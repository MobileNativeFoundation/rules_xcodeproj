"""Tests for `project_options`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj:project_options.bzl", "project_options")

def _project_options_test_impl(ctx):
    env = unittest.begin(ctx)

    # Defaults
    opts = project_options()
    asserts.equals(env, {"development_region": "en"}, opts)

    # With template_macros
    opts_with_macros = project_options(
        template_macros = "//:IDETemplateMacros.plist",
    )
    asserts.equals(
        env,
        {
            "development_region": "en",
            "template_macros": "//:IDETemplateMacros.plist",
        },
        opts_with_macros,
    )

    # With all options
    opts_all = project_options(
        development_region = "fr",
        indent_width = 4,
        organization_name = "My Org",
        tab_width = 4,
        template_macros = ":IDETemplateMacros.plist",
        uses_tabs = True,
    )
    asserts.equals(
        env,
        {
            "development_region": "fr",
            "indent_width": "4",
            "organization_name": "My Org",
            "tab_width": "4",
            "template_macros": ":IDETemplateMacros.plist",
            "uses_tabs": "1",
        },
        opts_all,
    )

    return unittest.end(env)

project_options_test = unittest.make(_project_options_test_impl)

def project_options_test_suite(name):
    project_options_test(
        name = "{}_test".format(name),
    )

    native.test_suite(
        name = name,
        tests = [
            ":{}_test".format(name),
        ],
    )

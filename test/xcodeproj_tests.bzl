"""Tests for the `xcodeproj` rule."""

load("//test/fixtures:fixtures.bzl", "fixtures_transition")
load("//xcodeproj:xcodeproj.bzl", "XcodeProjOutputInfo")

def _xcodeproj_test_impl(ctx):
    validator = ctx.actions.declare_file(
        "{}-spec-validator.sh".format(ctx.label.name),
    )

    xcodeproj_outputs = ctx.attr.target_under_test[0][XcodeProjOutputInfo]
    spec = xcodeproj_outputs.spec
    expected_spec = ctx.file.expected_spec
    xcodeproj = xcodeproj_outputs.xcodeproj
    expected_xcodeproj = ctx.files.expected_xcodeproj

    expected_xcodeproj_path = expected_xcodeproj[0].short_path
    suffix_len = len(expected_xcodeproj_path.split(".xcodeproj/")[1]) + 1
    expected_xcodeproj_path = expected_xcodeproj_path[:-suffix_len]

    ctx.actions.expand_template(
        template = ctx.file._validator_template,
        output = validator,
        is_executable = True,
        substitutions = {
            "%spec%": spec.short_path,
            "%expected_spec%": expected_spec.short_path,
            "%expected_xcodeproj%": expected_xcodeproj_path,
            "%xcodeproj%": xcodeproj.short_path,
        },
    )

    return [
        DefaultInfo(
            executable = validator,
            runfiles = ctx.runfiles(
                files = [spec, expected_spec, xcodeproj] + expected_xcodeproj,
            ),
        ),
    ]

xcodeproj_test = rule(
    implementation = _xcodeproj_test_impl,
    attrs = {
        "target_under_test": attr.label(
            cfg = fixtures_transition,
            mandatory = True,
            providers = [XcodeProjOutputInfo],
        ),
        "expected_spec": attr.label(mandatory = True, allow_single_file = True),
        "expected_xcodeproj": attr.label(mandatory = True, allow_files = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_validator_template": attr.label(
            allow_single_file = True,
            default = ":validator.template.sh",
        ),
    },
    test = True,
)

def xcodeproj_test_suite(name):
    """Test suite for `xcodeproj`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            target_under_test,
            expected_spec,
            expected_xcodeproj):
        test_names.append(name)
        xcodeproj_test(
            name = name,
            target_under_test = target_under_test,
            expected_spec = expected_spec,
            expected_xcodeproj = expected_xcodeproj,
        )

    # cc

    _add_test(
        name = "{}_cc".format(name),
        target_under_test = "//test/fixtures/cc:xcodeproj",
        expected_spec = "//test/fixtures/cc:spec.json",
        expected_xcodeproj = "//test/fixtures/cc:xcodeproj_output",
    )

    # Command Line

    _add_test(
        name = "{}_command_line".format(name),
        target_under_test = "//test/fixtures/command_line:xcodeproj",
        expected_spec = "//test/fixtures/command_line:spec.json",
        expected_xcodeproj = "//test/fixtures/command_line:xcodeproj_output",
    )

    # generator

    _add_test(
        name = "{}_generator".format(name),
        target_under_test = "//test/fixtures/generator:xcodeproj",
        expected_spec = "//test/fixtures/generator:spec.json",
        expected_xcodeproj = "//test/fixtures/generator:xcodeproj_output",
    )

    # iOS App

    _add_test(
        name = "{}_ios_app".format(name),
        target_under_test = "//test/fixtures/ios_app:xcodeproj",
        expected_spec = "//test/fixtures/ios_app:spec.json",
        expected_xcodeproj = "//test/fixtures/ios_app:xcodeproj_output",
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

"""Tests for `xcodeproj_rule.write_installer`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcodeproj_rule.bzl", "xcodeproj_rule")

def _write_installer_test_impl(ctx):
    env = unittest.begin(ctx)

    # Common mocks
    actions_none = mock_actions.create()
    bazel_integration_files = [
        mock_actions.mock_file(
            "bazel/copy_tool.py",
            short_path = "bazel/copy_tool.py",
        ),
    ]
    contents_xcworkspacedata = mock_actions.mock_file(
        "contents.xcworkspacedata",
        short_path = "contents.xcworkspacedata",
    )
    copy_tool = mock_actions.mock_file("copy_tool", short_path = "copy_tool")
    generated_directories_filelist = mock_actions.mock_file(
        "gen_dirs",
        short_path = "gen_dirs",
    )
    generated_xcfilelist = mock_actions.mock_file(
        "gen_files",
        short_path = "gen_files",
    )
    project_pbxproj = mock_actions.mock_file(
        "project.pbxproj",
        short_path = "project.pbxproj",
    )
    template = mock_actions.mock_file(
        "installer.sh",
        short_path = "installer.sh",
    )
    xcschememanagement = mock_actions.mock_file(
        "xcschememanagement.plist",
        short_path = "xcschememanagement.plist",
    )
    xcschemes = mock_actions.mock_file("xcschemes", short_path = "xcschemes")

    # Test 1: template_macros = None
    (installer_none, runfiles_none) = xcodeproj_rule.write_installer(
        actions = actions_none.mock,
        bazel_integration_files = bazel_integration_files,
        config = "rules_xcodeproj",
        contents_xcworkspacedata = contents_xcworkspacedata,
        copy_tool = copy_tool,
        generated_directories_filelist = generated_directories_filelist,
        generated_xcfilelist = generated_xcfilelist,
        install_path = "App.xcodeproj",
        name = "xcodeproj",
        project_pbxproj = project_pbxproj,
        template = template,
        template_macros = None,
        xcschememanagement = xcschememanagement,
        xcschemes = xcschemes,
    )

    asserts.equals(env, "xcodeproj-installer.sh", installer_none.path)
    asserts.equals(env, 1, len(actions_none.expand_template_args))
    expand_args_none = actions_none.expand_template_args[0]
    asserts.equals(env, "", expand_args_none.substitutions["%template_macros%"])
    asserts.false(env, any([f.path == "IDETemplateMacros.plist" for f in runfiles_none]))

    # Test 2: template_macros provided
    actions_with_macros = mock_actions.create()
    template_macros = mock_actions.mock_file(
        "custom/IDETemplateMacros.plist",
        short_path = "custom/IDETemplateMacros.plist",
    )

    (installer_macros, runfiles_macros) = xcodeproj_rule.write_installer(
        actions = actions_with_macros.mock,
        bazel_integration_files = bazel_integration_files,
        config = "rules_xcodeproj",
        contents_xcworkspacedata = contents_xcworkspacedata,
        copy_tool = copy_tool,
        generated_directories_filelist = generated_directories_filelist,
        generated_xcfilelist = generated_xcfilelist,
        install_path = "App.xcodeproj",
        name = "xcodeproj",
        project_pbxproj = project_pbxproj,
        template = template,
        template_macros = template_macros,
        xcschememanagement = xcschememanagement,
        xcschemes = xcschemes,
    )

    asserts.equals(env, "xcodeproj-installer.sh", installer_macros.path)
    asserts.equals(env, 1, len(actions_with_macros.expand_template_args))
    expand_args_macros = actions_with_macros.expand_template_args[0]
    asserts.equals(
        env,
        "custom/IDETemplateMacros.plist",
        expand_args_macros.substitutions["%template_macros%"],
    )
    asserts.true(
        env,
        template_macros in runfiles_macros,
        "template_macros should be in runfiles",
    )

    return unittest.end(env)

write_installer_test = unittest.make(_write_installer_test_impl)

def write_installer_test_suite(name):
    write_installer_test(
        name = "{}_test".format(name),
    )

    native.test_suite(
        name = name,
        tests = [
            ":{}_test".format(name),
        ],
    )

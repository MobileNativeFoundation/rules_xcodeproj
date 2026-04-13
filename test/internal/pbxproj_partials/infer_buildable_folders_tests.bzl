"""Tests for `pbxproj_partials._infer_buildable_folders`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:pbxproj_partials.bzl",
    "pbxproj_partials_testable",
)

def _source_file(path, owner):
    return struct(
        owner = owner,
        path = path,
    )

def _infer_buildable_folders_test_impl(ctx):
    env = unittest.begin(ctx)

    label = mock_actions.mock_label("//iosapp/Tools/XcodeFormat:XcodeFormat")
    sources_label = mock_actions.mock_label(
        "//iosapp/Tools/XcodeFormat/Sources:XcodeFormatSources",
    )

    xcode_target = struct(
        inputs = struct(
            non_arc_srcs = depset([]),
            resource_file_paths = depset([
                "iosapp/Tools/XcodeFormat/Sources/Assets.xcassets",
            ]),
            srcs = depset([
                _source_file(
                    "iosapp/Tools/XcodeFormat/Sources/ConfigurationFile.swift",
                    sources_label,
                ),
                _source_file(
                    "iosapp/Tools/XcodeFormat/Sources/ContentView.swift",
                    sources_label,
                ),
                _source_file(
                    "iosapp/Tools/XcodeFormat/Sources/XcodeFormatApp.swift",
                    sources_label,
                ),
            ]),
        ),
        label = label,
        outputs = struct(
            product_path = "iosapp/Tools/XcodeFormat/XcodeFormat.app",
        ),
    )

    asserts.equals(
        env,
        ["iosapp/Tools/XcodeFormat"],
        pbxproj_partials_testable.infer_buildable_folders(xcode_target),
    )

    return unittest.end(env)

infer_buildable_folders_test = unittest.make(
    impl = _infer_buildable_folders_test_impl,
)

def _infer_buildable_dependency_folders_test_impl(ctx):
    env = unittest.begin(ctx)

    label = mock_actions.mock_label("//iosapp/Components/AppShell/API:AppShell")
    sources_label = mock_actions.mock_label(
        "//iosapp/Components/AppShell/API:AppShellSources",
    )

    xcode_target = struct(
        inputs = struct(
            non_arc_srcs = depset([]),
            resource_file_paths = depset([]),
            srcs = depset([
                _source_file(
                    "iosapp/Components/AppShell/API/Sources/AppShell.swift",
                    sources_label,
                ),
            ]),
        ),
        label = label,
        outputs = struct(
            product_path = None,
        ),
    )

    asserts.equals(
        env,
        ["iosapp/Components"],
        pbxproj_partials_testable.infer_buildable_folders(xcode_target),
    )

    return unittest.end(env)

infer_buildable_dependency_folders_test = unittest.make(
    impl = _infer_buildable_dependency_folders_test_impl,
)

def infer_buildable_folders_test_suite(name):
    infer_buildable_folders_test(
        name = "{}_prefers_package_root".format(name),
    )
    infer_buildable_dependency_folders_test(
        name = "{}_broadens_dependencies".format(name),
    )

    native.test_suite(
        name = name,
        tests = [
            "{}_prefers_package_root".format(name),
            "{}_broadens_dependencies".format(name),
        ],
    )

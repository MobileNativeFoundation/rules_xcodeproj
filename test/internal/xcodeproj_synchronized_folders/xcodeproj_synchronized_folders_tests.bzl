"""Tests for the `xcodeproj_synchronized_folders` module."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "//xcodeproj:xcodeproj_synchronized_folders.bzl",
    "xcodeproj_synchronized_folders",
)

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:providers.bzl",
    "XcodeProjSynchronizedFoldersHintInfo",
)

def _provider_contents_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)

    asserts.equals(
        env,
        ("Sources", "Tests/Unit"),
        target_under_test[XcodeProjSynchronizedFoldersHintInfo].folders,
    )

    return analysistest.end(env)

provider_contents_test = analysistest.make(_provider_contents_test_impl)

def _invalid_folder_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "must be a path relative to a package")
    return analysistest.end(env)

invalid_folder_test = analysistest.make(
    _invalid_folder_test_impl,
    expect_failure = True,
)

def _test_provider_contents():
    xcodeproj_synchronized_folders(
        name = "xcodeproj_synchronized_folders_subject",
        folders = ["Sources", "Tests/Unit"],
        tags = ["manual"],
    )

    provider_contents_test(
        name = "provider_contents_test",
        target_under_test = ":xcodeproj_synchronized_folders_subject",
    )

def _test_invalid_folder():
    xcodeproj_synchronized_folders(
        name = "xcodeproj_synchronized_folders_invalid_subject",
        folders = ["../Sources"],
        tags = ["manual"],
    )

    invalid_folder_test(
        name = "invalid_folder_test",
        target_under_test = ":xcodeproj_synchronized_folders_invalid_subject",
    )

def xcodeproj_synchronized_folders_test_suite(name):
    _test_provider_contents()
    _test_invalid_folder()

    native.test_suite(
        name = name,
        tests = [
            ":invalid_folder_test",
            ":provider_contents_test",
        ],
    )

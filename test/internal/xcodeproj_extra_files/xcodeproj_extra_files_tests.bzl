load("@bazel_skylib//lib:unittest.bzl", "asserts", "analysistest")
load("//xcodeproj:xcodeproj_extra_files.bzl", "xcodeproj_extra_files", "XcodeProjExtraFilesHintInfo")

def _provider_contents_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)

    asserts.equals(env, depset(["BUILD"]), target_under_test[XcodeProjExtraFilesHintInfo].files)

    return analysistest.end(env)

provider_contents_test = analysistest.make(_provider_contents_test_impl)

def _test_provider_contents():
    xcodeproj_extra_files(
        name = "xcodeproj_extra_files_subject",
        files = ["BUILD"],
        tags = ["manual"],
    )

    provider_contents_test(
        name = "provider_contents_test",
        target_under_test = ":xcodeproj_extra_files_subject",
    )

def xcodeproj_extra_files_test_suite(name):
    _test_provider_contents()

    native.test_suite(
        name = name,
        tests = [
            ":provider_contents_test",
        ],
    )
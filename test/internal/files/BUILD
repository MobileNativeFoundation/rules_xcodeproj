load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":output_files_tests.bzl",
    "archive_preview_framework_test",
    "output_files_test_suite",
)

output_files_test_suite(name = "output_files")

archive_preview_framework_test(
    name = "archive_preview_framework",
)

test_suite(
    name = "files",
    tests = [
        ":archive_preview_framework",
        ":output_files",
    ],
)

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":xcodeproj_extra_files_tests.bzl", "xcodeproj_extra_files_test_suite")

xcodeproj_extra_files_test_suite(name = "xcodeproj_extra_files_test")

test_suite(name = "xcodeproj_extra_files")

bzl_library(
    name = "bzls",
    srcs = glob(
        ["*.bzl"],
        exclude = ["utils.bzl"],
    ),
    visibility = ["//test:__pkg__"],
)

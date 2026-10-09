load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":xcodeproj_synchronized_folders_tests.bzl", "xcodeproj_synchronized_folders_test_suite")

xcodeproj_synchronized_folders_test_suite(name = "xcodeproj_synchronized_folders_test")

test_suite(name = "xcodeproj_synchronized_folders")

bzl_library(
    name = "bzls",
    srcs = glob(
        ["*.bzl"],
        exclude = ["utils.bzl"],
    ),
    visibility = ["//test:__pkg__"],
)

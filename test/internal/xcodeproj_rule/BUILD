load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":buildable_folders_tests.bzl", "buildable_folders_test_suite")

buildable_folders_test_suite(name = "buildable_folders")

test_suite(name = "xcodeproj_rule")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

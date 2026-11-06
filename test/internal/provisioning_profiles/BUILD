load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":process_attr_tests.bzl", "process_attr_test_suite")

process_attr_test_suite(name = "process_attr")

test_suite(name = "provisioning_profiles")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

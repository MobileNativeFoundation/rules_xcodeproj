load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":is_test_bundle_tests.bzl", "is_test_bundle_test_suite")

is_test_bundle_test_suite(name = "is_test_bundle")

test_suite(name = "targets")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

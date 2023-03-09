load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":flattened_key_values_tests.bzl", "flattened_key_values_test_suite")

flattened_key_values_test_suite()

test_suite(name = "flattened_key_values")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

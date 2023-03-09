load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":normalize_tests.bzl", "normalize_test_suite")
load(":parse_tests.bzl", "parse_test_suite")

normalize_test_suite(name = "normalize_tests")

parse_test_suite(name = "parse_tests")

test_suite(name = "bazel_labels")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

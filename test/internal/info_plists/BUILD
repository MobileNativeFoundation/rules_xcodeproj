load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":get_file_tests.bzl", "get_file_test_suite")

get_file_test_suite(name = "get_file")

test_suite(name = "info_plists")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

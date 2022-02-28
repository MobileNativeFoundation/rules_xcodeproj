load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":calculate_module_name_tests.bzl",
    "calculate_module_name_test_suite",
)

calculate_module_name_test_suite(name = "calculate_module_name")

test_suite(name = "build_settings")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

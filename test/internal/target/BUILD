load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":calculate_configuration_tests.bzl",
    "calculate_configuration_test_suite",
)
load(
    ":process_top_level_properties_tests.bzl",
    "process_top_level_properties_test_suite",
)

calculate_configuration_test_suite(name = "calculate_configuration")

process_top_level_properties_test_suite(name = "process_top_level_properties")

test_suite(name = "target")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":calculate_configuration_tests.bzl",
    "calculate_configuration_test_suite",
)

calculate_configuration_test_suite(name = "calculate_configuration")

test_suite(name = "target")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

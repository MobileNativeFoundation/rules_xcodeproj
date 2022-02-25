load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":generate_platform_information_tests.bzl",
    "generate_platform_information_test_suite",
)

generate_platform_information_test_suite(name = "generate_platform_information")

test_suite(name = "platform")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

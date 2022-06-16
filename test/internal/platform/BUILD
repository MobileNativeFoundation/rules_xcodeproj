load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":platform_info_to_dto_tests.bzl",
    "platform_info_to_dto_test_suite",
)

platform_info_to_dto_test_suite(name = "platform_info_to_dto")

test_suite(name = "platform")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

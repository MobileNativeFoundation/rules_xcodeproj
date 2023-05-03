load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":platforms_to_dto_tests.bzl",
    "platforms_to_dto_test_suite",
)

platforms_to_dto_test_suite(name = "platforms_to_dto")

test_suite(name = "platforms")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

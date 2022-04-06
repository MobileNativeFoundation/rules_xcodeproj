load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":get_targeted_device_family_tests.bzl",
    "get_targeted_device_family_test_suite",
)

get_targeted_device_family_test_suite(name = "get_targeted_device_family")

test_suite(name = "build_settings")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

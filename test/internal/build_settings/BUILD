load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":calculate_module_name_tests.bzl",
    "calculate_module_name_test_suite",
)
load(
    ":get_targeted_device_family_tests.bzl",
    "get_targeted_device_family_test_suite",
)

calculate_module_name_test_suite(name = "calculate_module_name")

get_targeted_device_family_test_suite(name = "get_targeted_device_family")

test_suite(name = "build_settings")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

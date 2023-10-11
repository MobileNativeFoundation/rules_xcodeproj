load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":info_constructors_tests.bzl", "info_constructors_test_suite")
load(":infos_from_json_tests.bzl", "infos_from_json_test_suite")
load(":write_schemes_tests.bzl", "write_schemes_test_suite")

info_constructors_test_suite(name = "info_constructors")

infos_from_json_test_suite(name = "infos_from_json")

write_schemes_test_suite(name = "write_schemes")

test_suite(name = "xcschemes")

bzl_library(
    name = "bzls",
    srcs = glob(
        ["*.bzl"],
        exclude = ["utils.bzl"],
    ),
    visibility = ["//test:__pkg__"],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

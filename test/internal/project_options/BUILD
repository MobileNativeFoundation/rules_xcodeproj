load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":project_options_tests.bzl", "project_options_test_suite")

project_options_test_suite(name = "project_options_tests")

test_suite(name = "project_options")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

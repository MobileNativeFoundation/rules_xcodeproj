load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":model_tests.bzl", "model_test_suite")

model_test_suite(name = "model_tests")

test_suite(name = "xcode_schemes")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

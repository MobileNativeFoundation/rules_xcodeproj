load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":process_compiler_opts_tests.bzl",
    "process_compiler_opts_test_suite",
)

process_compiler_opts_test_suite(name = "process_compiler_opts")

test_suite(name = "opts")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

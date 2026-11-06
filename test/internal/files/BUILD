load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":linker_input_files_tests.bzl", "linker_input_files_test_suite")

linker_input_files_test_suite(name = "linker_input_files")

test_suite(
    name = "files",
    tests = [":linker_input_files"],
)

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

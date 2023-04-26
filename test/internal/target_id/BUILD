load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":write_target_ids_list_tests.bzl", "write_target_ids_list_test_suite")

write_target_ids_list_test_suite(name = "write_target_ids_list")

test_suite(name = "target_id")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

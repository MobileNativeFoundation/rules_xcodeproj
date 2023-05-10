load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":write_pbxproject_prefix_tests.bzl",
    "write_pbxproject_prefix_test_suite",
)

write_pbxproject_prefix_test_suite(name = "write_pbxproject_prefix")

test_suite(name = "pbxproj_partials")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

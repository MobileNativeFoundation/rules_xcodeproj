load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":write_bazel_dependencies_tests.bzl",
    "write_bazel_dependencies_test_suite",
)
load(
    ":write_pbxproj_prefix_tests.bzl",
    "write_pbxproj_prefix_test_suite",
)

write_bazel_dependencies_test_suite(name = "write_bazel_dependencies")

write_pbxproj_prefix_test_suite(name = "write_pbxproj_prefix")

test_suite(name = "pbxproj_partials")

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

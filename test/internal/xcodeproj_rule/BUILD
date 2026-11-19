load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":write_installer_tests.bzl", "write_installer_test_suite")

write_installer_test_suite(name = "write_installer_tests")

test_suite(name = "xcodeproj_rule")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

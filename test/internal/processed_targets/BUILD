load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":mergeable_infos_tests.bzl", "mergeable_infos_test_suite")

mergeable_infos_test_suite(name = "mergeable_infos")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)

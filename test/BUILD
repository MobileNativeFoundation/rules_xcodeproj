load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

test_suite(
    name = "test",
    tests = [
        "//test/internal/bazel_labels",
        "//test/internal/build_settings",
        "//test/internal/flattened_key_values",
        "//test/internal/info_plists",
        "//test/internal/opts",
        "//test/internal/platform",
        "//test/internal/target",
        "//test/internal/targets",
        "//test/internal/xcode_schemes",
    ],
)

bzl_library(
    name = "starlark_tests_bzls",
    deps = [
        "//test/internal/bazel_labels:starlark_tests_bzls",
        "//test/internal/build_settings:starlark_tests_bzls",
        "//test/internal/flattened_key_values:starlark_tests_bzls",
        "//test/internal/info_plists:starlark_tests_bzls",
        "//test/internal/platform:starlark_tests_bzls",
        "//test/internal/target:starlark_tests_bzls",
        "//test/internal/targets:starlark_tests_bzls",
        "//test/internal/xcode_schemes:starlark_tests_bzls",
    ],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

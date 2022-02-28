load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

test_suite(
    name = "test",
    tests = [
        "//test/internal/opts",
        "//test/internal/platform",
    ],
)

bzl_library(
    name = "starlark_tests_bzls",
    deps = [
        "//test/internal/opts:starlark_tests_bzls",
    ]
)

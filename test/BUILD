load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":xcodeproj_tests.bzl",
    "xcodeproj_test_suite",
)

xcodeproj_test_suite(name = "xcodeproj")

test_suite(
    name = "test",
    tests = [
        "//test/internal/build_settings",
        "//test/internal/opts",
        "//test/internal/platform",
        "//test/internal/target",
        ":xcodeproj",
    ],
)

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*_tests.bzl"]),
    deps = [
        "//test/internal/opts:starlark_tests_bzls",
    ]
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

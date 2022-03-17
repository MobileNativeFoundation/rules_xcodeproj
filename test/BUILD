load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//xcodeproj:testing.bzl", "xcodeproj_test_suite")

# TODO: Consider moving fixtures list to test/fixtures/fixtures.bzl and reference it.

_FIXTURE_BASENAMES = [
    "cc",
    "command_line",
    "generator",
    "ios_app",
]

xcodeproj_test_suite(
    name = "xcodeproj",
    test_pkgs = ["//test/fixtures/{}".format(n) for n in _FIXTURE_BASENAMES],
)

test_suite(
    name = "test",
    tests = [
        ":xcodeproj",
        "//test/internal/build_settings",
        "//test/internal/opts",
        "//test/internal/platform",
        "//test/internal/target",
    ],
)

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*_tests.bzl"]),
    deps = [
        "//test/internal/opts:starlark_tests_bzls",
    ],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

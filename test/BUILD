load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//test/fixtures:fixtures.bzl", "FIXTURE_TARGETS")
load("//xcodeproj:testing.bzl", "xcodeproj_test_suite", "xcodeproj_tests")

xcodeproj_test_suite(
    name = "xcodeproj",
    fixture_tests = xcodeproj_tests.from_fixtures(FIXTURE_TARGETS),
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

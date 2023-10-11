load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

test_suite(
    name = "test",
    tests = [
        "//test/internal/bazel_labels",
        "//test/internal/build_settings",
        "//test/internal/flattened_key_values",
        "//test/internal/info_plists",
        "//test/internal/opts",
        "//test/internal/pbxproj_partials",
        "//test/internal/platforms",
        "//test/internal/target",
        "//test/internal/target_id",
        "//test/internal/targets",
        "//test/internal/xcode_schemes",
        "//test/internal/xcschemes",
    ],
)

bzl_library(
    name = "test_bzls",
    deps = [
        "//test/internal/bazel_labels:bzls",
        "//test/internal/build_settings:bzls",
        "//test/internal/flattened_key_values:bzls",
        "//test/internal/info_plists:bzls",
        "//test/internal/pbxproj_partials:bzls",
        "//test/internal/platforms:bzls",
        "//test/internal/target:bzls",
        "//test/internal/target_id:bzls",
        "//test/internal/targets:bzls",
        "//test/internal/xcode_schemes:bzls",
        "//test/internal/xcschemes:bzls",
    ],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

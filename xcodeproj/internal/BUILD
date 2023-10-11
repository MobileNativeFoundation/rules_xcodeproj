load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "bazel_tools",
    srcs = [
        "@bazel_tools//tools:bzl_srcs",
    ],
    tags = ["manual"],
    visibility = ["//visibility:private"],
)

bzl_library(
    name = "internal",
    srcs = glob(["*.bzl"]),
    visibility = ["//:__subpackages__"],
    deps = [
        ":bazel_tools",
        "//xcodeproj/internal/xcschemes",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:sets",
        "@bazel_skylib//lib:structs",
        "@bazel_skylib//lib:versions",
        "@bazel_skylib//rules:common_settings",
        "@build_bazel_rules_apple//apple",
        "@build_bazel_rules_apple//apple:resources",
    ],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "xcodeproj_tests.bzl",
        ],
    ) + [
        "//" + package_name() + "/bazel_integration_files:release_files",
        "//" + package_name() + "/cat:release_files",
        "//" + package_name() + "/templates:release_files",
        "//" + package_name() + "/xcschemes:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

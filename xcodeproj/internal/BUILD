load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

py_library(
    name = "build_proxy_manifest_lib",
    srcs = ["build_proxy_manifest_lib.py"],
    visibility = ["//test/internal/build_proxy_manifest:__pkg__"],
)

py_binary(
    name = "build_proxy_manifest",
    srcs = ["build_proxy_manifest.py"],
    # The xcodeproj rule is instantiated from a generated extension repository,
    # so its implicit executable tool must be visible across repository bounds.
    visibility = ["//visibility:public"],
    deps = [":build_proxy_manifest_lib"],
)

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
        "//" + package_name() + "/files:release_files",
        "//" + package_name() + "/processed_targets:release_files",
        "//" + package_name() + "/templates:release_files",
        "//" + package_name() + "/xcschemes:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

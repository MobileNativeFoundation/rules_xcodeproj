load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files", "strip_prefix")

bzl_library(
    name = "bazel_tools",
    srcs = [
        "@bazel_tools//tools:bzl_srcs",
    ],
    tags = ["manual"],
    visibility = ["//visibility:private"],
)

bzl_library(
    name = "xcodeproj_internal",
    srcs = glob(["*.bzl"]),
    visibility = ["//:__subpackages__"],
    deps = [
        ":bazel_tools",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:sets",
        "@bazel_skylib//lib:structs",
        "@bazel_skylib//lib:versions",
        "@bazel_skylib//rules:common_settings",
        "@build_bazel_rules_apple//apple",
        "@build_bazel_rules_apple//apple:resources",
    ],
)

exports_files(glob(["*.template.*"]))

# Release

pkg_files(
    name = "package_release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "fixtures.bzl",
            "updater.template.sh",
            "validator.template.sh",
            "xcodeproj_tests.bzl",
        ],
    ),
    strip_prefix = strip_prefix.from_root(),
    tags = ["manual"],
)

pkg_filegroup(
    name = "release_files",
    srcs = [
        ":package_release_files",
        "//" + package_name() + "/bazel_integration_files:release_files",
    ],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

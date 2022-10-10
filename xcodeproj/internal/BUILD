load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "string_setting")

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
        "@bazel_skylib//lib:versions",
        "@bazel_skylib//rules:common_settings",
        "@build_bazel_rules_apple//apple",
        "@build_bazel_rules_apple//apple:resources",
    ],
)

exports_files(glob(["*.template.*"]))

string_setting(
    name = "build_mode",
    build_setting_default = "xcode",
    # This is made public for internal use only. Do not depend on this setting.
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "fixtures.bzl",
            "updater.template.sh",
            "validator.template.sh",
            "xcodeproj_tests.bzl",
        ],
    ) + [
        "//" + package_name() + "/bazel_integration_files:release_files",
    ],
    visibility = ["//visibility:public"],
)

load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files", "strip_prefix")

string_flag(
    name = "extra_common_flags",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

string_flag(
    name = "extra_generator_flags",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

string_flag(
    name = "extra_indexbuild_flags",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

string_flag(
    name = "extra_swiftuipreviews_flags",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

# Release

pkg_files(
    name = "package_release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "testing.bzl",
        ],
    ),
    strip_prefix = strip_prefix.from_root(),
    tags = ["manual"],
)

pkg_filegroup(
    name = "release_files",
    srcs = [
        ":package_release_files",
        "//" + package_name() + "/internal:release_files",
    ],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

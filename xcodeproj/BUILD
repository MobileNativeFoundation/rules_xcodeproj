load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag", "string_flag")

bool_flag(
    name = "color",
    build_setting_default = True,
    visibility = ["//visibility:public"],
)

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

package_group(
    name = "generated",
    includes = ["@rules_xcodeproj_generated//:package_group"],
)

bzl_library(
    name = "xcodeproj",
    srcs = glob(["*.bzl"]),
    visibility = ["//visibility:public"],
    deps = ["//xcodeproj/internal:xcodeproj_internal"],
)

# Release

genrule(
    name = "release_repositories.bzl",
    srcs = ["repositories.bzl"],
    outs = ["repositories.release.bzl"],
    cmd = """\
set -euo pipefail

perl -0777 -pe 's/\n *# Source dependencies.*//s' $< > $@
    """,
    tags = ["manual"],
)

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "dev_extensions.bzl",
            "repositories.bzl",
            "testing.bzl",
        ],
    ) + [
        ":release_repositories.bzl",
        "//" + package_name() + "/internal:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

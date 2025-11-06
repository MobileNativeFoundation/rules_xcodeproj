load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag", "string_flag")

bool_flag(
    name = "color",
    build_setting_default = True,
    visibility = ["//visibility:public"],
)

# `WriteTargetBuildSettings` is very fast, and there are potentially thousands
# of the action for a project, which results in caching overhead slowing down
# clean builds. So by default we disable remote cache/execution. This also
# prevents DDoSing the remote cache.
#
# Currently on Linux you need to enable this flag and use multi-platform RBE,
# since `WriteTargetBuildSettings` is precompiled for macOS. It might also be
# beneficial to enable this on CI to speed up project generation validation.
bool_flag(
    name = "allow_remote_write_target_build_settings",
    build_setting_default = False,
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

bool_flag(
    name = "separate_index_build_output_base",
    build_setting_default = False,
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
    deps = ["//xcodeproj/internal"],
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
        ],
    ) + [
        ":release_repositories.bzl",
        "//" + package_name() + "/internal:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

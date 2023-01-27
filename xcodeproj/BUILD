load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

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

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "testing.bzl",
        ],
    ) + [
        "//" + package_name() + "/internal:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

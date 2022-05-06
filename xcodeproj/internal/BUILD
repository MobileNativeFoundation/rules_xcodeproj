load(
    "@bazel_skylib//rules:common_settings.bzl",
    "bool_setting",
    "string_setting",
)

exports_files([
    "installer.template.sh",
    "updater.template.sh",
    "validator.template.sh",
])

string_setting(
    name = "install_path",
    build_setting_default = "",
    # This is made public for internal use only. Do not depend on this setting.
    visibility = ["//visibility:public"],
)

bool_setting(
    name = "archived_bundles_allowed",
    build_setting_default = False,
    # This is made public for internal use only. Do not depend on this setting.
    visibility = ["//visibility:public"],
)

string_setting(
    name = "build_mode",
    build_setting_default = "xcode",
    # This is made public for internal use only. Do not depend on this setting.
    visibility = ["//visibility:public"],
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

load("@bazel_skylib//rules:common_settings.bzl", "string_setting")

exports_files([
    "installer.template.sh",
    "validator.template.sh",
])

string_setting(
    name = "install_path",
    build_setting_default = "",
    # This is made public for internal use only. Do not depend on this setting.
    visibility = ["//visibility:public"],
)

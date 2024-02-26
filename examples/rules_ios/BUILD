load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
    "XCSCHEMES",
    "get_xcode_schemes",
)

exports_files(["README.md"])

[
    xcodeproj(
        name = "xcodeproj-{}".format(generation_mode),
        build_mode = "bazel",
        generation_mode = generation_mode,
        project_name = "rules_ios",
        scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
        schemes = get_xcode_schemes(),
        tags = ["manual"],
        top_level_targets = XCODEPROJ_TARGETS,
        xcschemes = XCSCHEMES,
    )
    for generation_mode in [
        "legacy",
        "incremental",
    ]
]

# Creates a flag which will be set when running via Xcode.
# This is useful for rules that need to behave differently when running via Xcode.
bool_flag(
    name = "is_running_in_swiftuipreviews",
    build_setting_default = 0,
)

config_setting(
    name = "running_in_swiftuipreviews",
    flag_values = {
        ":is_running_in_swiftuipreviews": "1",
    },
)

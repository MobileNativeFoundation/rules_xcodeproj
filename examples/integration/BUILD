load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "ASSOCIATED_EXTRA_FILES",
    "BAZEL_ENV",
    "CONFIG",
    "DEFAULT_XCODE_CONFIGURATION",
    "EXTRA_FILES",
    "PRE_BUILD",
    "PROJECT_OPTIONS",
    "SCHEME_AUTOGENERATION_CONFIG",
    "SCHEME_AUTOGENERATION_MODE",
    "UNFOCUSED_TARGETS",
    "XCODEPROJ_TARGETS",
    "XCODE_CONFIGURATIONS",
    "XCSCHEMES",
)

exports_files(["README.md"])

string_flag(
    name = "flag_to_transition_on",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

# Example of xcodeproj cache warming
#
# 1. Register a single macOS execution platform in `WORKSPACE`:
#
#      register_execution_platforms("@build_bazel_apple_support//platforms:macos_x86_64")
#
# 2. Add `build:rules_xcodeproj --@build_bazel_rules_swift//swift:universal_tools`
#    flag to your `.bazelrc`/`xcodeproj.bazelrc`.
# 3. Define an `xcodeproj` target for each macOS platform, e.g.
#    `xcodeproj-x86_64` and `xcodeproj-sim_arm64`. Even if you don't need to
#    support any of iOS, tvOS, or watchOS platforms, you still need to set all
#    of the `ios_simulator_cpus`, `tvos_simulator_cpus`, and
#    `watchos_simulator_cpus` to avoid Starlark transition effect. See
#    https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/1094.
# 4. Run each of the following commands to produce a cache for each macOS host
#    platform. This can be run from an Intel or Apple silicon Mac.
#
#      bazel run --config=cache //:xcodeproj-x86_64 \
#        -- \
#        --generator_output_groups=all_targets \
#        'build --remote_download_minimal'
#
#      bazel run --config=cache //:xcodeproj-sim_arm64 \
#        -- \
#        --generator_output_groups=all_targets \
#        'build --remote_download_minimal'
#
[
    xcodeproj(
        name = "xcodeproj-{}".format(simulator_cpu),
        associated_extra_files = ASSOCIATED_EXTRA_FILES,
        bazel_env = BAZEL_ENV,
        config = CONFIG,
        default_xcode_configuration = DEFAULT_XCODE_CONFIGURATION,
        extra_files = EXTRA_FILES,
        ios_simulator_cpus = simulator_cpu,
        pre_build = PRE_BUILD,
        project_name = "Integration",
        project_options = PROJECT_OPTIONS,
        scheme_autogeneration_config = SCHEME_AUTOGENERATION_CONFIG,
        scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
        tags = ["manual"],
        top_level_targets = XCODEPROJ_TARGETS,
        tvos_simulator_cpus = simulator_cpu,
        unfocused_targets = UNFOCUSED_TARGETS,
        # watchOS Simulator CPU on Apple silicon doesn't have 'sim_' prefix
        watchos_simulator_cpus = simulator_cpu.removeprefix("sim_"),
        xcode_configurations = XCODE_CONFIGURATIONS,
        xcschemes = XCSCHEMES,
    )
    for simulator_cpu in [
        "sim_arm64",
        "x86_64",
    ]
]

alias(
    name = "xcodeproj",
    actual = "xcodeproj-sim_arm64",
)

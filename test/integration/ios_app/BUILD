load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    project_name = "iOS App",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)

# MARK: - Select the Xcode Version

# NOTE: It appears that the BuildBuddy Xcode hosts have a pre-13.0 version of
# Xcode available. The code in this integration test requires 13.0 or later.
# Also, the README for rules_xcodeproj states that only Xcode versions 13.2.1
# or later are supported. For now, will require 13.2.1 using the configuration
# below and the --xcode_version_config flag in the .bazelrc.

xcode_version(
    name = "version13_2_1_13C100",
    aliases = [
        "13.2",
        "13.2.1",
        "13.2.1.13C100",
        "13",
        "13C100",
    ],
    default_ios_sdk_version = "15.2",
    default_macos_sdk_version = "12.1",
    default_tvos_sdk_version = "15.2",
    default_watchos_sdk_version = "8.3",
    version = "13.2.1.13C100",
)

xcode_config(
    name = "host_xcodes",
    default = ":version13_2_1_13C100",
    versions = [":version13_2_1_13C100"],
)

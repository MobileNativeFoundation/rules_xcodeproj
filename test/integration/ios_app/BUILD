load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    project_name = "iOS App",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)

# MARK: - Select the Xcode Version

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

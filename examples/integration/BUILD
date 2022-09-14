load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
load(":xcodeproj_targets.bzl", "CONFIG", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    associated_extra_files = {
        "//iOSApp/Source:iOSApp": ["//iOSApp:ownership.yaml"],
        "//Lib": ["//Lib:README.md"],
    },
    build_mode = "xcode",
    config = CONFIG,
    project_name = "Integration",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

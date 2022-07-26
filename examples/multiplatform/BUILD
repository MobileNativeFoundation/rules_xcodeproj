load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:experimental.bzl",
    "device_and_simulator",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    project_name = "Multiplatform",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

device_and_simulator(
    name = "device_targets",
    tags = ["manual"],
    targets = [
        "//examples/multiplatform/iOSApp",
        "//examples/multiplatform/iMessageApp",
        "//examples/multiplatform/tvOSApp",
    ],
    visibility = ["//visibility:public"],
)

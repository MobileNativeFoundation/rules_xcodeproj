load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    project_name = "tvOS App",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

alias(
    name = "tvOSApp",
    actual = "//examples/multiplatform/tvOSApp/Source:tvOSApp",
    visibility = ["//visibility:public"],
)

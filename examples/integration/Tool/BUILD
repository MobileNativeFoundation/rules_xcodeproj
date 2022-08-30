load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

macos_command_line_application(
    name = "Tool",
    bundle_id = "io.buildbuddy.example",
    infoplists = ["Info.plist"],
    minimum_os_version = "11.0",
    visibility = ["//visibility:public"],
    deps = [":Tool.library"],
)

swift_library(
    name = "Tool.library",
    srcs = ["main.swift"],
    module_name = "Tool",
    tags = ["manual"],
)

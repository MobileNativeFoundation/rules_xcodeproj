load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")

macos_command_line_application(
    name = "tool",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":tool.library"],
)

objc_library(
    name = "tool.library",
    srcs = ["main.m"],
    enable_modules = True,
    tags = ["manual"],
    deps = [
        "//examples/command_line/lib",
    ],
)

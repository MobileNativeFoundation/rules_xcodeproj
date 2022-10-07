load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

macos_command_line_application(
    name = "CommandLineTool",
    bundle_id = "io.buildbuddy.example",
    codesignopts = ["-v"],
    exported_symbols_lists = [
        "export_symbol_list.exp",
    ],
    infoplists = ["Info.plist"],
    launchdplists = ["Launchd.plist"],
    linkopts = ["-dead_strip"],
    minimum_os_version = "11.0",
    visibility = ["//visibility:public"],
    deps = [":tool.library"],
)

objc_library(
    name = "tool.library",
    srcs = ["main.m"],
    enable_modules = True,
    tags = ["manual"],
    deps = [
        "//CommandLine/CommandLineToolLib",
        "@examples_command_line_external//:ExternalFramework",
    ],
)

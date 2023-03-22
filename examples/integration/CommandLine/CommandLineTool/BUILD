load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

macos_command_line_application(
    name = "CommandLineTool",
    bundle_id = "rules-xcodeproj.example",
    codesignopts = ["-v"],
    exported_symbols_lists = [
        "export_symbol_list.exp",
    ],
    infoplists = ["Info.plist"],
    launchdplists = ["Launchd.plist"],
    linkopts = ["-dead_strip"],
    minimum_os_version = "11.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":tool.library"],
)

apple_universal_binary(
    name = "UniversalCommandLineTool",
    binary = ":tool.binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "11.0",
    platform_type = "macos",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

swift_binary(
    name = "tool.binary",
    deps = [":tool.library"],
)

objc_library(
    name = "tool.library",
    srcs = ["main.m"],
    hdrs = ["verbose.cfg"],
    copts = [
        "--config",
        "CommandLine/CommandLineTool/verbose.cfg",
    ],
    enable_modules = True,
    tags = ["manual"],
    deps = [
        "//CommandLine/CommandLineToolLib",
        "@examples_command_line_external//:ExternalFramework",
    ],
)

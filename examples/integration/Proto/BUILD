load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
    "swift_proto_library",
)

proto_library(
    name = "person_proto",
    srcs = ["Person.proto"],
)

swift_proto_library(
    name = "person_proto_swift",
    deps = [":person_proto"],
)

swift_library(
    name = "tool.library",
    srcs = ["main.swift"],
    deps = [
        ":person_proto_swift",
    ],
)

macos_command_line_application(
    name = "proto",
    bundle_id = "rules-xcodeproj.example",
    infoplists = ["Info.plist"],
    minimum_os_version = "11.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":tool.library"],
)

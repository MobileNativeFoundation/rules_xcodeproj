load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_grpc_library",
    "swift_library",
    "swift_proto_library",
)

proto_library(
    name = "echo_proto",
    srcs = ["echo.proto"],
)

swift_proto_library(
    name = "echo_proto_swift",
    deps = [":echo_proto"],
)

swift_grpc_library(
    name = "echo_client_services_swift",
    srcs = [":echo_proto"],
    flavor = "client",
    deps = [":echo_proto_swift"],
)

swift_grpc_library(
    name = "echo_server_services_swift",
    srcs = [":echo_proto"],
    flavor = "server",
    deps = [":echo_proto_swift"],
)

swift_library(
    name = "echo_server.library",
    srcs = ["server_main.swift"],
    deps = [
        ":echo_proto_swift",
        ":echo_server_services_swift",
    ],
)

macos_command_line_application(
    name = "echo_server",
    bundle_id = "rules-xcodeproj.examples.integration.grpc.echo_server",
    infoplists = ["Info.plist"],
    minimum_os_version = "11.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":echo_server.library"],
)

swift_library(
    name = "echo_client.library",
    srcs = ["client_main.swift"],
    deps = [":echo_client_services_swift"],
)

macos_command_line_application(
    name = "echo_client",
    bundle_id = "rules-xcodeproj.examples.integration.grpc.echo_client",
    infoplists = ["Info.plist"],
    minimum_os_version = "11.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":echo_client.library"],
)

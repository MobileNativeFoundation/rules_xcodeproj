load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_proto_library",
)

# protos
proto_library(
    name = "build_event_stream_proto",
    srcs = ["build_event_stream.proto"],
    deps = [
        ":command_line_proto",
        ":failure_details_proto",
        ":invocation_policy_proto",
        "@com_google_protobuf//:duration_proto",
        "@com_google_protobuf//:timestamp_proto",
    ],
)

proto_library(
    name = "command_line_proto",
    srcs = ["command_line.proto"],
    deps = [
        ":option_filters_proto",
    ],
)

proto_library(
    name = "failure_details_proto",
    srcs = ["failure_details.proto"],
    deps = [
        "@com_google_protobuf//:descriptor_proto",
    ],
)

proto_library(
    name = "invocation_policy_proto",
    srcs = ["invocation_policy.proto"],
)

proto_library(
    name = "option_filters_proto",
    srcs = ["option_filters.proto"],
)

# swift_protobuf

swift_proto_library(
    name = "bep",
    visibility = ["//tools/bep_parser:__subpackages__"],
    deps = [":build_event_stream_proto"],
)

load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

_BASE_FILES = [
    "bazel_build.sh",
    "calculate_output_groups.py",
    "create_lldbinit.sh",
    "import_indexstores.sh",
    "process_bazel_build_log.py",
]

filegroup(
    name = "base_integration_files",
    srcs = _BASE_FILES,
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

filegroup(
    name = "bazel_integration_files",
    srcs = glob(
        ["**/*"],
        exclude = _BASE_FILES + [
            "BUILD",
            "swiftc.swift",
        ],
    ),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

swift_binary(
    name = "swiftc_stub",
    srcs = ["swiftc.swift"],
)

apple_universal_binary(
    name = "swiftc",
    binary = ":swiftc_stub",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "12.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

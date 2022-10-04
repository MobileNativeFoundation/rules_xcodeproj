load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)

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
            "main.swift",
        ],
    ),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "swiftc",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":swiftc_stub.library"],
)

swift_library(
    name = "swiftc_stub.library",
    srcs = ["main.swift"],
    deps = [
        "@com_github_apple_swift_collections//:OrderedCollections",
    ],
)

swift_binary(
    name = "swiftc_stub_binary",
    deps = [":swiftc_stub.library"],
)

apple_universal_binary(
    name = "universal_swiftc_stub",
    binary = ":swiftc_stub_binary",
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

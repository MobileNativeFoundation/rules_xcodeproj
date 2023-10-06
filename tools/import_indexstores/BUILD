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

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "import_indexstores",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":import_indexstores.library"],
)

swift_library(
    name = "import_indexstores.library",
    srcs = glob(["*.swift"]),
    module_name = "import_indexstores",
    deps = [
        "//tools/lib/ToolCommon",
    ],
)

swift_binary(
    name = "import_indexstores_binary",
    deps = [":import_indexstores.library"],
)

apple_universal_binary(
    name = "universal_import_indexstores",
    binary = ":import_indexstores_binary",
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
    srcs = [
        "BUILD.release.bazel",
        ":universal_import_indexstores",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

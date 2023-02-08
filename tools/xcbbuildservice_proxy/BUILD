load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
    "macos_unit_test",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("//xcodeproj:defs.bzl", "xcodeproj")

swift_library(
    name = "xcbbuildservice_proxy.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "generator",
    deps = [
        "@xcbbuildserviceproxykit//:XCBBuildServiceProxyKit",
    ],
)

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "xcbbuildservice_proxy",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":xcbbuildservice_proxy.library"],
)

swift_binary(
    name = "xcbbuildservice_proxy_binary",
    deps = [":xcbbuildservice_proxy.library"],
)

apple_universal_binary(
    name = "universal_xcbbuildservice_proxy",
    binary = ":xcbbuildservice_proxy_binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "12.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)

swift_library(
    name = "tests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "tests",
    deps = [
        ":xcbbuildservice_proxy.library",
    ],
)

macos_unit_test(
    name = "tests",
    minimum_os_version = "12.0",
    visibility = [
        "//test:__subpackages__",
    ],
    deps = [
        ":tests.library",
    ],
)

xcodeproj(
    name = "xcodeproj",
    project_name = "xcbbuildservice_proxy",
    tags = ["manual"],
    top_level_targets = [
        ":tests",
        ":xcbbuildservice_proxy",
    ],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "BUILD.release.bazel",
        ":universal_xcbbuildservice_proxy",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

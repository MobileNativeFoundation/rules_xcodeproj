load("@build_bazel_rules_apple//apple:macos.bzl", "macos_application", "macos_dynamic_framework")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    ":dual_aspect_tests.bzl",
    "dual_aspect_resource_bundle_test",
    "multiple_generators_resource_bundle_test",
    "shared_consumer_resource_bundle_test",
)

apple_resource_bundle(
    name = "NestedResources",
    resources = ["Nested/value.txt"],
)

apple_resource_bundle(
    name = "MetadataOnlyResources",
    bundle_id = "com.example.rules-xcodeproj.metadata-only",
    infoplists = ["Info.plist"],
)

apple_resource_bundle(
    name = "RawResources",
    bundle_id = "com.example.rules-xcodeproj.dual-aspect",
    infoplists = ["Info.plist"],
    resources = glob(["Resources/**"]) + [
        ":MetadataOnlyResources",
        ":NestedResources",
    ],
)

dual_aspect_resource_bundle_test(
    name = "dual_aspect_resource_bundle",
    target = ":RawResources",
)

multiple_generators_resource_bundle_test(
    name = "multiple_generators_resource_bundle",
    first_target = ":RawResources",
    second_target = ":RawResources",
)

test_suite(
    name = "preview_resource_bundles",
    tests = [
        ":dual_aspect_resource_bundle",
        ":multiple_generators_resource_bundle",
        ":shared_consumer_resource_bundle",
    ],
)

swift_library(
    name = "ResourceLibrary",
    srcs = ["ResourceLibrary.swift"],
    data = [":RawResources"],
    module_name = "ResourceLibrary",
    tags = ["manual"],
)

swift_library(
    name = "ResourceAppLibrary",
    srcs = ["ResourceApp.swift"],
    tags = ["manual"],
    deps = [":ResourceLibrary"],
)

macos_application(
    name = "ResourceApp",
    bundle_id = "com.example.preview-resources.app",
    infoplists = ["Info.plist"],
    minimum_os_version = "13.0",
    tags = ["manual"],
    deps = [":ResourceAppLibrary"],
)

macos_dynamic_framework(
    name = "ResourceFramework",
    bundle_id = "com.example.preview-resources.framework",
    bundle_name = "ResourceLibrary",
    infoplists = ["Info.plist"],
    minimum_os_version = "13.0",
    tags = ["manual"],
    deps = [":ResourceLibrary"],
)

shared_consumer_resource_bundle_test(
    name = "shared_consumer_resource_bundle",
    app = ":ResourceApp",
    framework = ":ResourceFramework",
)

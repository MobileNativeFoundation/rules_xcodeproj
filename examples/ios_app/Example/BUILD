load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

ios_application(
    name = "Example",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = "io.buildbuddy.example",
    bundle_name = "Example",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    resources = [":ExampleResourceGroup"],
    visibility = ["//visibility:public"],
    deps = [":Example.library"],
)

apple_resource_group(
    name = "ExampleResourceGroup",
    resources = glob(
        [
            "Assets.xcassets/**",
            "*.lproj/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
    structured_resources = ["nested/answer.txt"],
)

swift_library(
    name = "Example.library",
    srcs = glob(["**/*.swift"]),
    data = [":ExampleLibraryResourceGroup"] + select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "Example",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [
        "//Utils",
        "//third_party:ExampleFramework",
        "@examples_ios_app_external//:ExternalFramework",
    ],
)

apple_resource_group(
    name = "ExampleLibraryResourceGroup",
    resources = ["//ExampleResources"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)

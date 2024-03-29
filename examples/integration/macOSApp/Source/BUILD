load("@build_bazel_rules_apple//apple:macos.bzl", "macos_application", "macos_dynamic_framework")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:versioning.bzl", "apple_bundle_version")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

apple_bundle_version(
    name = "Version",
    build_version = "123.4.5",
    short_version_string = "123.4",
    visibility = ["//:__subpackages__"],
)

macos_application(
    name = "macOSApp",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = "rules-xcodeproj.macOSApp",
    bundle_name = "macOSApp",
    frameworks = [
        ":macOSLib.framework",
    ],
    infoplists = [":Info.plist"],
    minimum_os_version = "12.0",
    resources = [":ResourceGroup"],
    version = ":Version",
    visibility = [
        "//macOSApp/Test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [":macOSApp.library"],
)

macos_dynamic_framework(
    name = "macOSLib.framework",
    bundle_id = "rules-xcodeproj.macOSApp.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    infoplists = ["//Lib:Info.plist"],
    minimum_os_version = "12.0",
    version = "//iOSApp:Version",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = ["//Lib"],
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(
        [
            "Assets.xcassets/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
)

swift_library(
    name = "macOSApp.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "macOSApp",
    tags = ["manual"],
    deps = [
        "//Lib",
        "//macOSApp/third_party:ExampleFramework",
    ],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
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
    entitlements = "app.entitlements",
    executable_name = "Example_ExecutableName",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    launch_storyboard = "Launch.storyboard",
    minimum_os_version = "15.0",
    resources = glob(
        [
            "Assets.xcassets/**",
            "Model.xcdatamodeld/**",
            "*.lproj/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
    visibility = ["//visibility:public"],
    deps = [
        ":Example.library",
    ],
)

swift_library(
    name = "Example.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "Example",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)

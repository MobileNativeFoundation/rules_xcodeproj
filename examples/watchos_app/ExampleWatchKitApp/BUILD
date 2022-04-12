load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_application")

watchos_application(
    name = "ExampleWatchKitApp",
    app_icons = ["AppIcon.xcassets"],
    bundle_id = "io.buildbuddy.example.watch",
    extension = "//examples/watchos_app/ExampleWatchKitExtension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    version = "//examples/watchos_app/Example:Version",
    visibility = ["//examples/watchos_app:__subpackages__"],
)

filegroup(
    name = "AppIcon.xcassets",
    srcs = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
)

load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_application")

watchos_application(
    name = "ExampleWatchKitApp",
    app_icons = ["AppIcon.xcassets"],
    bundle_id = "io.buildbuddy.example.watch",
    extension = "//examples/multiplatform/watchOSApp/ExampleWatchKitExtension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    version = "//examples/multiplatform/watchOSApp/Example:Version",
    visibility = ["//examples/multiplatform/watchOSApp:__subpackages__"],
)

filegroup(
    name = "AppIcon.xcassets",
    srcs = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
)

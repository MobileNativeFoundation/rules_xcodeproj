load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_application")

watchos_application(
    name = "watchOSApp",
    app_icons = ["AppIcon.xcassets"],
    bundle_id = "io.buildbuddy.example.watch",
    extension = "//examples/multiplatform/watchOSAppExtension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    version = "//examples/multiplatform/iOSApp:Version",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "AppIcon.xcassets",
    srcs = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
)

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_application(
    name = "ExampleLaunchImages",
    bundle_id = "io.buildbuddy.examplelaunchimages",
    bundle_name = "ExampleLaunchImages",
    entitlements = "app.entitlements",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    launch_images = glob(["launch_images_ios.xcassets/**"]),
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [
        "ExampleLaunchImages.library",
    ],
)

swift_library(
    name = "ExampleLaunchImages.library",
    srcs = glob(["**/*.swift"]),
    module_name = "ExampleLaunchImages",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

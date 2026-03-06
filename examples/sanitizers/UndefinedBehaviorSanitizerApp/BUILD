load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@rules_cc//cc:objc_library.bzl", "objc_library")

ios_application(
    name = "UndefinedBehaviorSanitizerApp",
    bundle_id = "rules-xcodeproj.example",
    bundle_name = "UndefinedBehaviorSanitizerApp",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [
        ":UndefinedBehaviorSanitizerApp.library",
    ],
)

objc_library(
    name = "UndefinedBehaviorSanitizerApp.library",
    srcs = [
        "Sources/AppDelegate.h",
        "Sources/AppDelegate.m",
        "Sources/main.m",
    ],
    sdk_frameworks = ["UIKit"],
    tags = ["manual"],
)

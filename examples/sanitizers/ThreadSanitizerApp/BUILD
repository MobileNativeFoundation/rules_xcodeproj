load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_application(
    name = "ThreadSanitizerApp",
    bundle_id = "rules-xcodeproj.example",
    bundle_name = "ThreadSanitizerApp",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [
        ":ThreadSanitizerApp.library",
    ],
)

swift_library(
    name = "ThreadSanitizerApp.library",
    srcs = glob(["**/*.swift"]),
    module_name = "ThreadSanitizerApp",
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

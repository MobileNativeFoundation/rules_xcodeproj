load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_application(
    name = "AddressSanitizerApp",
    bundle_id = "rules-xcodeproj.example",
    bundle_name = "AddressSanitizerApp",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [
        ":AddressSanitizerApp.library",
    ],
)

swift_library(
    name = "AddressSanitizerApp.library",
    srcs = glob(["**/*.swift"]),
    module_name = "AddressSanitizerApp",
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

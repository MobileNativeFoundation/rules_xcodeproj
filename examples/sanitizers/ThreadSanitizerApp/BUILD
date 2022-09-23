load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcodeproj",
)
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
    "XCODEPROJ_TARGETS",
)
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:versioning.bzl", "apple_bundle_version")

apple_bundle_version(
    name = "Version",
    build_version = "123.4.5",
    short_version_string = "123.4",
    visibility = ["//:__subpackages__"],
)

ios_application(
    name = "ThreadSanitizerApp",
    bundle_id = IOS_BUNDLE_ID,
    bundle_name = "ThreadSanitizerApp",
    executable_name = "ThreadSanitizerApp_ExecutableName",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    version = ":Version",
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

xcodeproj(
    name = "xcodeproj",
    project_name = "cc",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

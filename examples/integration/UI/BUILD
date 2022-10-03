load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_framework")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "UI",
    srcs = glob(["*.swift"]),
    copts = ["-application-extension"],
    module_name = "UI",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [
        "//Lib",
    ],
    alwayslink = True,
)

ios_framework(
    name = "UIFramework.iOS",
    hdrs = ["UI.h"],
    bundle_id = "io.budilebuddy.UIFramework",
    extension_safe = True,
    families = ["iphone"],
    frameworks = ["//Lib:LibFramework.iOS"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":UI"],
)

tvos_framework(
    name = "UIFramework.tvOS",
    bundle_id = "io.budilebuddy.UIFramework",
    extension_safe = True,
    frameworks = ["//Lib:LibFramework.tvOS"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":UI"],
)

watchos_framework(
    name = "UIFramework.watchOS",
    bundle_id = "io.budilebuddy.UIFramework",
    bundle_name = "UI",
    extension_safe = True,
    frameworks = ["//Lib:LibFramework.watchOS"],
    infoplists = ["Info.plist"],
    minimum_os_version = "7.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":UI"],
)

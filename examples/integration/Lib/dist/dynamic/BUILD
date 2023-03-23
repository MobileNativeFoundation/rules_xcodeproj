load("@build_bazel_rules_apple//apple:ios.bzl", "ios_dynamic_framework")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_dynamic_framework")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_dynamic_framework")

ios_dynamic_framework(
    name = "iOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    families = ["iphone"],
    infoplists = ["//Lib:Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = ["//Lib"],
)

tvos_dynamic_framework(
    name = "tvOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    infoplists = ["//Lib:Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = ["//Lib"],
)

watchos_dynamic_framework(
    name = "watchOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    infoplists = ["//Lib:Info.plist"],
    minimum_os_version = "7.0",
    version = "//iOSApp:Version",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = ["//Lib"],
)

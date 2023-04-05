load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

exports_files(
    ["Info.plist"],
    visibility = ["//Lib:__subpackages__"],
)

rules_ios_apple_framework(
    name = "Lib",
    srcs = ["Resources.swift"],
    bundle_id = "rules-xcodeproj.LibFramework",
    infoplists = ["Info.plist"],
    module_name = "Lib",
    platforms = {
        "ios": "15.0",
    },
    visibility = [
        "//Lib/dist/dynamic:__pkg__",
        "//UI:__pkg__",
        "//WidgetExtension:__subpackages__",
    ],
    xcconfig = {
        "APPLICATION_EXTENSION_API_ONLY": "YES",
    },
)

rules_ios_apple_framework(
    name = "LibDynamic",
    bundle_id = "rules-xcodeproj.LibFramework",
    infoplists = ["//Lib:Info.plist"],
    link_dynamic = True,
    module_name = "Lib",
    platforms = {
        "ios": "15.0",
    },
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    xcconfig = {
        "APPLICATION_EXTENSION_API_ONLY": "YES",
    },
    deps = [":Lib"],
)

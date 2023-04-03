load("@build_bazel_rules_ios//rules:framework.bzl", rules_ios_apple_framework = "apple_framework")

rules_ios_apple_framework(
    name = "iOS",
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
    deps = ["//Lib"],
)

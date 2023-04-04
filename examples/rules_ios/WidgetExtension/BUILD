load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_intent_library",
    "apple_resource_group",
)
load(
    "@build_bazel_rules_ios//rules:extension.bzl",
    rules_ios_ios_extension = "ios_extension",
)
load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
)

config_setting(
    name = "device_build",
    values = {
        "cpu": "ios_arm64",
    },
)

rules_ios_ios_extension(
    name = "WidgetExtension",
    bundle_id = "{}.widget-extension".format(IOS_BUNDLE_ID),
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    resources = [":ResourceGroup"],
    version = "//iOSApp:Version",
    visibility = ["//iOSApp:__subpackages__"],
    deps = [":WidgetExtension.library"],
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
)

rules_ios_apple_framework(
    name = "WidgetExtension.library",
    srcs = glob(["**/*.swift"]) + [":Intents.Intent.genrule.swift"],
    data = ["WidgetExtension.intentdefinition"],
    module_name = "WidgetExtension",
    platforms = {
        "ios": "15.0",
    },
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
    deps = [
        "//Lib",
    ],
)

apple_intent_library(
    name = "Intents",
    src = "WidgetExtension.intentdefinition",
    language = "Swift",
)

genrule(
    name = "Intents.Intent.genrule.swift",
    srcs = [":Intents"],
    outs = ["Intents.Intent.output.swift"],
    cmd = "cp \"$<\" \"$@\"",
    tags = ["manual"],
)

load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
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
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
    "TEAMID",
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
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = [":ResourceGroup"],
    version = "//iOSApp:Version",
    visibility = ["//iOSApp:__subpackages__"],
    deps = [":WidgetExtension.library"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}.widget-extension".format(IOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
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

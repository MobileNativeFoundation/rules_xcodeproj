load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_extension")
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_intent_library",
    "apple_resource_group",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
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

ios_extension(
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

swift_library(
    name = "WidgetExtension.library",
    srcs = glob(["**/*.swift"]) + [":Intents"],
    module_name = "WidgetExtension",
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

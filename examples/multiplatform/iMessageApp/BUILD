load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_imessage_application",
    "ios_imessage_extension",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:experimental.bzl",
    "xcode_provisioning_profile",
)
load(
    "//examples/multiplatform:xcodeproj_targets.bzl",
    "IMESSAGE_APP_BUNDLE_ID",
    "TEAMID",
)

IMESSAGE_EXTENSION_BUNDLE_ID = "{}.extension".format(IMESSAGE_APP_BUNDLE_ID)

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

config_setting(
    name = "device_build",
    values = {
        "cpu": "ios_arm64",
    },
)

ios_imessage_application(
    name = "iMessageApp",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = IMESSAGE_APP_BUNDLE_ID,
    bundle_name = "iMessageApp",
    extension = ":iMessageAppExtension",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    version = "//examples/multiplatform/iOSApp:Version",
    visibility = ["//visibility:public"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(IMESSAGE_APP_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

ios_imessage_extension(
    name = "iMessageAppExtension",
    bundle_id = IMESSAGE_EXTENSION_BUNDLE_ID,
    families = ["iphone"],
    infoplists = ["Info.extension.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":extension_xcode_profile",
        "//conditions:default": None,
    }),
    resources = glob(["*.lproj/**"]),
    version = "//examples/multiplatform/iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":iMessageAppExtension.library"],
)

swift_library(
    name = "iMessageAppExtension.library",
    srcs = glob(["**/*.swift"]),
    data = glob(["ExtensionAssets.xcassets/**"]),
    module_name = "iMessageAppExtension",
    tags = ["manual"],
    deps = [
        "//examples/multiplatform/Lib",
    ],
)

xcode_provisioning_profile(
    name = "extension_xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "extension_xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(IMESSAGE_EXTENSION_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

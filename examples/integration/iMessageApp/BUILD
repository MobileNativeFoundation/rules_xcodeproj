load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_imessage_application",
    "ios_imessage_extension",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("//:xcodeproj_targets.bzl", "IOS_BUNDLE_ID")

IMESSAGE_APP_BUNDLE_ID = "{}.imessage-app".format(IOS_BUNDLE_ID)

IMESSAGE_EXTENSION_BUNDLE_ID = "{}.extension".format(IMESSAGE_APP_BUNDLE_ID)

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
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
    version = "//iOSApp:Version",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

ios_imessage_extension(
    name = "iMessageAppExtension",
    bundle_id = IMESSAGE_EXTENSION_BUNDLE_ID,
    families = ["iphone"],
    infoplists = ["Info.extension.plist"],
    minimum_os_version = "15.0",
    resources = glob(["*.lproj/**"]),
    version = "//iOSApp:Version",
    deps = [":iMessageAppExtension.library"],
)

swift_library(
    name = "iMessageAppExtension.library",
    srcs = glob(["**/*.swift"]),
    data = glob(["ExtensionAssets.xcassets/**"]),
    module_name = "iMessageAppExtension",
    tags = ["manual"],
    deps = [
        "//Lib",
    ],
)

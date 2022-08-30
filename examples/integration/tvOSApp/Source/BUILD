load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:experimental.bzl",
    "xcode_provisioning_profile",
)
load(
    "//examples/integration:xcodeproj_targets.bzl",
    "TEAMID",
    "TVOS_BUNDLE_ID",
)

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

config_setting(
    name = "device_build",
    values = {
        "cpu": "tvos_arm64",
    },
)

tvos_application(
    name = "tvOSApp",
    bundle_id = TVOS_BUNDLE_ID,
    bundle_name = "tvOSApp",
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = ["//examples/integration/tvOSApp/Resources:ResourceGroup"],
    visibility = ["//visibility:public"],
    deps = [":tvOSApp.library"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "tvOS Team Provisioning Profile: {}".format(TVOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

swift_library(
    name = "tvOSApp.library",
    srcs = glob(["*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": ["//examples/integration/tvOSApp/Resources:PreviewContent"],
    }),
    module_name = "tvOSApp",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [
        "//examples/integration/Lib",
    ],
)

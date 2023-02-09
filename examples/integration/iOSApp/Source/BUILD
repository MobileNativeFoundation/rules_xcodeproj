load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
    "TEAMID",
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
        "cpu": "ios_arm64",
    },
)

ios_application(
    name = "iOSApp",
    alternate_icons = glob(["AltIcons/AltIcon-60.alticon/**"]),
    # app_clips = ["//AppClip"],
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = IOS_BUNDLE_ID,
    bundle_name = "iOSApp",
    entitlements = "ios app.entitlements",
    executable_name = "iOSApp_ExecutableName",
    # extensions = ["//WidgetExtension"],
    families = ["iphone"],
    # frameworks = [
    #     "//iOSApp/Source/CoreUtilsObjC:FrameworkCoreUtilsObjC",
    #     "//UI:UIFramework.iOS",
    # ],
    infoplists = [":Info.plist"],
    launch_images = select({
        ":device_build": glob(["launch_images_ios.xcassets/**"]),
        "//conditions:default": [],
    }),
    launch_storyboard = select({
        ":device_build": None,
        "//conditions:default": "Launch.storyboard",
    }),
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = [":ExampleResourceGroup"] + glob(
        [
            "Assets.xcassets/**",
            "Model.xcdatamodeld/**",
            "*.lproj/unprocessed.json",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
    strings = glob(["*.lproj/Localizable.strings"]),
    version = "//iOSApp:Version",
    visibility = [
        "//iOSApp:__pkg__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    # watch_application = "//watchOSApp",
    deps = [
        ":iOSApp.library",
        # "@rules_apple_linker//:lld",
    ],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(IOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(
        [
            "Assets.xcassets/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
)

apple_resource_group(
    name = "ExampleResourceGroup",
    resources = ["//iOSApp/Resources/ExampleNestedResources"],
    structured_resources = ["nested/answer.txt"],
)

swift_library(
    name = "iOSApp.library",
    srcs = glob(["**/*.swift"]) + [":many_strings"],
    data = [":ExampleLibraryResourceGroup"] + select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "iOSApp",
    tags = ["manual"],
    visibility = ["//iOSApp/Test:__subpackages__"],
    deps = [
        "//UI",
        "//iOSApp/Source/CoreUtilsMixed/MixedAnswer",
        "//iOSApp/Source/CoreUtilsObjC",
        "@com_google_google_maps//:GoogleMaps",
        "@firebase//:FirebaseCrashlytics",
        "@firebase//:FirebaseAnalyticsSwift",
    ],
)

genrule(
    name = "many_strings",
    outs = ["many_strings.swift"],
    cmd = """\
# Generate a swift file with 1000 random strings.
readonly str="dsjgiudfnbjkrtnbutrkbundtjbduthnbdjtbgdkunhldnbhjbdsrgyfsbkvrsjkvbrjbvjsbrvjhsbrvhsbrvnskvbrjhsbvjrsbvkrbsryjvkusegnlbrkubvsjhbvgsrtvuybsrvhsr45634bfsdvytfskbjt3478tgwiunvrweuyvbsurgbiuvuye6bvksrbvhjbsvyrvkueyrvbyrsbvkjsbverygb4ervsjcvjybvsruesdmhbsdjyfbsjchgsvhgfsbhjvbsjhcfhdjvdgvfhvjshbvcjsdhbcjshdvchsgvchjewyf6wjcesycvdytsvytdsvjhgdvtdvsyvsdgvcsghcruwtycvtrsybjchsbvyurctbsvvhjbsvyrvkueyrvbyrsbvkjsbverygb4ervsjcvjybvsruesdmhbsdjhfbsjchgsvhgfsbhjvbsjhcfhdjvdgvfhvjshbvcjsdhbcjshdvchsgvchjewyf6wjcesycvdytsvytdsvjhgdvtdvsyvsdgvcsghcruwtycvtrsybjchsbvyurctbsvjfgstehfjgtusqolbcjshdvchsgvchjewyf6wjcesycvdytsvytdsvjhgdvtdvsyvsdgvcsghcruwtycvtrsybjchsbvyurctbsvjfgstehfjgtusqol"
# for i in {1..10000}; do
#   echo "public let string$$i = \\"$$i$$str\\"" >> $@
# done

echo "public let strings: [String] = [" > $@
for i in {1..1000}; do
  echo "  \\"$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$i$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str$$str\\"," >> $@
done
echo "]" >> $@
""",
)

apple_resource_group(
    name = "ExampleLibraryResourceGroup",
    resources = ["//iOSApp/Resources/ExampleResources"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)

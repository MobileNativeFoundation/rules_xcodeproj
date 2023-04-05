load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "UI",
    srcs = glob(["*.swift"]),
    infoplists = ["Info.plist"],
    module_name = "UI",
    platforms = {
        "ios": "15.0",
    },
    public_headers = ["UI.h"],
    visibility = [
        "//iOSApp:__subpackages__",
        "//tvOSApp:__subpackages__",
        "//watchOSAppExtension:__subpackages__",
    ],
    deps = [
        "//Lib",
    ],
)

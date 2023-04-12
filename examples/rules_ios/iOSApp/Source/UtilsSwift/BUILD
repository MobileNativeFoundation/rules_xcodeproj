load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "UtilsSwift",
    srcs = glob(
        ["**/*.swift"],
    ),
    module_name = "UtilsSwift",
    platforms = {
        "ios": "15.0",
    },
    public_headers = [],
    tags = ["manual"],
    visibility = ["//iOSApp:__subpackages__"],
    deps = [
        "//iOSApp/Source/Utils:Utils",
    ],
)

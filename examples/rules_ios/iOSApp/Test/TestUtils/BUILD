load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "Utils",
    testonly = True,
    srcs = glob(
        ["**/*.swift"],
    ),
    module_name = "Test_Utils",
    platforms = {
        "ios": "15.0",
    },
    tags = ["manual"],
    visibility = ["//iOSApp:__subpackages__"],
)
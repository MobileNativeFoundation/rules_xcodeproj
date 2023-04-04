load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "Utils",
    srcs = glob(
        ["**/*.m"],
        # Headers included here on purpose, to test `hdrs` collection logic
        ["**/*.h"],
    ),
    module_name = "Utils",
    platforms = {
        "ios": "15.0",
    },
    public_headers = glob(["**/*.h"]),
    tags = ["manual"],
    visibility = ["//iOSApp:__subpackages__"],
    deps = [
        "//iOSApp/Source/CoreUtilsObjC",
    ],
)

load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "CoreUtilsObjC",
    srcs = glob(
        [
            "**/*.m",
            "**/*.mm",
            # Headers included here on purpose, to test `hdrs` collection logic
            "**/*.h",
        ],
        allow_empty = True,
    ),
    bundle_id = "rules-xcodeproj.CoreUtilsObjC",
    infoplists = ["Info.plist"],
    module_name = "CoreUtils",
    pch = "CoreUtils/CoreUtils.pch",
    platforms = {
        "ios": "15.0",
    },
    public_headers = ["CoreUtils/Answers.h"],
    sdk_dylibs = ["c++"],
    tags = ["manual"],
    visibility = ["//iOSApp:__subpackages__"],
)

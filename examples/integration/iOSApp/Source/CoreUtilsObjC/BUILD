load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")

objc_library(
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
    hdrs = ["CoreUtils/Answers.h"],
    includes = [""],
    module_name = "CoreUtils",
    pch = "CoreUtils/CoreUtils.pch",
    sdk_dylibs = ["c++"],
    tags = ["manual"],
    visibility = ["//iOSApp:__subpackages__"],
)

ios_framework(
    name = "FrameworkCoreUtilsObjC",
    hdrs = ["CoreUtils/Answers.h"],
    bundle_id = "rules-xcodeproj.CoreUtilsObjC",
    bundle_name = "CoreUtilsObjC",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//iOSApp:__subpackages__"],
    deps = [":CoreUtilsObjC"],
)

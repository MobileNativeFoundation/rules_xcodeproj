load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "MixedAnswer",
    srcs = [
        "MixedAnswer.m",
        "MixedAnswer.swift",
    ],
    bundle_id = "rules-xcodeproj.MixedAnswer",
    module_name = "MixedAnswer",
    platforms = {
        "ios": "15.0",
    },
    public_headers = ["MixedAnswer.h"],
    visibility = ["//iOSApp:__subpackages__"],
)

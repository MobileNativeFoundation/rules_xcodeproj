load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_unit_test = "ios_unit_test",
)
load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "Foo",
    vendored_xcframeworks = [
        {
            "name": "Foo",
            "slices": [
                {
                    "identifier": "ios-arm64",
                    "platform": "ios",
                    "platform_variant": "",
                    "supported_archs": ["arm64"],
                    "path": "ios/Foo.xcframework/ios-arm64/Foo.framework",
                    "build_type": {
                        "linkage": "dynamic",
                        "packaging": "framework",
                    },
                },
                {
                    "identifier": "ios-arm64_x86_64-simulator",
                    "platform": "ios",
                    "platform_variant": "simulator",
                    "supported_archs": [
                        "arm64",
                        "x86_64",
                    ],
                    "path": "ios/Foo.xcframework/ios-arm64_x86_64-simulator/Foo.framework",
                    "build_type": {
                        "linkage": "dynamic",
                        "packaging": "framework",
                    },
                },
            ],
        },
    ],
    visibility = ["//visibility:public"],
)

rules_ios_ios_unit_test(
    name = "iOSAppMixedUnitTests",
    srcs = glob([
        "**/*.m",
        "**/*.swift",
    ]),
    bundle_id = "rules-xcodeproj.example.mixedtests",
    minimum_os_version = "15.0",
    module_name = "iOSAppMixed_Unit_Tests",
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
        ":Foo",
    ],
)

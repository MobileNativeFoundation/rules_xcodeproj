"""Module extension for loading dependencies not yet compatible with bzlmod."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# buildifier: disable=function-docstring
def non_bzlmod_dependencies():
    http_archive(
        name = "build_bazel_rules_ios",
        sha256 = "810e3b2270ec781a51807478d188e51f1a5aad2247367509f17486e62dc151ac",
        urls = [
            "https://github.com/bazel-ios/rules_ios/archive/050a6dbf24f4e5e14fefa12a132d579da3231640.tar.gz",
        ],
        strip_prefix = "rules_ios-050a6dbf24f4e5e14fefa12a132d579da3231640",
    )

    http_archive(
        name = "arm64-to-sim",
        sha256 = "98a95d9376e10677910d40f9db6f9830e7e4105aaa1daae554ef49413e4de6fc",
        urls = [
            "https://github.com/bogo/arm64-to-sim/archive/25599a28689fa42679f23eb0ff031ebe57d3bb9b.tar.gz",
        ],
        strip_prefix = "arm64-to-sim-25599a28689fa42679f23eb0ff031ebe57d3bb9b",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "arm64-to-sim",
    srcs = glob(["Sources/arm64-to-sim/*.swift"]),
    visibility = ["//visibility:public"],
)
        """,
    )

    http_archive(
        name = "com_google_google_maps",
        build_file_content = """\
load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

apple_static_xcframework_import(
    name = "GoogleMaps",
    sdk_frameworks = ["SystemConfiguration"],
    xcframework_imports = glob(
        ["GoogleMaps.xcframework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
    deps = [":GoogleMapsCore"],
)

apple_static_xcframework_import(
    name = "GoogleMapsBase",
    sdk_dylibs = [
        "c++",
        "z",
    ],
    sdk_frameworks = [
        "CoreLocation",
        "CoreTelephony",
    ],
    xcframework_imports = glob(
        ["GoogleMapsBase.xcframework/**"],
        exclude = ["**/.*"],
    ),
)

apple_static_xcframework_import(
    name = "GoogleMapsCore",
    xcframework_imports = glob(
        ["GoogleMapsCore.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [":GoogleMapsBase"],
)
""",
        sha256 = "2308155fc29655ee3722e1829bd2c1b09f457b7140bc65cad6116dd8a4ca8bff",
        strip_prefix = "GoogleMaps-6.2.1-beta",
        url = "https://dl.google.com/geosdk/GoogleMaps-6.2.1-beta.tar.gz",
    )

    http_archive(
        name = "com_github_krzyzanowskim_cryptoswift",
        build_file_content = """\
load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework"
)

# This is a subset of the `vendored_xcframeworks` parameter.
rules_ios_apple_framework(
    name = "CryptoSwift",
    platforms = {"ios": "9.0"},
    swift_version = "5.3",
    vendored_xcframeworks = [
        {
            "name": "CryptoSwift",
            "slices": [
                {
                    "identifier": "ios-arm64_i386_x86_64-simulator",
                    "platform": "ios",
                    "platform_variant": "simulator",
                    "supported_archs": [
                        "i386",
                        "arm64",
                        "x86_64",
                    ],
                    "path": "CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework",
                    "build_type": {
                        "linkage": "dynamic",
                        "packaging": "framework",
                    },
                },
                {
                    "identifier": "ios-arm64_armv7",
                    "platform": "ios",
                    "platform_variant": "",
                    "supported_archs": [
                        "arm64",
                        "armv7",
                    ],
                    "path": "CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework",
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
""",
        sha256 = "b251155dce1e5f705f40bf1d531d56851b90f1907a8ff07d0e0c471f12316515",
        url = "https://github.com/krzyzanowskim/CryptoSwift/releases/download/1.5.1/CryptoSwift.xcframework.zip",
    )

    http_archive(
        name = "FXPageControl",
        build_file_content = """
objc_library(
    name = "FXPageControl",
    module_name = "FXPageControl",
    hdrs = ["FXPageControl/FXPageControl.h"],
    sdk_frameworks = ["CoreGraphics"],
    srcs = ["FXPageControl/FXPageControl.m"],
    visibility = ["//visibility:public"],
)
""",
        sha256 = "1610603d6ccfbc80b17aa2944c2587f4800c06a4e229303f431091e4e2e7a6d1",
        strip_prefix = "FXPageControl-1.5",
        url = "https://github.com/nicklockwood/FXPageControl/archive/refs/tags/1.5.tar.gz",
    )

    http_archive(
        name = "xctestrunner",
        sha256 = "f66233a3b40e78d2d0e33c937c8147ff6b2553d82284376700b9630d9672d31e",
        urls = [
            "https://github.com/google/xctestrunner/archive/3ec25f572c091b7111b7d351f9328fa67468baf5.tar.gz",
        ],
        strip_prefix = "xctestrunner-3ec25f572c091b7111b7d351f9328fa67468baf5",
    )

non_module_deps = module_extension(implementation = lambda _: non_bzlmod_dependencies())

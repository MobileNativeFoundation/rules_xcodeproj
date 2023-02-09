"""Module extension for loading dependencies not yet compatible with bzlmod."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def non_bzlmod_dependencies():
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
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_xcframework_import",
)

apple_dynamic_xcframework_import(
    name = "CryptoSwift",
    xcframework_imports = glob(
        ["CryptoSwift.xcframework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "b251155dce1e5f705f40bf1d531d56851b90f1907a8ff07d0e0c471f12316515",
        url = "https://github.com/krzyzanowskim/CryptoSwift/releases/download/1.5.1/CryptoSwift.xcframework.zip",
    )

    http_archive(
        name = "firebase",
        build_file_content = """\
load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

apple_static_xcframework_import(
    name = "FirebaseAnalyticsSwift",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FirebaseAnalyticsSwift.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [":FirebaseAnalytics"],
    visibility = ["//visibility:public"],
)

apple_static_xcframework_import(
    name = "FirebaseAnalytics",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FirebaseAnalytics.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [":FirebaseCore", ":GoogleAppMeasurement", ":GoogleAppMeasurementIdentitySupport", ":FirebaseInstallations"],
)

apple_static_xcframework_import(
    name = "FirebaseCore",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FirebaseCore.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":GoogleUtilities",
        ":FirebaseCoreInternal",
    ],
    visibility = ["//visibility:public"],
)

apple_static_xcframework_import(
    name = "GoogleAppMeasurement",
    xcframework_imports = glob(
        ["FirebaseAnalytics/GoogleAppMeasurement.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":nanopb",
    ],
    visibility = ["//visibility:public"],
)

apple_static_xcframework_import(
    name = "GoogleAppMeasurementIdentitySupport",
    xcframework_imports = glob(
        ["FirebaseAnalytics/GoogleAppMeasurementIdentitySupport.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":nanopb",
    ],
    visibility = ["//visibility:public"],
)

apple_static_xcframework_import(
    name = "FirebaseCoreInternal",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FirebaseCoreInternal.xcframework/**"],
        exclude = ["**/.*"],
    ),
)

apple_static_xcframework_import(
    name = "FirebaseCrashlytics",
    xcframework_imports = glob(
        ["FirebaseCrashlytics/FirebaseCrashlytics.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":FBLPromises",
        ":FirebaseCore",
        ":FirebaseInstallations",
        ":GoogleDataTransport",
        ":GoogleUtilities",
        ":nanopb",
    ],
    visibility = ["//visibility:public"],
)

apple_static_xcframework_import(
    name = "FirebaseInstallations",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FirebaseInstallations.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":FBLPromises",
        ":FirebaseCore",
        ":GoogleUtilities",
    ],
)

apple_static_xcframework_import(
    name = "GoogleDataTransport",
    xcframework_imports = glob(
        ["FirebaseCrashlytics/GoogleDataTransport.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [
        ":FBLPromises",
        ":GoogleUtilities",
        ":nanopb",
    ],
)

apple_static_xcframework_import(
    name = "GoogleUtilities",
    xcframework_imports = glob(
        ["FirebaseAnalytics/GoogleUtilities.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [":FBLPromises"],
)

apple_static_xcframework_import(
    name = "nanopb",
    xcframework_imports = glob(
        ["FirebaseAnalytics/nanopb.xcframework/**"],
        exclude = ["**/.*"],
    ),
)

apple_static_xcframework_import(
    name = "FBLPromises",
    xcframework_imports = glob(
        ["FirebaseAnalytics/FBLPromises.xcframework/**"],
        exclude = ["**/.*"],
    ),
)
""",
        sha256 = "ebc5cbdda13ffa7f711176b4f936445c3484892a98e491e49443abc5fce98393",
        strip_prefix = "Firebase",
        url = "https://github.com/firebase/firebase-ios-sdk/releases/download/10.5.0/Firebase.zip",
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

non_module_deps = module_extension(implementation = lambda _: non_bzlmod_dependencies())

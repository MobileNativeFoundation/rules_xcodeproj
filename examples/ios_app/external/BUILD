load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_framework_import",
)
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_bundle_import",
    "apple_resource_bundle",
)
load("@rules_cc//cc:defs.bzl", "objc_import", "objc_library")

apple_dynamic_framework_import(
    name = "ExternalFramework",
    framework_imports = glob(
        ["ExternalFramework.framework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
)

apple_resource_bundle(
    name = "ExternalResources",
    bundle_id = "com.example.resources.external",
    infoplists = ["Info.plist"],
    resources = glob(["Assets.xcassets/**"]),
    structured_resources = ["nested/hello.txt"],
    visibility = ["//visibility:public"],
)

apple_bundle_import(
    name = "ExternalImportedBundle",
    bundle_imports = glob(["bundles/Utils.bundle/**"]),
    visibility = ["//visibility:public"],
)

objc_import(
    name = "Library",
    hdrs = ["ImportableLibrary/Library.h"],
    archives = ["ImportableLibrary/libImportableLibrary.a"],
    visibility = ["//visibility:public"],
)

# Don't use this directly, instead use it to construct ImportableLibrary.a and
# depend on that instead:
# $ bazel build @examples_ios_app_external//:ImportableLibrary --cpu=ios_sim_arm64 --apple_platform_type=ios --ios_sdk_version="15.0"
# $ bazel build @examples_ios_app_external//:ImportableLibrary --cpu=x86_64 --apple_platform_type=ios --ios_sdk_version="15.0"
# $ lipo -create -output ... ... libImportableLibrary.a
objc_library(
    name = "ImportableLibrary",
    srcs = [
        "ImportableLibrary/Library.m",
    ],
    hdrs = ["ImportableLibrary/Library.h"],
    includes = ["ImportableLibrary"],
    tags = ["manual"],
)

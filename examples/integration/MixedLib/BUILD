load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_build_test",
)
load(
    "@build_bazel_rules_swift//mixed_language:mixed_language_library.bzl",
    "mixed_language_library",
)
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_precompiled_resource_bundle",
)

ios_build_test(
    name = "ios_MixedLib",
    minimum_os_version = "16.0",
    targets = [":MixedLib"],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

apple_precompiled_resource_bundle(
    name = "MixedLibResourceBundle",
    bundle_name = "MixedLibResources",
    resources = glob(
        [
            "Model.xcdatamodeld/*",
        ],
        exclude_directories = 0,
    ),
)

mixed_language_library(
    name = "MixedLib",
    hdrs = ["MixedObjC.h"],
    clang_srcs = ["MixedObjC.m"],
    enable_modules = True,
    module_name = "MixedLib",
    data = [":MixedLibResourceBundle"],
    swift_copts = ["-application-extension"],
    swift_srcs = ["MixedSwift.swift"],
    tags = ["manual"],
    visibility = [
        "//Lib:__subpackages__",
    ],
    alwayslink = True,
)

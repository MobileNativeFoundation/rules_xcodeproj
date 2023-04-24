load("@build_bazel_rules_apple//apple:macos.bzl", "macos_bundle")

cc_library(
    name = "aplugin.library",
    srcs = ["main.c"],
    alwayslink = True,
)

macos_bundle(
    name = "Bundle",
    bundle_extension = "aplugin",
    bundle_id = "rules-xcodeproj.example.ABundle",
    bundle_name = "ABundle",
    codesign_inputs = [":aplugin.library"],
    infoplists = [":Info.plist"],
    minimum_os_version = "12.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":aplugin.library"],
)

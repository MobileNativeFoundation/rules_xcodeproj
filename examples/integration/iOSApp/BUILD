load("@build_bazel_rules_apple//apple:versioning.bzl", "apple_bundle_version")

alias(
    name = "iOSApp",
    actual = "//iOSApp/Source:iOSApp",
    visibility = ["//visibility:public"],
)

apple_bundle_version(
    name = "Version",
    build_version = "123.4.5",
    short_version_string = "123.4",
    visibility = ["//:__subpackages__"],
)

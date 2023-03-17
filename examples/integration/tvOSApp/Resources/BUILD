load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
    visibility = ["//tvOSApp:__subpackages__"],
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
    visibility = ["//tvOSApp:__subpackages__"],
)

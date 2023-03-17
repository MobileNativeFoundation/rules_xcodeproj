load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")

apple_resource_bundle(
    name = "OnlyStructuredResources",
    bundle_id = "com.example.only_structured_resources",
    bundle_name = "OnlyStructuredResources",
    infoplists = ["Info.plist"],
    structured_resources = glob(["Nested/*.json"]),
    visibility = ["//iOSApp:__subpackages__"],
)

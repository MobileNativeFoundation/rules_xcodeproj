load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")

apple_resource_bundle(
    name = "ExampleResources",
    bundle_id = "com.example.resources",
    infoplists = ["Info.plist"],
    resources = glob(["Assets.xcassets/**"]),
    structured_resources = ["nested/hello.txt"],
    visibility = ["//visibility:public"],
)

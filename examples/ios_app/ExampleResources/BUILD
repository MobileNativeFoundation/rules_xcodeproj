load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load(":dep_resources_collector.bzl", "dep_resources_collector")

apple_resource_bundle(
    name = "ExampleResources",
    bundle_id = "com.example.resources",
    infoplists = ["Info.plist"],
    resources = glob(["Assets.xcassets/**"]) + [
        "//ExampleNestedResources",
        ":deps_txt",
    ],
    structured_resources = ["nested/hello.txt"],
    visibility = ["//visibility:public"],
)

dep_resources_collector(
    name = "deps_txt",
    deps = ["//Utils"],
)

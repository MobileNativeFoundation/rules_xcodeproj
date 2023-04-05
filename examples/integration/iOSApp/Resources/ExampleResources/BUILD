load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load(":dep_resources_collector.bzl", "dep_resources_collector")

apple_resource_bundle(
    name = "ExampleResources",
    bundle_id = "com.example.resources",
    infoplists = ["Info.plist"],
    resources = glob(["Assets.xcassets/**"]) + [
        ":deps_txt",
        "//iOSApp/Resources/ExampleNestedResources",
    ],
    structured_resources = ["nested/hello.txt"],
    visibility = ["//iOSApp:__subpackages__"],
)

dep_resources_collector(
    name = "deps_txt",
    deps = ["//iOSApp/Source/Utils"],
)

filegroup(
    name = "exported_resources",
    srcs = glob(["Assets.xcassets/**"]),
    visibility = ["//iOSApp:__subpackages__"],
)

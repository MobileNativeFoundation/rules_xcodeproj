load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")

apple_resource_bundle(
    name = "ExampleNestedResources",
    bundle_id = "com.example.resources.nested",
    infoplists = ["Info.plist"],
    resources = glob([
        "Assets.xcassets/**",
        "*.lproj/**",
    ]) + ["@examples_ios_app_external//:ExternalImportedBundle"],
    structured_resources = glob(["dir/**"]),
    visibility = ["//visibility:public"],
)

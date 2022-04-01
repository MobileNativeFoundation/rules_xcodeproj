load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_framework_import",
)
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_bundle_import",
    "apple_resource_bundle",
)

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

load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_framework_import",
)

apple_dynamic_framework_import(
    name = "ExampleFramework",
    framework_imports = glob(
        ["ExampleFramework.framework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
)

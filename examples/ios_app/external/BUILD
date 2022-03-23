load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_framework_import",
)

apple_dynamic_framework_import(
    name = "ExternalFramework",
    framework_imports = glob(
        ["ExternalFramework.framework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
)

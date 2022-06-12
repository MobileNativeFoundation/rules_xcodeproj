load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_framework_import",
)

apple_static_framework_import(
    name = "ExampleFramework",
    framework_imports = glob(
        ["ExampleFramework.framework/**"],
        exclude = ["**/.*"],
    ),
    sdk_frameworks = ["Foundation"],
    visibility = ["//visibility:public"],
    weak_sdk_frameworks = ["SwiftUI"],
)

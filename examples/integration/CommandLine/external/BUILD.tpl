load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_framework_import",
)

apple_static_framework_import(
    name = "ExternalFramework",
    framework_imports = glob(
        ["ExternalFramework.framework/**"],
        exclude = ["**/.*"],
    ),
    sdk_frameworks = ["Foundation"],
    visibility = ["//visibility:public"],
    weak_sdk_frameworks = ["SwiftUI"],
    alwayslink = True,
)

objc_import(
    name = "Library",
    hdrs = ["ImportableLibrary/Library.h"],
    archives = ["ImportableLibrary/libImportableLibrary.a"],
    visibility = ["//visibility:public"],
)

# Don't use this directly, instead use it to construct ImportableLibrary.a and
# depend on that instead:
# $ bazel build @examples_command_line_external//:ImportableLibrary --cpu=darwin_arm64 --macos_sdk_version="11.0"
# $ bazel build @examples_command_line_external//:ImportableLibrary --cpu=darwin_x86_64 --macos_sdk_version="11.0"
# $ lipo -create -output ... ... libImportableLibrary.a
objc_library(
    name = "ImportableLibrary",
    srcs = [
        "ImportableLibrary/Library.m",
    ],
    hdrs = ["ImportableLibrary/Library.h"],
    includes = ["ImportableLibrary"],
    tags = ["manual"],
)

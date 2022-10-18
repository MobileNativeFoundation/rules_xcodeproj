load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework", "ios_unit_test")

swift_library(
    name = "SomeModule",
    srcs = ["somemodule.swift"],
    module_name = "SomeModule",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "SomeModuleTestsLib",
    srcs = ["test_somemodule.swift"],
    tags = ["manual"],
    deps = [":SomeModule"],
    testonly = True,
)

ios_unit_test(
    name = "SomeModuleTests",
    deps = [":SomeModuleTestsLib"],
    minimum_os_version = "14.0",
    visibility = ["//visibility:public"]
)

ios_framework(
    name = "SomeModuleFramework.iOS",
    bundle_id = "io.budilebuddy.UIFramework",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "14.0",
    visibility = ["//visibility:public"],
    deps = [":SomeModule"],
)

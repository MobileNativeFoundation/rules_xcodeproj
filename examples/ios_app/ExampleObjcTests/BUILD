load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")

ios_unit_test(
    name = "ExampleObjcTests",
    bundle_id = "io.buildbuddy.example.objctests",
    minimum_os_version = "15.0",
    test_host = "//Example",
    visibility = ["//visibility:public"],
    deps = [":ExampleObjcTests.library"],
)

objc_library(
    name = "ExampleObjcTests.library",
    testonly = True,
    srcs = glob(["**/*.m"]),
    data = ["@examples_ios_app_external//:ExternalImportedBundle"],
    enable_modules = True,
    module_name = "ExampleObjcTests",
    tags = ["manual"],
    deps = [
        "//Example:Example.library",
        "//TestingUtils",
        "//Utils",
    ],
)

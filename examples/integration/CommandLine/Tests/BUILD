load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CommandLineToolTests",
    testonly = True,
    srcs = glob(["*.swift"]),
    module_name = "LibSwiftTestsLib",
    deps = [
        "//examples/integration/CommandLine/CommandLineToolLib:lib_swift",
    ],
    visibility = [
        "//visibility:public",
    ],
)

macos_unit_test(
    name = "CommandLineToolLibSwiftTests",
    minimum_os_version = "11.0",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":CommandLineLibSwiftTestsLib",
    ],
)

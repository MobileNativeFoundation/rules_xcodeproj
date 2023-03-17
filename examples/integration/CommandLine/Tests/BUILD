load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CommandLineLibSwiftTestsLib",
    testonly = True,
    srcs = glob(["*.swift"]),
    module_name = "LibSwiftTestsLib",
    deps = [
        "//CommandLine/CommandLineToolLib:lib_swift",
    ],
)

macos_unit_test(
    name = "CommandLineToolTests",
    minimum_os_version = "11.0",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        ":CommandLineLibSwiftTestsLib",
    ],
)

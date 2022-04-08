load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "LibSwiftTestsLib",
    srcs = glob(["*.swift"]),
    module_name = "LibSwiftTestsLib",
    deps = [
        "//examples/command_line/lib:lib_swift",
    ],
)

macos_unit_test(
    name = "LibSwiftTests",
    minimum_os_version = "11.0",
    visibility = [
        "//examples/command_line:__subpackages__",
        "//test/fixtures/command_line:__subpackages__",
    ],
    deps = [
        ":LibSwiftTestsLib",
    ],
)

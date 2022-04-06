load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

swift_library(
    name = "tests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "tests",
    deps = [
        "//tools/generator:generator.library",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

swift_test(
    name = "tests",
    visibility = [
        "//test:__subpackages__",
        "//tools/generator:__subpackages__",
    ],
    deps = [
        ":tests.library",
    ],
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

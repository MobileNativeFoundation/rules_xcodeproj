load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

swift_library(
    name = "tests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "tests",
    deps = [
        "//tools/generator:generator.library",
    ] + select({
        ":release_build": [],
        # This conditional dependency is to exercise how the Xcode configuration
        # logic handles conditional dependencies
        "//conditions:default": [
            "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
        ],
    }),
)

macos_unit_test(
    name = "tests",
    minimum_os_version = "12.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":tests.library",
    ],
)

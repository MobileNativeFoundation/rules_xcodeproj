load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("//xcodeproj:xcodeproj.bzl", "xcode_schemes", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

swift_library(
    name = "generator.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "generator",
    visibility = ["//tools/generator/test:__pkg__"],
    deps = [
        "@com_github_apple_swift_collections//:OrderedCollections",
        "@com_github_kylef_pathkit//:PathKit",
        "@com_github_tuist_xcodeproj//:XcodeProj",
    ],
)

swift_binary(
    name = "generator",
    visibility = ["//visibility:public"],
    deps = [
        ":generator.library",
    ],
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Generator",
        launch_action = xcode_schemes.launch_action(
            "//tools/generator:generator",
        ),
        test_action = xcode_schemes.test_action([
            "//tools/generator/test:tests",
        ]),
    ),
]

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "generator",
    # GH573: Revert to `auto` once custom schemes are implemented.
    scheme_autogeneration_mode = "all",
    schemes = _SCHEMES,
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
    "swift_test",
)

swift_library(
    name = "generator.library",
    module_name = "generator",
    srcs = glob(["src/**/*.swift"]),
    deps = [
        "@com_github_tuist_xcodeproj//:XcodeProj",
        "@com_github_kylef_pathkit//:PathKit",
    ],
)

swift_library(
    name = "tests.library",
    module_name = "tests",
    srcs = glob(["test/**/*.swift"]),
    testonly = True,
    deps = [
        ":generator.library",
    ],
)

swift_test(
    name = "tests",
    deps = [
        ":tests.library",
    ],
)

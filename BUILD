load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load(
    "@cgrindel_rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    "integration_test_utils",
)

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
    # Buildifier wants to add a rules_cc load statement for objc_library.
    # We do not want to add a dependency on this ruleset, at this time.
    "examples/ios_app/Utils/BUILD",
]

_BUILDIFIER_WARNINGS = [
    # GH176: Enable all Buildifier warnings.
    # "all",
]

buildifier(
    name = "buildifier.check",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "warn",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "diff",
)

buildifier(
    name = "buildifier.fix",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "fix",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "fix",
)

# Integration test related targets

package_group(
    name = "integration_test_visibility",
    packages = [
        "//examples/...",
    ],
)

filegroup(
    name = "all_files",
    srcs = glob(["*"]),
)

filegroup(
    name = "local_repository_files",
    srcs = [
        ":all_files",
        "//third_party/com_github_pointfreeco_swift_custom_dump:all_files",
        "//third_party/com_github_tuist_xcodeproj:all_files",
        "//tools:all_files",
        "//tools/generator:all_files",
        "//xcodeproj:all_files",
        "//xcodeproj/internal:all_files",
    ],
    visibility = [":integration_test_visibility"],
)

test_suite(
    name = "all_integration_tests",
    # If you don't apply the test tags to the test suite, the test suite will
    # be found when `bazel test //...` is executed.
    tags = integration_test_utils.DEFAULT_INTEGRATION_TEST_TAGS,
    tests = [
        "//examples:all_integration_tests",
    ],
    visibility = ["//:__subpackages__"],
)

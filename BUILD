load("@buildifier_prebuilt//:rules.bzl", "buildifier")

# Release

filegroup(
    name = "release_files",
    srcs = [
        "LICENSE",
        "MODULE.bazel",
        "//tools:release_files",
        "//xcodeproj:release_files",
    ],
    tags = ["manual"],
    visibility = ["//distribution:__subpackages__"],
)

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
    "./xcodeproj/internal/*.template.*",
    "**/bazel-output-base/*",
    "**/.rules_xcodeproj/*",
    "**/*.xcodeproj/*",
]

_BUILDIFIER_WARNINGS = [
    "all",
    "-native-cc",
]

buildifier(
    name = "buildifier.check",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "warn",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "diff",
    tags = ["manual"],
)

buildifier(
    name = "buildifier.fix",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "fix",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "fix",
    tags = ["manual"],
)

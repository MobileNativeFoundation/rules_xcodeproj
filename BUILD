load("@buildifier_prebuilt//:rules.bzl", "buildifier")

# See the note in __init__.py for why this is needed.
py_library(
    name = "py_init_shim",
    testonly = 1,
    srcs = ["__init__.py"],
    visibility = ["//tools:__subpackages__"],
)

# Release

exports_files(["MODULE.bazel"])

genrule(
    name = "release_MODULE.bazel",
    srcs = ["MODULE.bazel"],
    outs = ["MODULE.release.bazel"],
    cmd = """\
set -euo pipefail

perl -0777 -pe 's/\n# Non-release dependencies.*//s' $< > $@
    """,
    tags = ["manual"],
)

filegroup(
    name = "release_files",
    srcs = [
        "LICENSE",
        ":release_MODULE.bazel",
        "//tools:release_files",
        "//xcodeproj:release_files",
    ],
    tags = ["manual"],
    visibility = ["//distribution:__subpackages__"],
)

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
    "./xcodeproj/internal/templates/*",
    "./test/fixtures/**/generated/*",
    "**/bazel-output-base/*",
    "**/test/fixtures/generated/*",
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

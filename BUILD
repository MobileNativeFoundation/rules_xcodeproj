load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

# Release

filegroup(
    name = "release",
    srcs = [
        ":release_pkg",
        ":release_pkg_sha256",
    ],
)

genrule(
    name = "release_pkg_sha256",
    srcs = [":release_pkg"],
    outs = ["release.tar.gz.sha256"],
    cmd = """\
set -euo pipefail

shasum -a 256 $< > $@
    """,
    tags = ["manual"],
)

pkg_tar(
    name = "release_pkg",
    srcs = [":release_files"],
    mode = "0444",
    owner = "0.0",
    package_file_name = "release.tar.gz",
    extension = "tar.gz",
    strip_prefix = ".",
    tags = ["manual"],
)

filegroup(
    name = "release_files",
    srcs = [
        "LICENSE",
        "MODULE.bazel",
        "//third_party:release_files",
        "//tools:release_files",
        "//xcodeproj:release_files",
    ],
    tags = ["manual"],
)

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
    "**/bazel-output-base/*",
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

load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
load("//examples/multiplatform:xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

# Release

# TODO: Use rules_pkg
genrule(
    name = "release",
    srcs = [":release_files"],
    outs = [
        "release.tar.gz",
        "release.tar.gz.sha256",
    ],
    cmd = """\
set -euo pipefail

outs=($(OUTS))

COPYFILE_DISABLE=1 tar czvfh "$${outs[0]}" \
  --exclude .DS_Store \
  --exclude **/*.xcodeproj \
  --exclude ^bazel-out/ \
  --exclude ^external/ \
  *
shasum -a 256 "$${outs[0]}" > "$${outs[1]}"
    """,
)

filegroup(
    name = "release_files",
    srcs = [
        "LICENSE",
        "//third_party:release_files",
        "//tools:release_files",
        "//xcodeproj:release_files",
    ],
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
)

buildifier(
    name = "buildifier.fix",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "fix",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "fix",
)

# TODO(chuck): FIX ME!

# CHUCK DEBUG

xcodeproj(
    name = "xcodeproj",
    # TODO(chuck): REVERT ME!
    build_mode = "bazel",
    project_name = "Multiplatform",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

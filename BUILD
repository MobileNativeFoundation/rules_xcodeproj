load("@buildifier_prebuilt//:rules.bzl", "buildifier")

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
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

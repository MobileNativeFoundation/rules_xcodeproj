load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@rules_python//python:defs.bzl", "py_library")

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
    "attr-cfg",
    "attr-non-empty",
    "attr-output-default",
    "attr-single-file",
    "build-args-kwargs",
    "bzl-visibility",
    "confusing-name",
    "constant-glob",
    "ctx-actions",
    "ctx-args",
    "deprecated-function",
    "depset-items",
    "depset-iteration",
    "depset-union",
    "dict-concatenation",
    "dict-method-named-arg",
    "duplicated-name",
    "filetype",
    "function-docstring",
    "function-docstring-args",
    "function-docstring-header",
    "function-docstring-return",
    "git-repository",
    "http-archive",
    "integer-division",
    "keyword-positional-params",
    "list-append",
    "load",
    "load-on-top",
    "module-docstring",
    "name-conventions",
    "native-py",
    "no-effect",
    "out-of-order-load",
    "output-group",
    "overly-nested-depset",
    "package-name",
    "package-on-top",
    "positional-args",
    "print",
    "provider-params",
    "redefined-variable",
    "repository-name",
    "return-value",
    "rule-impl-return",
    "same-origin-load",
    "skylark-comment",
    "skylark-docstring",
    "string-iteration",
    "uninitialized",
    "unnamed-macro",
    "unreachable",
    "unsorted-dict-items",
    "unused-variable",
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

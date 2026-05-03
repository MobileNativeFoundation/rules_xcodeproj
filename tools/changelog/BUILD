load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

py_library(
    name = "update_release_changelog_library",
    srcs = ["update_release_changelog.py"],
    srcs_version = "PY3",
    visibility = ["//visibility:public"],
)

py_binary(
    name = "update_release_changelog",
    srcs = ["update_release_changelog.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [":update_release_changelog_library"],
)

py_test(
    name = "update_release_changelog_tests",
    srcs = ["update_release_changelog_tests.py"],
    deps = [
        ":update_release_changelog_library",
        "//:py_init_shim",
    ],
)

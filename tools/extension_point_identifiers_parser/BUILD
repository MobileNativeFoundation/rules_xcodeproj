load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "extension_point_identifiers_parser",
    srcs = ["extension_point_identifiers_parser.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ),
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

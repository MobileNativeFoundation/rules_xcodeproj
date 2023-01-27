load("@rules_pkg//:mappings.bzl", "pkg_files", "strip_prefix")

py_binary(
    name = "xccurrentversions_parser",
    srcs = ["xccurrentversions_parser.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

# Release

pkg_files(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ),
    strip_prefix = strip_prefix.from_root(),
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "xccurrentversions_parser",
    srcs = ["xccurrentversions_parser.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

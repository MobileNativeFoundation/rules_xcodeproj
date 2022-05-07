filegroup(
    name = "bazel_integration_files",
    srcs = glob(["**/*"]),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

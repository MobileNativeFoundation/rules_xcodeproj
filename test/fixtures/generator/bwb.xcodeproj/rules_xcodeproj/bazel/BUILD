exports_files(["create_lldbinit.sh"])

filegroup(
    name = "bazel_integration_files",
    srcs = glob(
        ["**/*"],
        exclude = ["create_lldbinit.sh"],
    ),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)

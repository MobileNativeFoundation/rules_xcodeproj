filegroup(
    name = "base_integration_files",
    srcs = [
        "calculate_output_groups.py",
        "create_lldbinit.sh",
    ],
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

filegroup(
    name = "bazel_integration_files",
    srcs = glob(
        ["**/*"],
        exclude = [
            "BUILD",
            "calculate_output_groups.py",
            "create_lldbinit.sh",
        ],
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

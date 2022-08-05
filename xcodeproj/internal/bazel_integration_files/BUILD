_BASE_FILES = [
    "calculate_output_groups.py",
    "create_lldbinit.sh",
    "process_bazel_build_log.py",
]

filegroup(
    name = "base_integration_files",
    srcs = _BASE_FILES,
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

filegroup(
    name = "bazel_integration_files",
    srcs = glob(
        ["**/*"],
        exclude = _BASE_FILES + ["BUILD"],
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

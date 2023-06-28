py_library(
    name = "selected_model_versions_library",
    srcs = ["selected_model_versions.py"],
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

py_binary(
    name = "selected_model_versions",
    srcs = ["selected_model_versions.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
    deps = [":selected_model_versions_library"],
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

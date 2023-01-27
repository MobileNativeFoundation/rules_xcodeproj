load("@rules_pkg//:mappings.bzl", "pkg_files")

py_binary(
    name = "link_params_processor",
    srcs = ["link_params_processor.py"],
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
    prefix = package_name().split("/")[-1],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

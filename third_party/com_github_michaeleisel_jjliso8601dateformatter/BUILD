load("@rules_pkg//:mappings.bzl", "pkg_files")

# Release

pkg_files(
    name = "release_files",
    srcs = glob(
        ["*"],
        exclude = [
            "**/.*",
        ],
    ),
    prefix = package_name().split("/")[-1],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

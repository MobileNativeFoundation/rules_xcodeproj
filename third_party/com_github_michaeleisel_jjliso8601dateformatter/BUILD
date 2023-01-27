load("@rules_pkg//:mappings.bzl", "pkg_files", "strip_prefix")

# Release

pkg_files(
    name = "release_files",
    srcs = glob(
        ["*"],
        exclude = [
            "**/.*",
        ],
    ),
    strip_prefix = strip_prefix.from_root(),
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

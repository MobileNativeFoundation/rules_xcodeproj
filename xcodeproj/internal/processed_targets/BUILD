load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "processed_targets",
    srcs = glob(["*.bzl"]),
    visibility = ["//:__subpackages__"],
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

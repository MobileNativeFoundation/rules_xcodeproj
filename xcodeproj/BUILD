# Required for stardoc integration

exports_files([
    "experimental.doc.bzl",
    "xcodeproj.bzl",
])

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = ["testing.bzl"],
    ) + [
        "//" + package_name() + "/internal:release_files",
    ],
    visibility = ["//visibility:public"],
)

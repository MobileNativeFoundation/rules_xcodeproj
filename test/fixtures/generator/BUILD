load("//test/fixtures:fixtures.bzl", "xcodeproj_srcs")

exports_files([
    "spec.json",
])

filegroup(
    name = "xcodeproj",
    srcs = xcodeproj_srcs(),
    visibility = ["//test:__subpackages__"],
)

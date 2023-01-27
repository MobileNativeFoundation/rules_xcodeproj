load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files", "strip_prefix")

sh_binary(
    name = "set_bazel_5",
    srcs = ["set_bazel_5.sh"],
    tags = ["manual"],
)

# Release

pkg_files(
    name = "package_release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ),
    strip_prefix = strip_prefix.from_root(),
    tags = ["manual"],
)

pkg_filegroup(
    name = "release_files",
    srcs = [
        ":package_release_files",
        "//" + package_name() + "/extensionpointidentifiers_parser:release_files",
        "//" + package_name() + "/generator:release_files",
        "//" + package_name() + "/params_processors:release_files",
        "//" + package_name() + "/swiftc_stub:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files", "strip_prefix")

# Release

pkg_files(
    name = "package_release_files",
    srcs = glob(
        ["*"],
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
        "//" + package_name() + "/com_github_michaeleisel_jjliso8601dateformatter:release_files",
    ],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

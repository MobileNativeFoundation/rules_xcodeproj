load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files")

# Release

pkg_files(
    name = "package_release_files",
    srcs = glob(
        ["*"],
        exclude = [
            "**/.*",
        ],
    ),
    tags = ["manual"],
)

pkg_filegroup(
    name = "release_files",
    srcs = [
        ":package_release_files",
        "//" + package_name() + "/com_github_michaeleisel_jjliso8601dateformatter:release_files",
    ],
    prefix = package_name().split("/")[-1],
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

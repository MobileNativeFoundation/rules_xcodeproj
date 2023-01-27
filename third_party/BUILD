# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["*"],
        exclude = [
            "**/.*",
        ],
    ) + [
        "//" + package_name() + "/com_github_michaeleisel_jjliso8601dateformatter:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

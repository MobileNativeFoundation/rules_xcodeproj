exports_files(
    glob(
        ["*"],
        exclude = ["BUILD"],
    )
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
            "updater.sh",
            "validator.sh",
        ],
    ),
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

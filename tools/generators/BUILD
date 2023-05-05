exports_files(["README.md"])

# Release

filegroup(
    name = "release_files",
    srcs = [
        "//" + package_name() + "/legacy:release_files",
        # TODO: Uncomment when we start using the incremental generator
        # "//" + package_name() + "/pbxproject_prefix:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

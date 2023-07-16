exports_files(["README.md"])

# Release

filegroup(
    name = "release_files",
    srcs = [
        # TODO: Uncomment when we start using the incremental generator
        # "//" + package_name() + "/files_and_groups:release_files",
        "//" + package_name() + "/legacy:release_files",
        # TODO: Uncomment when we start using the incremental generator
        # "//" + package_name() + "/pbxproj_prefix:release_files",
        # "//" + package_name() + "/pbxproject_targets:release_files",
        # "//" + package_name() + "/selected_model_versions:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

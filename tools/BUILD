sh_binary(
    name = "set_release_archive_override",
    srcs = ["set_release_archive_override.sh"],
    tags = ["manual"],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "//" + package_name() + "/extensionpointidentifiers_parser:release_files",
        "//" + package_name() + "/generator:release_files",
        "//" + package_name() + "/params_processors:release_files",
        "//" + package_name() + "/swiftc_stub:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

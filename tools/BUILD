sh_binary(
    name = "set_bazel_5",
    srcs = ["set_bazel_5.sh"],
    tags = ["manual"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ) + [
        "//" + package_name() + "/extensionpointidentifiers_parser:release_files",
        "//" + package_name() + "/generator:release_files",
        "//" + package_name() + "/params_processors:release_files",
        "//" + package_name() + "/swiftc_stub:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    visibility = ["//visibility:public"],
)

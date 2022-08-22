# Release

filegroup(
    name = "release_files",
    srcs = glob(["**"]) + [
        "//" + package_name() + "/extensionpointidentifiers_parser:release_files",
        "//" + package_name() + "/generator:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    visibility = ["//visibility:public"],
)

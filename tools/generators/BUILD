exports_files(["README.md"])

# Release

filegroup(
    name = "release_files",
    srcs = [
        "//" + package_name() + "/files_and_groups:release_files",
        "//" + package_name() + "/legacy:release_files",
        "//" + package_name() + "/pbxnativetargets:release_files",
        "//" + package_name() + "/pbxproj_prefix:release_files",
        "//" + package_name() + "/pbxtargetdependencies:release_files",
        "//" + package_name() + "/selected_model_versions:release_files",
        "//" + package_name() + "/swift_debug_settings:release_files",
        "//" + package_name() + "/target_build_settings:release_files",
        "//" + package_name() + "/xcschemes:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)

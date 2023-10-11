load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load(":opt_wrapper.bzl", "opt_wrapper")
load(":expanded_pkg.bzl", "expanded_pkg")

opt_wrapper(
    name = "release",
    dep = ":release_filegroup",
    tags = ["manual"],
)

filegroup(
    name = "release_filegroup",
    srcs = [
        ":release_pkg",
        ":release_pkg_sha256",
    ],
    tags = ["manual"],
)

genrule(
    name = "release_pkg_sha256",
    srcs = [":release_pkg"],
    outs = ["release.tar.gz.sha256"],
    cmd = """\
set -euo pipefail

shasum -a 256 $< > $@
    """,
    tags = ["manual"],
)

_GENERATORS = [
    "tools/generators/files_and_groups/universal_files_and_groups",
    "tools/generators/legacy/universal_generator",
    "tools/generators/pbxnativetargets/universal_pbxnativetargets",
    "tools/generators/pbxproj_prefix/universal_pbxproj_prefix",
    "tools/generators/pbxtargetdependencies/universal_pbxtargetdependencies",
    "tools/generators/swift_debug_settings/universal_swift_debug_settings",
    "tools/generators/target_build_settings/universal_target_build_settings",
    "tools/generators/xcschemes/universal_xcschemes",
]

pkg_tar(
    name = "release_pkg",
    srcs = [
        "//:release_files",
    ],
    extension = "tar.gz",
    mode = "0444",
    modes = {
        # "tools/generators/G/prebuilt_universal_G": "0744"
        paths.dirname(g) + "/prebuilt_" + paths.basename(g): "0744"
        for g in _GENERATORS
    },
    owner = "0.0",
    package_file_name = "release.tar.gz",
    remap_paths = dicts.add(
        {
            "MODULE.release.bazel": "MODULE.bazel",
            "tools/import_indexstores/BUILD.release.bazel": (
                "tools/import_indexstores/BUILD"
            ),
            "tools/swiftc_stub/BUILD.release.bazel": "tools/swiftc_stub/BUILD",
            "xcodeproj/repositories.release.bzl": "xcodeproj/repositories.bzl",
        },
        {
            # "tools/generators/G/BUILD.release.bazel": "tools/generators/G/BUILD"
            paths.dirname(g) + "/BUILD.release.bazel": paths.dirname(g) + "/BUILD"
            for g in _GENERATORS
        },
        {
            # "tools/generators/G/universal_G": "tools/generators/G/prebuilt_universal_G"
            g: paths.dirname(g) + "/prebuilt_" + paths.basename(g)
            for g in _GENERATORS
        },
    ),
    strip_prefix = "/",
    tags = ["manual"],
)

expanded_pkg(
    name = "expanded_release",
    dep = ":release_pkg",
    tags = ["manual"],
)

opt_wrapper(
    name = "opt_expanded_release",
    dep = ":expanded_release",
    tags = ["manual"],
)

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load(":opt_wrapper.bzl", "opt_wrapper")

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

pkg_tar(
    name = "release_pkg",
    srcs = [
        "//:release_files",
    ],
    extension = "tar.gz",
    mode = "0444",
    modes = {
        "tools/generators/files_and_groups/prebuilt_universal_files_and_groups": "0744",
        "tools/generators/legacy/prebuilt_universal_generator": "0744",
        "tools/generators/pbxnativetargets/prebuilt_universal_pbxnativetargets": "0744",
        "tools/generators/pbxproj_prefix/prebuilt_universal_pbxproj_prefix": "0744",
        "tools/generators/pbxtargetdependencies/prebuilt_universal_pbxtargetdependencies": "0744",
        "tools/generators/target_build_settings/prebuilt_universal_target_build_settings": "0744",
    },
    owner = "0.0",
    package_file_name = "release.tar.gz",
    remap_paths = {
        "MODULE.release.bazel": "MODULE.bazel",
        "tools/generators/files_and_groups/BUILD.release.bazel": (
            "tools/generators/files_and_groups/BUILD"
        ),
        "tools/generators/files_and_groups/universal_files_and_groups": (
            "tools/generators/files_and_groups/prebuilt_universal_files_and_groups"
        ),
        "tools/generators/legacy/BUILD.release.bazel": (
            "tools/generators/legacy/BUILD"
        ),
        "tools/generators/legacy/universal_generator": (
            "tools/generators/legacy/prebuilt_universal_generator"
        ),
        "tools/generators/pbxnativetargets/BUILD.release.bazel": (
            "tools/generators/pbxnativetargets/BUILD"
        ),
        "tools/generators/pbxnativetargets/universal_pbxnativetargets": (
            "tools/generators/pbxnativetargets/prebuilt_universal_pbxnativetargets"
        ),
        "tools/generators/pbxproj_prefix/BUILD.release.bazel": (
            "tools/generators/pbxproj_prefix/BUILD"
        ),
        "tools/generators/pbxproj_prefix/universal_pbxproj_prefix": (
            "tools/generators/pbxproj_prefix/prebuilt_universal_pbxproj_prefix"
        ),
        "tools/generators/pbxtargetdependencies/BUILD.release.bazel": (
            "tools/generators/pbxtargetdependencies/BUILD"
        ),
        "tools/generators/pbxtargetdependencies/universal_pbxtargetdependencies": (
            "tools/generators/pbxtargetdependencies/prebuilt_universal_pbxtargetdependencies"
        ),
        "tools/generators/target_build_settings/BUILD.release.bazel": (
            "tools/generators/target_build_settings/BUILD"
        ),
        "tools/generators/target_build_settings/universal_target_build_settings": (
            "tools/generators/target_build_settings/prebuilt_universal_target_build_settings"
        ),
        "tools/swiftc_stub/BUILD.release.bazel": "tools/swiftc_stub/BUILD",
        "xcodeproj/repositories.release.bzl": "xcodeproj/repositories.bzl",
    },
    strip_prefix = "/",
    tags = ["manual"],
)

genrule(
    name = "expanded_release_pkg",
    srcs = [":release_pkg"],
    outs = ["expanded_release"],
    cmd = """\
set -euo pipefail

mkdir "$@"
tar -xf $< -C "$@"
touch "$@/WORKSPACE"
    """,
    tags = ["manual"],
)

opt_wrapper(
    name = "opt_expanded_release_pkg",
    dep = ":expanded_release_pkg",
    tags = ["manual"],
)

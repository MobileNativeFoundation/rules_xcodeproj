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
        "tools/generator/prebuilt_universal_generator": "0744",
    },
    owner = "0.0",
    package_file_name = "release.tar.gz",
    remap_paths = {
        "tools/generator/BUILD.release.bazel": "tools/generator/BUILD",
        "tools/generator/universal_generator": "tools/generator/prebuilt_universal_generator",
        "tools/swiftc_stub/BUILD.release.bazel": "tools/swiftc_stub/BUILD",
    },
    strip_prefix = "/",
    tags = ["manual"],
)

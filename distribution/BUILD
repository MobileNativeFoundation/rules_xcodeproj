load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

filegroup(
    name = "release",
    srcs = [
        ":release_pkg",
        ":release_pkg_sha256",
    ],
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
    owner = "0.0",
    package_file_name = "release.tar.gz",
    strip_prefix = "/",
    tags = ["manual"],
)

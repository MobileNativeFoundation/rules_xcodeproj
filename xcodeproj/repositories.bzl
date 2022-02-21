"""Definitions for handling Bazel repositories used by rules_xcodeproj."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:logging.bzl",
    "green",
    "yellow",
    "warn",
)

def _maybe(repo_rule, name, ignore_version_differences, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
        repo_rule: The repository rule to be executed (e.g., `http_archive`.)
        name: The name of the repository to be defined by the rule.
        ignore_version_differences: If `True`, warnings about potentially
            incompatible versions of depended-upon repositories will be
            silenced.
        **kwargs: Additional arguments passed directly to the repository rule.
    """
    if native.existing_rule(name):
        if not ignore_version_differences:
            # Verify that the repository is being loaded from the same URL and
            # tag that we asked for, and warn if they differ.
            # This isn't perfect, because the user could load from the same
            # commit SHA as the tag, or load from an HTTP archive instead of a
            # Git repository, but this is a good first step toward validating.
            # Bzlmod will remove the need for all of this in the longer term.
            existing_repo = native.existing_rule(name)
            if (existing_repo.get("remote") != kwargs.get("remote") or
                existing_repo.get("tag") != kwargs.get("tag")):
                expected = "{url} (tag {tag})".format(
                    tag = kwargs.get("tag"),
                    url = kwargs.get("remote"),
                )
                existing = "{url} (tag {tag})".format(
                    tag = existing_repo.get("tag"),
                    url = existing_repo.get("remote"),
                )

                warn("""\
`com_github_buildbuddy_io_rules_xcodeproj` depends on `{repo}` loaded from \
{expected}, but we have detected it already loaded into your workspace from \
{existing}. You may run into compatibility issues. To silence this warning, \
pass `ignore_version_differences = True` to `rules_xcodeproj_dependencies()`.
""".format(
                    existing = yellow(existing),
                    expected = green(expected),
                    repo = name,
                ))
        return

    repo_rule(name = name, **kwargs)

def xcodeproj_rules_dependencies(ignore_version_differences = False):
    """Fetches repositories that are dependencies of `rules_xcodeproj`.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of rules_xcodeproj are downloaded and that they are isolated
    from changes to those dependencies.

    Args:
        ignore_version_differences: If `True`, warnings about potentially
            incompatible versions of dependency repositories will be silenced.
    """
    _maybe(
        http_archive,
        name = "bazel_skylib",
        url = "https://github.com/bazelbuild/bazel-skylib/archive/df3c9e2735f02a7fe8cd80db4db00fec8e13d25f.tar.gz",
        strip_prefix = "bazel-skylib-df3c9e2735f02a7fe8cd80db4db00fec8e13d25f",
        sha256 = "58f558d04a936cade1d4744d12661317e51f6a21e3dd7c50b96dc14f3fa3b87d",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "build_bazel_rules_swift",
        url = "https://github.com/bazelbuild/rules_swift/releases/download/0.26.0/rules_swift.0.26.0.tar.gz",
        sha256 = "3e52a508cdc47a7adbad36a3d2b712e282cc39cc211b0d63efcaf608961eb36b",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_kylef_pathkit",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PathKit",
    srcs = glob(["Sources/**/*.swift"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "fcda78cdf12c1c6430c67273333e060a9195951254230e524df77841a0235dae",
        strip_prefix = "PathKit-1.0.1",
        url = "https://github.com/kylef/PathKit/archive/refs/tags/1.0.1.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_tadija_aexml",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AEXML",
    srcs = glob(["Sources/AEXML/**/*.swift"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "5a76c28e4fa9dcc1cbfb87a8518652628e990e522ecfbc98bdad17eabf4631d5",
        strip_prefix = "AEXML-4.6.1",
        url = "https://github.com/tadija/AEXML/archive/refs/tags/4.6.1.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_tuist_xcodeproj",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "XcodeProj",
    srcs = glob(["Sources/XcodeProj/**/*.swift"]),
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_tadija_aexml//:AEXML",
        "@com_github_kylef_pathkit//:PathKit",
    ],
)
""",
        patches = [
            "@com_github_buildbuddy_io_rules_xcodeproj//third_party/com_github_tuist_xcodeproj:parent_equatable.patch",
        ],
        sha256 = "83e3b19effa03338482989d38d6c8875faf3bee82fc4ababf81bda29cbdcf849",
        strip_prefix = "XcodeProj-8.7.1",
        url = "https://github.com/tuist/XcodeProj/archive/refs/tags/8.7.1.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

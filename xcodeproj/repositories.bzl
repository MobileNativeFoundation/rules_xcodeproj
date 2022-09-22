"""Definitions for handling Bazel repositories used by rules_xcodeproj."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//xcodeproj/internal:logging.bzl", "green", "warn", "yellow")

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
pass `ignore_version_differences = True` to `xcodeproj_rules_dependencies()`.
""".format(
                    existing = yellow(existing),
                    expected = green(expected),
                    repo = name,
                ))
        return

    repo_rule(name = name, **kwargs)

# buildifier: disable=unnamed-macro
def xcodeproj_rules_dependencies(
        ignore_version_differences = False,
        use_dev_patches = False):
    """Fetches repositories that are dependencies of `rules_xcodeproj`.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of rules_xcodeproj are downloaded and that they are isolated
    from changes to those dependencies.

    Args:
        ignore_version_differences: If `True`, warnings about potentially
            incompatible versions of dependency repositories will be silenced.
        use_dev_patches: If `True`, use patches that are intended to be
            applied to the development version of the repository.
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
        url = "https://github.com/bazelbuild/rules_swift/releases/download/1.2.0/rules_swift.1.2.0.tar.gz",
        sha256 = "51efdaf85e04e51174de76ef563f255451d5a5cd24c61ad902feeadafc7046d9",
        ignore_version_differences = ignore_version_differences,
    )

    # `rules_swift` depends on `build_bazel_rules_swift_index_import`, and we
    # also need to use `index-import`, so we could declare the same dependency
    # here in order to reuse it, and in case `rules_swift` stops depending on it
    # in the future. We don't though, because we need 5.5.3.1 or higher, and the
    # currently lowest version of rules_swift we support uses 5.3.2.6.
    _maybe(
        http_archive,
        name = "rules_xcodeproj_index_import",
        build_file_content = """\
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "index_import",
    src = "index-import",
    out = "index-import",
    visibility = ["//visibility:public"],
)
""",
        url = "https://github.com/MobileNativeFoundation/index-import/releases/download/5.5.3.1/index-import.tar.gz",
        sha256 = "176ec3bf1e7ea4a0f5e320fc2fc666f4c736fb51d21a99a8ef134e19ed51ef5f",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.2/rules_apple.1.1.2.tar.gz",
        sha256 = "90e3b5e8ff942be134e64a83499974203ea64797fd620eddeb71b3a8e1bff681",
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

    if use_dev_patches:
        xcodeproj_patches = [
            # Custom for our tests
            "@com_github_buildbuddy_io_rules_xcodeproj//third_party/com_github_tuist_xcodeproj:parent_equatable.patch",
        ]
    else:
        xcodeproj_patches = []

    # Main branch as of 2022-09-07. Contains implementation for
    # XCScheme.ExecutionAction.shellToInvoke
    xcodeproj_git_sha = "b7e93122d08e59497211ea12f4da73e6a4d7d598"
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
        patches = xcodeproj_patches,
        sha256 = "376f13a99dcb70961ebde9fcaa7bfeb360422990161b7fb35954937f671574dc",
        strip_prefix = "XcodeProj-%s" % xcodeproj_git_sha,
        url = "https://github.com/tuist/XcodeProj/archive/%s.tar.gz" % xcodeproj_git_sha,
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_apple_swift_collections",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Collections",
    srcs = glob(["Sources/Collections/**/*.swift"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "DequeModule",
    srcs = glob(["Sources/DequeModule/**/*.swift"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "OrderedCollections",
    srcs = glob(["Sources/OrderedCollections/**/*.swift"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "b18c522aff4241160f60bcd0695702657c7862512c994c260a7d63f15a8450d8",
        strip_prefix = "swift-collections-1.0.2",
        url = "https://github.com/apple/swift-collections/archive/refs/tags/1.0.2.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        build_file_content = """\
package(default_visibility = ["//visibility:public"])

cc_library(
    name = "json",
    srcs = glob(
        ["include/nlohmann/**/*.hpp"],
        exclude = ["include/nlohmann/json.hpp"],
    ),
    hdrs = ["include/nlohmann/json.hpp"],
    includes = ["include"],
)
""",
        name = "com_github_nlohmann_json",
        urls = [
            "https://github.com/nlohmann/json/releases/download/v3.6.1/include.zip",
        ],
        sha256 = "69cc88207ce91347ea530b227ff0776db82dcb8de6704e1a3d74f4841bc651cf",
        ignore_version_differences = ignore_version_differences,
    )

    _cache_buster_repository(
        name = "rules_xcodeproj_top_level_cache_buster",
    )

def _cache_buster_repository_impl(repository_ctx):
    repository_ctx.file("BUILD", """\
exports_files(["top_level_cache_buster"])
""")
    repository_ctx.file("top_level_cache_buster", "")

_cache_buster_repository = repository_rule(
    implementation = _cache_buster_repository_impl,
)

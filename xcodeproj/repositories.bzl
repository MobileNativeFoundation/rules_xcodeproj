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
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        url = "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    # TODO: Change to 1.3.1+ once released.
    _maybe(
        http_archive,
        name = "build_bazel_rules_swift",
        sha256 = "75840ff8b761f381541915adcfdabdaa18ccc92a3a5dffb0d12d4d6d1b4f9081",
        strip_prefix = "rules_swift-7d8769a9d5024200da8a34999e5934b23f441e90",
        url = "https://github.com/bazelbuild/rules_swift/archive/7d8769a9d5024200da8a34999e5934b23f441e90.tar.gz",
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
        sha256 = "802f33638b996abe76285d1e0246e661919c0c3222877681e66c519f78145511",
        url = "https://github.com/MobileNativeFoundation/index-import/releases/download/5.7/index-import.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        sha256 = "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911",
        url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.3/rules_apple.1.1.3.tar.gz",
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
        name = "com_github_michaeleisel_jjliso8601dateformatter",
        build_file_content = """\
objc_library(
    name = "JJLISO8601DateFormatter",
    srcs = glob(["Sources/JJLISO8601DateFormatter/**/*"]),
    copts = [
        "-Wno-incompatible-pointer-types",
        "-Wno-incompatible-pointer-types-discards-qualifiers",
        "-Wno-shorten-64-to-32",
        "-Wno-unreachable-code",
        "-Wno-unused-function",
        "-Wno-unused-variable",
    ],
    includes = ["Sources/JJLISO8601DateFormatter/include"],
    hdrs = glob(["Sources/JJLISO8601DateFormatter/include/*"]),
    visibility = ["//visibility:public"],
)
""",
        patches = [
            "@com_github_buildbuddy_io_rules_xcodeproj//third_party/com_github_michaeleisel_jjliso8601dateformatter:missing_include.patch",
        ],
        sha256 = "cfd5fad808d321b6ba3389be7af39955e99736960e68e54ffd3927676664dc35",
        strip_prefix = "JJLISO8601DateFormatter-0.1.3",
        url = "https://github.com/michaeleisel/JJLISO8601DateFormatter/archive/refs/tags/0.1.3.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_michaeleisel_zippyjsoncfamily",
        build_file_content = """\
objc_library(
    name = "ZippyJSONCFamily",
    copts = [
        "-std=c++17",
        "-Wno-unused-function",
        "-Wno-reorder-ctor",
        "-Wno-return-type-c-linkage",
        "-Wno-shorten-64-to-32",
        "-Wno-unused-variable",
    ],
    srcs = glob(["Sources/ZippyJSONCFamily/**/*"]),
    includes = ["Sources/ZippyJSONCFamily/include"],
    hdrs = glob(["Sources/ZippyJSONCFamily/include/*"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "d729f2e30dbb738843ffa812d4f1a649b68f9266eea70a41c95b850306b4a8f7",
        strip_prefix = "ZippyJSONCFamily-1.2.5",
        url = "https://github.com/michaeleisel/ZippyJSONCFamily/archive/refs/tags/1.2.5.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_michaeleisel_zippyjson",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ZippyJSON",
    srcs = glob(["Sources/ZippyJSON/**/*.swift"]),
    deps = [
        "@com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter",
        "@com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily",
    ],
    visibility = ["//visibility:public"],
)
""",
        sha256 = "773169ecc97c18551ffbcc319d44ef06e40415a8d71b19b6a6b2e3100a312ad0",
        strip_prefix = "ZippyJSON-1.2.5",
        url = "https://github.com/michaeleisel/ZippyJSON/archive/refs/tags/1.2.5.tar.gz",
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

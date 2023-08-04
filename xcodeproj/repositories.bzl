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
`rules_xcodeproj` depends on `{repo}` loaded from \
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

def _generated_files_repo_impl(repository_ctx):
    repository_ctx.file(
        "BUILD",
        content = """
package_group(
    name = "package_group",
    packages = ["//..."],
)
""",
    )

    # Don't do anything on non-macOS platforms
    if repository_ctx.execute(["uname"]).stdout.strip() != "Darwin":
        return

    output_base_hash_result = repository_ctx.execute(
        ["bash", "-c", '/sbin/md5 -q -s "${PWD%/*/*/*/*}"'],
    )
    if output_base_hash_result.return_code != 0:
        fail("Failed to calculate output base hash: {}".format(
            output_base_hash_result.stderr,
        ))

    # Ensure that this repository is unique per output base
    output_base_hash = output_base_hash_result.stdout.strip()
    repository_ctx.symlink(
        "/var/tmp/rules_xcodeproj/generated_v2/{}/generator".format(output_base_hash),
        "generator",
    )

generated_files_repo = repository_rule(
    implementation = _generated_files_repo_impl,
)

# buildifier: disable=unnamed-macro
def xcodeproj_rules_dependencies(
        ignore_version_differences = False,
        include_bzlmod_ready_dependencies = True,
        internal_only = False):
    """Fetches repositories that are dependencies of `rules_xcodeproj`.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of rules_xcodeproj are downloaded and that they are isolated
    from changes to those dependencies.

    Args:
        ignore_version_differences: If `True`, warnings about potentially
            incompatible versions of dependency repositories will be silenced.
        include_bzlmod_ready_dependencies: Whether or not bzlmod-ready
            dependencies should be included.
        internal_only: If `True`, only internal dependencies will be included.
            Should only be called from `extensions.bzl`.
    """
    if internal_only or include_bzlmod_ready_dependencies:
        # Used to house generated files
        generated_files_repo(name = "rules_xcodeproj_generated")

    if internal_only:
        return

    if include_bzlmod_ready_dependencies:
        _maybe(
            http_archive,
            name = "bazel_skylib",
            sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
            url = "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
            ignore_version_differences = ignore_version_differences,
        )

        _maybe(
            http_archive,
            name = "build_bazel_rules_swift",
            sha256 = "b3b6c5c9f2a589150f71e79dec1e1ed0eb974dbd49e9317df4e09e08ff6e83df",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/1.9.1/rules_swift.1.9.1.tar.gz",
            ignore_version_differences = ignore_version_differences,
        )

        is_bazel_6 = hasattr(apple_common, "link_multi_arch_static_library")
        if is_bazel_6:
            rules_apple_sha256 = "2a0a35c9f72a0b0ac9238ecb081b0da4bb3e9739e25d2a910cc6b4c4425c01be"
            rules_apple_version = "2.4.1"
        else:
            rules_apple_sha256 = "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911"
            rules_apple_version = "1.1.3"

            # Without manually specifying apple_support version, we get the old
            # one set by rules_apple 1.1.3. We need a newer one for the newer
            # rules_swift.
            _maybe(
                http_archive,
                name = "build_bazel_apple_support",
                sha256 = "4f8dabf7cd16c23d2a406bbf60291c7c8c2e3c617e182a82585e1d3efe36670b",
                url = "https://github.com/bazelbuild/apple_support/releases/download/1.7.1/apple_support.1.7.1.tar.gz",
                ignore_version_differences = ignore_version_differences,
            )

        _maybe(
            http_archive,
            name = "build_bazel_rules_apple",
            sha256 = rules_apple_sha256,
            url = "https://github.com/bazelbuild/rules_apple/releases/download/{version}/rules_apple.{version}.tar.gz".format(version = rules_apple_version),
            ignore_version_differences = ignore_version_differences,
        )

    # `rules_swift` depends on `build_bazel_rules_swift_index_import`, and we
    # also need to use `index-import`, so we could declare the same dependency
    # here in order to reuse it, and in case `rules_swift` stops depending on it
    # in the future. We don't though, because we need 5.5.3.1 or higher, and the
    # current lowest version of rules_swift we support uses 5.3.2.6.
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
        sha256 = "28c1ffa39d99e74ed70623899b207b41f79214c498c603915aef55972a851a15",
        url = "https://github.com/MobileNativeFoundation/index-import/releases/download/5.8.0.1/index-import.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    # Source dependencies
    _xcodeproj_rules_source_dependencies(ignore_version_differences)

# buildifier: disable=unnamed-macro
def _xcodeproj_rules_source_dependencies(ignore_version_differences = False):
    """Fetches repositories that are dependencies of `rules_xcodeproj` when \
    building from source.

    Args:
        ignore_version_differences: If `True`, warnings about potentially
            incompatible versions of dependency repositories will be silenced.
    """
    _maybe(
        http_archive,
        name = "com_github_apple_swift_argument_parser",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ArgumentParserToolInfo",
    srcs = glob(["Sources/ArgumentParserToolInfo/**/*.swift"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "ArgumentParser",
    srcs = glob(["Sources/ArgumentParser/**/*.swift"]),
    visibility = ["//visibility:public"],
    deps = [":ArgumentParserToolInfo"],
)
""",
        sha256 = "44782ba7180f924f72661b8f457c268929ccd20441eac17301f18eff3b91ce0c",
        strip_prefix = "swift-argument-parser-1.2.2",
        url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.2.2.tar.gz",
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
            Label("//third_party/com_github_michaeleisel_jjliso8601dateformatter:include_fix.patch"),
        ],
        sha256 = "6fe15f251f100f3df057c2802a50765387674fde9c922375683682b5ba37eef0",
        strip_prefix = "JJLISO8601DateFormatter-0.1.6",
        url = "https://github.com/michaeleisel/JJLISO8601DateFormatter/archive/refs/tags/0.1.6.tar.gz",
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
        patches = [
            Label("//third_party/com_github_michaeleisel_zippyjsoncfamily:include_fix.patch"),
        ],
        sha256 = "b215927ada8403e1b056d39450c6a7b59122eca4b0c7fc5beb5f0b5fea2acd72",
        strip_prefix = "ZippyJSONCFamily-1.2.9",
        url = "https://github.com/michaeleisel/ZippyJSONCFamily/archive/refs/tags/1.2.9.tar.gz",
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
        sha256 = "4b256843c9c3686c527e76dde54f8d76b6201c1fd903c07dc2211ab1b250bd04",
        strip_prefix = "ZippyJSON-1.2.10",
        url = "https://github.com/michaeleisel/ZippyJSON/archive/refs/tags/1.2.10.tar.gz",
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
        sha256 = "70a4504d5cfd30e1c1968df3929bf0c40cba91bdb2ef0e3143c0e72bbe1d8092",
        strip_prefix = "XcodeProj-8.9.0",
        url = "https://github.com/tuist/XcodeProj/archive/refs/tags/8.9.0.tar.gz",
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
        sha256 = "1a2ec8cc6c63c383a9dd4eb975bf83ce3bc7a2ac21a0289a50dae98a576327d6",
        strip_prefix = "swift-collections-4cab1c1c417855b90e9cfde40349a43aff99c536",
        # TODO: Change to 1.0.5 when it's released
        url = "https://github.com/apple/swift-collections/archive/4cab1c1c417855b90e9cfde40349a43aff99c536.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

# buildifier: disable=unnamed-macro
def xcodeproj_rules_dev_dependencies(ignore_version_differences = False):
    # Setup Swift Custom Dump test dependency
    _maybe(
        http_archive,
        name = "com_github_pointfreeco_xctest_dynamic_overlay",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "XCTestDynamicOverlay",
    module_name = "XCTestDynamicOverlay",
    srcs = glob(["Sources/XCTestDynamicOverlay/**/*.swift"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "97169124feb98b409f5b890bd95bb147c2fba0dba3098f9bf24c539270ee9601",
        strip_prefix = "xctest-dynamic-overlay-0.2.1",
        url = "https://github.com/pointfreeco/xctest-dynamic-overlay/archive/refs/tags/0.2.1.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

    _maybe(
        http_archive,
        name = "com_github_pointfreeco_swift_custom_dump",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CustomDump",
    module_name = "CustomDump",
    srcs = glob(["Sources/CustomDump/**/*.swift"]),
    deps = ["@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay"],
    visibility = ["//visibility:public"],
)
""",
        patches = [
            # Custom for our tests
            Label("//third_party/com_github_pointfreeco_swift_custom_dump:type_name.patch"),
        ],
        sha256 = "9aec23538c2d050e3829200cd73ecb3c402d3922366ed2f6abb4f748f7582533",
        strip_prefix = "swift-custom-dump-0.11.1",
        url = "https://github.com/pointfreeco/swift-custom-dump/archive/refs/tags/0.11.1.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )

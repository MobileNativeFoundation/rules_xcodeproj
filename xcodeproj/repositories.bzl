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
                    existing = yellow(existing, bold = True),
                    expected = green(expected, bold = True),
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

    if repository_ctx.execute(["command", "-v", "/sbin/md5"]).return_code == 0:
        md5_command = "/sbin/md5"
    else:
        md5_command = "md5sum"

    output_base_hash_result = repository_ctx.execute(
        ["bash", "-c", "set -euo pipefail; echo \"${PWD%/*/*/*/*}\" | " + md5_command + " | awk '{print $1}'"],
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
            sha256 = "b17bdad10f3996cffc1ae3634e426d5280848cdb25ae5351f39357599938f5c6",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/3.0.2/rules_swift.3.0.2.tar.gz",
            ignore_version_differences = ignore_version_differences,
        )

        _maybe(
            http_archive,
            name = "build_bazel_rules_apple",
            sha256 = "b28822cb81916fb544119f5533de010cc67ec6a789f2e7d0fc19d53bfcbb8285",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/4.0.1/rules_apple.4.0.1.tar.gz",
            ignore_version_differences = ignore_version_differences,
        )

        _maybe(
            http_archive,
            name = "bazel_features",
            sha256 = "4912fc2f5d17199a043e65c108d3f0a2896061296d4c335aee5e6a3a71cc4f0d",
            strip_prefix = "bazel_features-1.4.0",
            url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.4.0/bazel_features-v1.4.0.tar.gz",
            ignore_version_differences = ignore_version_differences,
        )

    # `rules_swift` depends on `build_bazel_rules_swift_index_import`, and we
    # also need to use `index-import`, so we could declare the same dependency
    # here in order to reuse it, and in case `rules_swift` stops depending on it
    # in the future. We don't though, because we need 5.5.3.1 or higher, and the
    # current lowest version of rules_swift we support uses 5.3.2.6.
    # TODO: we must depend on two versions of index-import to support backwards
    # compatibility between Xcode 16.3+ and older versions, we can remove the older
    # version once we drop support for Xcode 16.x.
    index_import_build_file_content = """\
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "index_import",
    src = "index-import",
    out = "index-import",
    visibility = ["//visibility:public"],
)
"""
    _maybe(
        http_archive,
        name = "rules_xcodeproj_legacy_index_import",
        build_file_content = index_import_build_file_content,
        canonical_id = "index-import-5.8.0.1",
        sha256 = "28c1ffa39d99e74ed70623899b207b41f79214c498c603915aef55972a851a15",
        url = "https://github.com/MobileNativeFoundation/index-import/releases/download/5.8.0.1/index-import.tar.gz",
        ignore_version_differences = ignore_version_differences,
    )
    _maybe(
        http_archive,
        name = "rules_xcodeproj_index_import",
        build_file_content = index_import_build_file_content,
        canonical_id = "index-import-6.1.0.1",
        sha256 = "9a54fc1674af6031125a9884480a1e31e1bcf48b8f558b3e8bcc6b6fcd6e8b61",
        url = "https://github.com/MobileNativeFoundation/index-import/releases/download/6.1.0.1/index-import.tar.gz",
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
        sha256 = "4a10bbef290a2167c5cc340b39f1f7ff6a8cf4e1b5433b68548bf5f1e542e908",
        strip_prefix = "swift-argument-parser-1.2.3",
        url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.2.3.tar.gz",
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
        name = "com_github_apple_swift_collections",
        build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Collections",
    srcs = glob(["Sources/Collections/**/*.swift"]),
    deps = [
        "@com_github_apple_swift_collections//:DequeModule",
    ],
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
        sha256 = "1ebde9c9403d5befb6956556e26f9308000722f7da9e87fed2e770d3918d647c",
        strip_prefix = "swift-issue-reporting-0.2.1",
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

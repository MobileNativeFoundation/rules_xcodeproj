"""Tests for Preview framework output files."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:products.bzl", "products")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/files:output_files.bzl",
    "output_files",
    "output_groups",
)

def _paths(files):
    return sorted([file.path for file in files.to_list()])

def _collect_output_groups(ctx, preview_framework_files):
    (_, _, metadata) = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "target-id",
        name = ctx.label.name,
        output_group_info = None,
        preview_framework_files = preview_framework_files,
        swift_info = None,
        transitive_infos = [],
    )
    return output_groups.to_output_groups_fields(
        target_output_groups = output_groups.collect(
            metadata = metadata,
            transitive_infos = [],
        ),
    )

def _preview_framework_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    frameworks = [
        ctx.actions.declare_directory("First.framework"),
        ctx.actions.declare_directory("Frameworks With Spaces/Second.framework"),
    ]
    ctx.actions.run_shell(
        outputs = frameworks,
        arguments = [framework.path for framework in frameworks],
        command = "mkdir -p \"$1\" \"$2\"",
    )
    output_group_fields = _collect_output_groups(ctx, frameworks)

    asserts.equals(
        env,
        _paths(depset(frameworks)),
        _paths(output_group_fields["bf target-id"]),
        "Preview framework output group",
    )
    asserts.equals(
        env,
        [],
        [
            path
            for path in _paths(output_group_fields["bp target-id"])
            if path.endswith(".framework")
        ],
        "ordinary product output group",
    )
    for framework in frameworks:
        asserts.true(
            env,
            framework.path in _paths(output_group_fields["all_b"]),
            "all_b includes {}".format(framework.path),
        )

    return unittest.end(env)

def _empty_preview_framework_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    output_group_fields = _collect_output_groups(ctx, [])

    asserts.equals(
        env,
        [],
        output_group_fields["bf target-id"].to_list(),
        "empty Preview framework output group",
    )
    asserts.equals(
        env,
        [
            "all_b",
            "bc target-id",
            "bf target-id",
            "bi target-id",
            "bl target-id",
            "bp target-id",
        ],
        sorted(output_group_fields.keys()),
        "exported output groups",
    )

    return unittest.end(env)

preview_framework_output_group_test = unittest.make(
    _preview_framework_output_group_test_impl,
)
empty_preview_framework_output_group_test = unittest.make(
    _empty_preview_framework_output_group_test_impl,
)

def _archive_preview_framework_test_impl(ctx):
    archive = ctx.actions.declare_file("Archive Framework.zip")
    archive_args = ctx.actions.args()
    archive_args.add(ctx.executable._zipper)
    archive_args.add(archive)
    ctx.actions.run_shell(
        outputs = [archive],
        arguments = [archive_args],
        tools = [ctx.executable._zipper],
        command = """\
set -euo pipefail

readonly zipper="$PWD/$1"
readonly archive="$PWD/$2"
readonly staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

mkdir -p "$staging_dir/Archive Framework.framework/Resources"
printf 'binary' > "$staging_dir/Archive Framework.framework/Archive Framework"
printf 'plist' > "$staging_dir/Archive Framework.framework/Info.plist"
printf 'resource' > "$staging_dir/Archive Framework.framework/Resources/value.txt"

cd "$staging_dir"
"$zipper" c "$archive" \
  "Archive Framework.framework/Archive Framework" \
  "Archive Framework.framework/Info.plist" \
  "Archive Framework.framework/Resources/value.txt"
""",
    )

    product = products.collect(
        actions = ctx.actions,
        bundle_extension = ".framework",
        bundle_file = archive,
        bundle_name = "Archive Framework",
        linker_inputs = None,
        product_name = "Archive Framework",
        product_type = "f",
        target = {},
    )

    (_, _, metadata) = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "archive",
        name = ctx.label.name,
        output_group_info = None,
        preview_framework_files = [product.file],
        swift_info = None,
        transitive_infos = [],
    )
    output_group_fields = output_groups.to_output_groups_fields(
        target_output_groups = output_groups.collect(
            metadata = metadata,
            transitive_infos = [],
        ),
    )

    verified = ctx.actions.declare_file("archive_preview_framework.verified")
    verify_args = ctx.actions.args()
    verify_args.add(product.file.path)
    verify_args.add(verified)
    ctx.actions.run_shell(
        inputs = output_group_fields["bf archive"],
        outputs = [verified],
        arguments = [verify_args],
        command = """\
set -euo pipefail

readonly framework="$1"
readonly output="$2"

test -d "$framework"
test -f "$framework/Archive Framework"
test -f "$framework/Info.plist"
test -f "$framework/Resources/value.txt"
printf 'verified\n' > "$output"
""",
    )

    executable = ctx.actions.declare_file("archive_preview_framework_test.sh")
    ctx.actions.write(
        executable,
        content = """\
#!/bin/bash
set -euo pipefail
readonly marker="$TEST_SRCDIR/$TEST_WORKSPACE/{marker}"
[[ "$(cat "$marker")" == "verified" ]]
""".format(marker = verified.short_path),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [verified]),
    )]

archive_preview_framework_test = rule(
    attrs = {
        "_zipper": attr.label(
            default = "@bazel_tools//tools/zip:zipper",
            cfg = "exec",
            executable = True,
        ),
    },
    implementation = _archive_preview_framework_test_impl,
    test = True,
)

def output_files_test_suite(name):
    return unittest.suite(
        name,
        preview_framework_output_group_test,
        empty_preview_framework_output_group_test,
    )

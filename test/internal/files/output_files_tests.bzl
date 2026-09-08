"""Tests for Preview framework output files."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:products.bzl", "products")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal/files:input_files.bzl", "input_files")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/files:output_files.bzl",
    "output_files",
    "output_groups",
)

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal/files:resources.bzl", resources_module = "resources")

def _paths(files):
    return sorted([file.path for file in files.to_list()])

def _collect_output_groups(
        ctx,
        preview_framework_files,
        *,
        link_params = None,
        preview_link_input_files = [],
        preview_resource_bundle_files = [],
        preview_swift_import_files = depset()):
    (_, _, metadata) = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "target-id",
        link_params = link_params,
        name = ctx.label.name,
        output_group_info = None,
        preview_framework_files = preview_framework_files,
        preview_link_input_files = preview_link_input_files,
        preview_resource_bundle_files = preview_resource_bundle_files,
        preview_swift_import_files = preview_swift_import_files,
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
            "br target-id",
        ],
        sorted(output_group_fields.keys()),
        "exported output groups",
    )

    return unittest.end(env)

def _preview_infoplists_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    plists = [
        ctx.actions.declare_file("App/Info.plist"),
        ctx.actions.declare_file("Dependency/Info.plist"),
    ]
    for file in plists:
        ctx.actions.write(file, "plist\n")
    product_file = ctx.actions.declare_directory("App.app")
    ctx.actions.run_shell(
        outputs = [product_file],
        arguments = [product_file.path],
        command = "mkdir -p \"$1\"",
    )
    product = products.collect(
        actions = ctx.actions,
        bundle_file = product_file,
        bundle_path = product_file.path,
        linker_inputs = None,
        product_name = "App",
        product_type = "a",
        target = {},
    )
    (_, dependency_outputs, _) = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "dependency",
        infoplist = plists[1],
        name = ctx.label.name + "_dependency",
        output_group_info = None,
        swift_info = None,
        transitive_infos = [],
    )
    (_, _, metadata) = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "app",
        infoplist = plists[0],
        name = ctx.label.name,
        output_group_info = None,
        product = product,
        swift_info = None,
        transitive_infos = [struct(outputs = dependency_outputs)],
    )
    output_group_fields = output_groups.to_output_groups_fields(
        target_output_groups = output_groups.collect(
            metadata = metadata,
            transitive_infos = [],
        ),
    )

    asserts.equals(
        env,
        _paths(depset(plists)),
        _paths(output_group_fields["bf app"]),
        "Preview preparation includes direct and transitive adjusted Info.plists",
    )
    asserts.true(
        env,
        product_file.path in _paths(output_group_fields["bp app"]),
        "ordinary build still materializes the product",
    )
    asserts.false(
        env,
        product_file.path in _paths(output_group_fields["bf app"]),
        "Preview preparation does not materialize the selected target's product",
    )

    return unittest.end(env)

preview_framework_output_group_test = unittest.make(
    _preview_framework_output_group_test_impl,
)
empty_preview_framework_output_group_test = unittest.make(
    _empty_preview_framework_output_group_test_impl,
)
preview_infoplists_output_group_test = unittest.make(
    _preview_infoplists_output_group_test_impl,
)

def _preview_resource_bundle_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    bundles = [
        ctx.actions.declare_directory("First.bundle"),
        ctx.actions.declare_directory("Bundles With Spaces/Second.bundle"),
    ]
    ctx.actions.run_shell(
        outputs = bundles,
        arguments = [bundle.path for bundle in bundles],
        command = """\
mkdir -p "$1/en.lproj" "$2/Model.momd"
printf 'plist' > "$1/Info.plist"
printf 'localized' > "$1/en.lproj/Localizable.strings"
printf 'plist' > "$2/Info.plist"
printf 'model' > "$2/Model.momd/contents"
""",
    )
    output_group_fields = _collect_output_groups(
        ctx,
        [],
        preview_resource_bundle_files = bundles,
    )

    asserts.equals(
        env,
        _paths(depset(bundles)),
        _paths(output_group_fields["br target-id"]),
        "Preview resource bundle output group",
    )
    for bundle in bundles:
        asserts.true(
            env,
            bundle.path in _paths(output_group_fields["all_b"]),
            "all_b includes {}".format(bundle.path),
        )

    return unittest.end(env)

preview_resource_bundle_output_group_test = unittest.make(
    _preview_resource_bundle_output_group_test_impl,
)

def _provider_inputs(preview_resource_bundles):
    empty = depset()
    return struct(
        _preview_resource_bundles = preview_resource_bundles,
        _product_framework_files = empty,
        _resource_bundle_labels = empty,
        _resource_bundle_uncategorized_file_paths = empty,
        _resource_bundle_uncategorized_files = empty,
        _resource_bundle_uncategorized_generated_file_paths = empty,
        _uncategorized = empty,
        important_generated = empty,
        resource_bundles = empty,
        unsupported_extra_files = empty,
        xccurrentversions = empty,
    )

def _transitive_preview_resource_bundle_test_impl(ctx):
    env = unittest.begin(ctx)

    feature = ctx.actions.declare_directory("FeatureResources.bundle")
    palette = ctx.actions.declare_directory(
        "PaletteAssets.bundle",
    )
    ctx.actions.run_shell(
        arguments = [feature.path, palette.path],
        command = "mkdir -p \"$1\" \"$2\"",
        outputs = [feature, palette],
    )
    palette_bundle = struct(
        file = palette,
        id = "palette-resource-bundle-id",
        name = "PaletteAssets",
    )
    palette_info = struct(
        inputs = _provider_inputs(depset([palette_bundle])),
        xcode_target = None,
    )
    feature_bundle = struct(
        file = feature,
        id = "feature-resource-bundle-id",
        name = "FeatureResources",
    )
    feature_info = struct(
        inputs = _provider_inputs(depset(
            [feature_bundle],
            transitive = [palette_info.inputs._preview_resource_bundles],
        )),
        xcode_target = None,
    )

    merged_inputs = input_files.merge(transitive_infos = [feature_info])
    files = input_files.preview_resource_bundle_files(merged_inputs)

    asserts.equals(
        env,
        sorted([feature.path, palette.path]),
        sorted([file.path for file in files]),
        "direct and transitive Preview resource bundles are both retained",
    )

    (_, mixed_inputs) = input_files.collect_mixed_language(
        mergeable_info = struct(
            extra_file_paths = depset(),
            extra_files = depset(),
            non_arc_srcs = [],
            srcs = [],
        ),
        mixed_target_infos = [feature_info],
        transitive_infos = [],
    )
    mixed_files = input_files.preview_resource_bundle_files(mixed_inputs)
    asserts.equals(
        env,
        sorted([feature.path, palette.path]),
        sorted([file.path for file in mixed_files]),
        "mixed-language data input retains its transitive Preview bundles",
    )

    (_, unmerged_inputs) = input_files.collect_mixed_language(
        mergeable_info = None,
        mixed_target_infos = [],
        transitive_infos = [feature_info],
    )
    asserts.equals(env, files, input_files.preview_resource_bundle_files(unmerged_inputs))
    top_level_inputs = input_files.merge_top_level(
        avoid_deps = [],
        focused_labels = depset(),
        framework_files = depset(),
        platform = None,
        resource_info = None,
        transitive_infos = [feature_info],
    )
    asserts.equals(env, files, input_files.preview_resource_bundle_files(top_level_inputs))

    # A consuming target must select the original dependency materialization
    # instead of its differently namespaced duplicate of the same resource ID.
    duplicate = struct(file = feature, id = palette_bundle.id, name = palette_bundle.name)
    duplicated_inputs = _provider_inputs(depset(
        [duplicate],
        order = "postorder",
        transitive = [palette_info.inputs._preview_resource_bundles],
    ))
    asserts.equals(env, [palette], input_files.preview_resource_bundle_files(duplicated_inputs))

    return unittest.end(env)

transitive_preview_resource_bundle_test = unittest.make(
    _transitive_preview_resource_bundle_test_impl,
)

def _preview_link_inputs_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    link_params = ctx.actions.declare_file("preview.link.params")
    libraries = [
        ctx.actions.declare_file("libFirst.a"),
        ctx.actions.declare_file("nested/libSecond.a"),
    ]
    carrier = ctx.actions.declare_file("preview.autolink.a")
    for file in [link_params, carrier] + libraries:
        ctx.actions.write(file, "test\n")
    output_group_fields = _collect_output_groups(
        ctx,
        [],
        link_params = link_params,
        preview_link_input_files = tuple(libraries + [carrier]),
    )

    asserts.equals(
        env,
        sorted(
            [link_params.path, carrier.path] +
            [library.path for library in libraries],
        ),
        _paths(output_group_fields["bl target-id"]),
        "Preview params, static libraries, and autolink carrier are materialized together",
    )

    return unittest.end(env)

preview_link_inputs_output_group_test = unittest.make(
    _preview_link_inputs_output_group_test_impl,
)

def _mixed_language_preview_link_inputs_output_group_test_impl(ctx):
    env = unittest.begin(ctx)

    link_params = ctx.actions.declare_file("mixed.preview.link.params")
    library = ctx.actions.declare_file("libMixedDependency.a")
    carrier = ctx.actions.declare_file("mixed.preview.autolink.a")
    framework = ctx.actions.declare_directory("Mixed.framework")
    resource_bundle = ctx.actions.declare_directory("MixedResources.bundle")
    for file in [link_params, library, carrier]:
        ctx.actions.write(file, "test\n")
    ctx.actions.run_shell(
        outputs = [framework, resource_bundle],
        arguments = [framework.path, resource_bundle.path],
        command = """\
mkdir -p "$1" "$2/en.lproj"
printf 'plist' > "$2/Info.plist"
printf 'localized' > "$2/en.lproj/Localizable.strings"
""",
    )

    (_, _, metadata) = output_files.collect_mixed_language(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "mixed-target-id",
        indexstore_overrides = [],
        link_params = link_params,
        mixed_target_infos = [],
        name = ctx.label.name,
        output_group_info = None,
        preview_framework_files = [framework],
        preview_link_input_files = [library, carrier],
        preview_resource_bundle_files = [resource_bundle],
        swift_info = None,
        transitive_infos = [],
    )
    output_group_fields = output_groups.to_output_groups_fields(
        target_output_groups = output_groups.collect(
            metadata = metadata,
            transitive_infos = [],
        ),
    )

    asserts.equals(
        env,
        sorted([link_params.path, library.path, carrier.path]),
        _paths(output_group_fields["bl mixed-target-id"]),
        "mixed-language Preview params, archive, and autolink carrier are materialized",
    )
    asserts.equals(
        env,
        [framework.path],
        _paths(output_group_fields["bf mixed-target-id"]),
        "mixed-language Preview framework is materialized",
    )
    asserts.equals(
        env,
        [resource_bundle.path],
        _paths(output_group_fields["br mixed-target-id"]),
        "mixed-language Preview resource bundle is materialized",
    )

    return unittest.end(env)

mixed_language_preview_link_inputs_output_group_test = unittest.make(
    _mixed_language_preview_link_inputs_output_group_test_impl,
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

def _preview_swift_imports_test_impl(ctx):
    env = unittest.begin(ctx)
    files = [ctx.actions.declare_file(path) for path in ["Local.swiftmodule", "local/module.modulemap", "local/header.h"]]
    ctx.actions.run_shell(outputs = files, command = "exit 1")
    fields = _collect_output_groups(ctx, [], preview_swift_import_files = depset(files))
    asserts.equals(env, _paths(depset(files)), _paths(fields["bf target-id"]))
    asserts.equals(env, [], _paths(fields["bc target-id"]))
    return unittest.end(env)

preview_swift_imports_test = unittest.make(_preview_swift_imports_test_impl)

def _preview_resource_bundle_materialization_test_impl(ctx):
    info_plist = ctx.actions.declare_file("resource-inputs/Info.plist")
    localized = ctx.actions.declare_file(
        "resource-inputs/en.lproj/Localizable.strings",
    )
    model = ctx.actions.declare_file("resource-inputs/Model.momd/contents")
    compiled_assets = ctx.actions.declare_directory("resource-inputs/xcassets")
    ctx.actions.write(info_plist, "plist\n")
    ctx.actions.write(localized, "localized-content\n")
    ctx.actions.write(model, "compiled-model-content\n")
    ctx.actions.run_shell(
        command = "mkdir -p \"$1\" && printf 'compiled-assets\\n' > \"$1/Assets.car\"",
        arguments = [compiled_assets.path],
        outputs = [compiled_assets],
    )

    nested_info_plist = ctx.actions.declare_file(
        "nested-resource-inputs/Info.plist",
    )
    nested_content = ctx.actions.declare_file(
        "nested-resource-inputs/value.txt",
    )
    ctx.actions.write(nested_info_plist, "nested-plist\n")
    ctx.actions.write(nested_content, "nested-content\n")
    nested_bundle = resources_module.materialize_preview_bundle(
        actions = ctx.actions,
        bundle = struct(
            label = ctx.label,
            materialization_name = ctx.label.name,
            name = "NestedResources",
            preview_resources = {
                "Info.plist": nested_info_plist,
                "value.txt": nested_content,
            },
        ),
    )

    bundle = resources_module.materialize_preview_bundle(
        actions = ctx.actions,
        bundle = struct(
            label = ctx.label,
            materialization_name = ctx.label.name,
            name = "MaterializedResources",
            preview_resources = {
                ".rules_xcodeproj_directory_overlay/xcassets": compiled_assets,
                "Info.plist": info_plist,
                "Model.momd/contents": model,
                "en.lproj/Localizable.strings": localized,
            },
        ),
        dependencies = [struct(
            file = nested_bundle,
            relative_path = "NestedResources.bundle",
        )],
    )

    verified = ctx.actions.declare_file(
        "preview_resource_bundle_materialization.verified",
    )
    ctx.actions.run_shell(
        inputs = [bundle],
        outputs = [verified],
        arguments = [bundle.path, verified.path],
        command = """\
set -euo pipefail

readonly bundle="$1"
readonly output="$2"
test "$(cat "$bundle/Info.plist")" = plist
test "$(cat "$bundle/en.lproj/Localizable.strings")" = localized-content
test "$(cat "$bundle/Model.momd/contents")" = compiled-model-content
test "$(cat "$bundle/Assets.car")" = compiled-assets
test ! -e "$bundle/xcassets"
test "$(cat "$bundle/NestedResources.bundle/Info.plist")" = nested-plist
test "$(cat "$bundle/NestedResources.bundle/value.txt")" = nested-content
find -L "$bundle" -type f -print | LC_ALL=C sort > "$output"
test "$(wc -l < "$output" | tr -d ' ')" = 6
""",
    )

    executable = ctx.actions.declare_file(
        "preview_resource_bundle_materialization_test.sh",
    )
    ctx.actions.write(
        executable,
        content = """\
#!/bin/bash
set -euo pipefail
readonly marker="$TEST_SRCDIR/$TEST_WORKSPACE/{marker}"
[[ "$(wc -l < "$marker" | tr -d ' ')" == 6 ]]
""".format(marker = verified.short_path),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [verified]),
    )]

preview_resource_bundle_materialization_test = rule(
    implementation = _preview_resource_bundle_materialization_test_impl,
    test = True,
)

def output_files_test_suite(name):
    return unittest.suite(
        name,
        preview_framework_output_group_test,
        empty_preview_framework_output_group_test,
        preview_resource_bundle_output_group_test,
        transitive_preview_resource_bundle_test,
        preview_infoplists_output_group_test,
        preview_link_inputs_output_group_test,
        mixed_language_preview_link_inputs_output_group_test,
        preview_swift_imports_test,
    )

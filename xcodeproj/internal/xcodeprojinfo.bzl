"""The `XcodeProjInfo` provider."""

target_type = struct(
    compile = "compile",
)

XcodeProjInfo = provider(
    """\
Provides information needed to generate an Xcode project.

> [!WARNING]
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.
""",
    fields = {
        "args": """\
A `depset` of `struct`s with `id` and `arg` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target and `arg` values for the target
(if applicable).
""",
        "compilation_providers": """\
A value from `compilation_providers.{collect,merge}`.
""",
        "direct_dependencies": """\
A `depset` of target IDs (see `xcode_target.id`) that this target directly
depends on.
""",
        "envs": """\
A `depset` of `struct`s with `id` and `env` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target and `env` values for the target
(if applicable).
""",
        "extension_infoplists": """\
A `depset` of `struct`s with `id` and `infoplist` fields. The `id` field is the
target ID (see `xcode_target.id`) of the application extension target. The
`infoplist` field is a `File` for the Info.plist for the target.
""",
        "focused_labels": """\
A `depset` of label strings of focused targets. This will include the current
target (if focused) and any focused dependencies of the current target.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "focused_library_deps": """\
A `depset` of `struct`s with `id` and `label` fields. The `id` field is the
target ID (see `xcode_target.id`) of a focused library target. The `label`
field is the string label of the same target.

This field represents the transitive focused library dependencies of the target.
Top-level targets use this field to determine the value of
`top_level_focused_deps`. They also reset this value.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "framework_product_mappings": """\
A `depset` of `(linker_path, product_path)` `tuple`s.
`linker_path` is the `.framework/Executable` path used when linking to a
framework. `product_path` is the path to a built `.framework` product. In
particular, `product_path` can have a fully fleshed out framework, including
resources, while `linker_path` will most likely only have a symlink to a
`.dylib` in it.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "hosted_targets": """\
A `depset` of `struct`s with `host` and `hosted` fields. The `host` field is the
target ID (see `xcode_target.id`) of the hosting target. The `hosted` field is
the target ID of the hosted target.
""",
        "inputs": """\
A value from `input_files.collect`/`inputs_files.merge`, that contains
information related to all of the input `File`s for the project collected so
far. It also includes information related to "extra files" that should be added
to the Xcode project, but are not associated with any targets.
""",
        "label": """\
The `Label` of the target.

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "labels": """\
A `depset` of `Labels` for the target and its transitive dependencies.

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "lldb_context": "A value from `lldb_context.collect`.",
        "mergable_xcode_library_targets": """\
A `depset` of target IDs (see `xcode_target.id`). Each represents a target that
can potentially merge into a top-level target (to be decided by the top-level
target).

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "mergeable_infos": """\
A `depset` of `structs`s. Each contains information about a target that can
potentially merge into a top-level target (to be decided by the top-level
target).

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "merged_target_ids": """\
A `depset` of `tuple`s. The first element is the target ID (see
`xcode_target.id`) of the target being merged into. The second element is a list
of target IDs that have been merged into the target referenced by the first
element.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "non_top_level_rule_kind": """
If this target is not a top-level target, this is the value from
`ctx.rule.kind`, otherwise it is `None`. Top-level targets are targets that
are valid to be listed in the `top_level_targets` attribute of `xcodeproj`.
In particular, this means that they aren't library targets, which when
specified in `top_level_targets` cause duplicate mis-configured targets to be
added to the project.
""",
        "outputs": """\
A value from `output_files.collect`/`output_files.merge`, that contains
information about the output files for this target and its transitive
dependencies.
""",
        "platforms": """\
A `depset` of `apple_platform`s that this target and its transitive dependencies
are built for.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "potential_target_merges": """\
A `depset` of `struct`s with `src` and `dest` fields. The `src` field is the id
of the target that can be merged into the target with the id of the `dest`
field.

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "replacement_labels": """\
A `depset` of `struct`s with `id` and `label` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target that have its label (and name)
be replaced with the
label in the `label` field.

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "resource_bundle_ids": """\
A `depset` of `tuple`s mapping target ID (see `xcode_target.id`) to bundle id.
""",
        "swift_debug_settings": """\
A `depset` of swift_debug_settings `File`s, produced by
`pbxproj_partials.write_target_build_settings`.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "target_output_groups": """\
A value from `output_groups.collect`/`output_groups.merge`, that contains
information related to BwB mode output groups.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "target_type": """\
A string that categorizes the type of the current target. This will be one of
"compile", "resources", or `None`. Even if this target doesn't produce an Xcode
target, it can still have a non-`None` value for this field.
""",
        "top_level_focused_deps": """\
A `depset` of `struct`s with `id`, `label`, and `deps` fields. The `id` field is
the target ID (see `xcode_target.id`) of a top-level target. The `label` field
is the string label of the same target. The `deps` field is a `tuple` (used as a
frozen sequence) of values as stored in `focused_library_deps`.

This field is used to allow custom schemes (see the `xcschemes` module) to
include the correct versions of library targets.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "top_level_swift_debug_settings": """\
A `depset` of `tuple`s of an LLDB context key and swift_debug_settings `File`s,
produced by `pbxproj_partials.write_target_build_settings`. This will be an
empty `depset` for non-top-level targets.

This is only set and used when `xcodeproj.generation_mode = "incremental"` is
set.
""",
        "transitive_dependencies": """\
A `depset` of target IDs (see `xcode_target.id`) that this target transitively
depends on.
""",
        "xcode_required_targets": """\
A `depset` of values from `xcode_targets.make` for targets that need to be in
projects that have `build_mode = "xcode"`. This means that they can't be
unfocused in BwX mode, and if requested it will be ignored.

This is only set and used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "xcode_target": """\
A value from `xcode_targets.make` if this target can produce an Xcode
target.
""",
        "xcode_targets": """\
A `depset` of values from `xcode_targets.make`, which potentially will become
targets in the Xcode project.
""",
    },
)

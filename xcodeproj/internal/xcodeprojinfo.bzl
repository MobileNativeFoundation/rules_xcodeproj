"""The `XcodeProjInfo` provider."""

target_type = struct(
    compile = "compile",
)

XcodeProjInfo = provider(
    """\
Provides information needed to generate an Xcode project.

> **Warning**
>
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
A value returned from `compilation_providers.{collect,merge}`.
""",
        "dependencies": """\
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
        "hosted_targets": """\
A `depset` of `struct`s with `host` and `hosted` fields. The `host` field is the
target ID (see `xcode_target.id`) of the hosting target. The `hosted` field is
the target ID of the hosted target.
""",
        "inputs": """\
A value returned from `input_files.collect`/`inputs_files.merge`, that contains
information related to all of the input `File`s for the project collected so
far. It also includes information related to "extra files" that should be added
to the Xcode project, but are not associated with any targets.
""",
        "label": "The `Label` of the target.",
        "labels": """\
A `depset` of `Labels` for the target and its transitive dependencies.
""",
        "lldb_context": "A value returned from `lldb_context.collect`.",
        "mergable_xcode_library_targets": """\
A `depset` of target IDs (see `xcode_target.id`). Each represents a target that
can potentially merge into a top-level target (to be decided by the top-level
target).
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
A value returned from `output_files.collect`/`output_files.merge`, that contains
information about the output files for this target and its transitive
dependencies.
""",
        "potential_target_merges": """\
A `depset` of `struct`s with `src` and `dest` fields. The `src` field is the id
of the target that can be merged into the target with the id of the `dest`
field.
""",
        "replacement_labels": """\
A `depset` of `struct`s with `id` and `label` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target that have its label (and name)
be replaced with the
label in the `label` field.
""",
        "resource_bundle_ids": """\
A `depset` of `tuple`s mapping target ID (see `xcode_target.id`) to bundle id.
""",
        "target_type": """\
A string that categorizes the type of the current target. This will be one of
"compile", "resources", or `None`. Even if this target doesn't produce an Xcode
target, it can still have a non-`None` value for this field.
""",
        "transitive_dependencies": """\
A `depset` of target IDs (see `xcode_target.id`) that this target transitively
depends on.
""",
        "xcode_required_targets": """\
A `depset` of values returned from `xcode_targets.make` for targets that need to
be in projects that have `build_mode = "xcode"`. This means that they can't be
unfocused in BwX mode, and if requested it will be ignored.
""",
        "xcode_target": """\
A value returned from `xcode_targets.make` if this target can produce an Xcode
target.
""",
        "xcode_targets": """\
A `depset` of values returned from `xcode_targets.make`, which potentially will
become targets in the Xcode project.
""",
    },
)

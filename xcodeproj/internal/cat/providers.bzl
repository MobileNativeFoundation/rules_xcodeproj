"""Providers that are used throughout the rules."""

XcodeProjAutomaticTargetProcessingInfo = provider(
    """\
Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return an `XcodeProjInfo` provider instance instead.

**Warning:** This provider currently has an unstable API and may change in the
future. If you are using this provider, please let us know so we can prioritize
stabilizing it.
""",
    fields = {
        "alternate_icons": """\
An attribute name (or `None`) to collect the application alternate icons.
""",
        "app_icons": """\
An attribute name (or `None`) to collect the application icons.
""",
        "args": """\
A `List` (or `None`) representing the command line arguments that this target
should execute or test with.
""",
        "bundle_id": """\
An attribute name (or `None`) to collect the bundle id string from.
""",
        "codesignopts": """\
An attribute name (or `None`) to collect the `codesignopts` `list` from.
""",
        "collect_uncategorized_files": """\
Whether to collect files from uncategorized attributes.
""",
        "deps": """\
A sequence of attribute names to collect `Target`s from for `deps`-like
attributes.
""",
        "entitlements": """\
An attribute name (or `None`) to collect `File`s from for the
`entitlements`-like attribute.
""",
        "env": """\
A `dict` representing the environment variables that this target should execute
or test with.
""",
        "exported_symbols_lists": """\
A sequence of attribute names to collect `File`s from for the
`exported_symbols_lists`-like attributes.
""",
        "hdrs": """\
A sequence of attribute names to collect `File`s from for `hdrs`-like
attributes.
""",
        "implementation_deps": """\
A sequence of attribute names to collect `Target`s from for
`implementation_deps`-like attributes.
""",
        "infoplists": """\
A sequence of attribute names to collect `File`s from for the `infoplists`-like
attributes.
""",
        "is_supported": """\
Whether an Xcode target can be generated for this target. Even if this value is
`False`, setting values for the other attributes can cause inputs to be
collected and shown in the Xcode project.
""",
        "is_top_level": """\
FIXME
""",
        "label": "The `Label` to use for the target.",
        "launchdplists": """\
A sequence of attribute names to collect `File`s from for the
`launchdplists`-like attributes.
""",
        "link_mnemonics": """\
A sequence of mnemonic (action) names to gather link parameters. The first
action that matches any of the mnemonics is used.
""",
        "non_arc_srcs": """\
A sequence of attribute names to collect `File`s from for `non_arc_srcs`-like
attributes.
""",
        "pch": """\
An attribute name (or `None`) to collect `File`s from for the `pch`-like
attribute.
""",
        "provisioning_profile": """\
An attribute name (or `None`) to collect `File`s from for the
`provisioning_profile`-like attribute.
""",
        "srcs": """\
A sequence of attribute names to collect `File`s from for `srcs`-like
attributes.
""",
        "target_type": "See `XcodeProjInfo.target_type`.",
        "xcode_targets": """\
A `dict` mapping attribute names to target type strings (i.e. "resource" or
"compile"). Only Xcode targets from the specified attributes with the specified
target type are allowed to propagate.
""",
    },
)

target_type = struct(
    compile = "compile",
)

XcodeProjInfo = provider(
    """\
Provides information needed to generate an Xcode project.

**Warning:** This provider currently has an unstable API and may change in the
future. If you are using this provider, please let us know so we can prioritize
stabilizing it.
""",
    fields = {
        "args": """\
A `depset` of `struct`s with `id` and `arg` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target and `arg` values for the target
(if applicable).
""",
        "bwb_output_groups": """\
A value returned from `bwb_output_groups.collect`/`bwb_output_groups.merge`,
that contains information related to BwB mode output groups.
""",
        "bwx_output_groups": """\
A value returned from `bwx_output_groups.collect`/`bwx_output_groups.merge`,
that contains information related to BwX mode output groups.
""",
        "compilation_providers": """\
A value returned from `compilation_providers.{collect,merge}`.
""",
        "dependencies": """\
A `depset` of target IDs (see `xcode_target.id`) that this target directly
depends on.
""",
        "env": """\
A `depset` of `struct`s with `id` and `env` fields. The `id` field is the
target ID (see `xcode_target.id`) of the target and `env` values for the target
(if applicable).
""",
        "extension_infoplists": """\
A `depset` of `struct`s with 'id' and 'infoplist' fields. The 'id' field is the
target ID (see `xcode_target.id`) of the application extension target. The
'infoplist' field is a `File` for the Info.plist for the target.
""",
        "framework_product_mappings": """\
A `depset` of `(linker_path, product_path)` `tuple`s.
`linker_path` is the `.framework/Executable` path used when linking to a
framework. `product_path` is the path to a built `.framework` product. In
particular, `product_path` can have a fully fleshed out framework, including
resources, while `linker_path` will most likely only have a symlink to a
`.dylib` in it.
""",
        "focused_deps": "FIXME",
        "hosted_targets": """\
A `depset` of `struct`s with 'host' and 'hosted' fields. The `host` field is the
target ID (see `xcode_target.id`) of the hosting target. The `hosted` field is
the target ID of the hosted target.
""",
        "inputs": """\
A value returned from `input_files.collect`/`inputs_files.merge`, that contains
information related to all of the input `File`s for the project collected so
far. It also includes information related to "extra files" that should be added
to the Xcode project, but are not associated with any targets.
""",
        "mergeable_infos": """\
A `depset` of `structs`s. Each contains information about a target that can
potentially merge into a top-level target (to be decided by the top-level
target).
""",
        "merged_target_ids": """\
A `depset` of `xcode_target.id`s of targets that have been merged into another
target.
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
        "platforms": """\
A `depset` of `apple_platform`s that this target and its transitive dependencies
are built for.
""",
        "resource_bundle_ids": """\
A `depset` of `tuple`s mapping target id to bundle id.
""",
        "swift_debug_settings": """\
For top-level targets, this is a `depset` of swift_debug_settings `File`s,
produced by `pbxproj_partials.write_target_build_settings`.
""",
        "target_type": """\
A string that categorizes the type of the current target. This will be one of
"compile", "resources", or `None`. Even if this target doesn't produce an Xcode
target, it can still have a non-`None` value for this field.
""",
        "top_level_focused_deps": "FIXME",
        "top_level_swift_debug_settings": """\
A `depset` of `tuple`s of an LLDB context key and swift_debug_settings `File`s,
produced by `pbxproj_partials.write_target_build_settings`. This will be an
empty `depset` for non-top-level targets.
""",
        "transitive_dependencies": """\
A `depset` of target IDs (see `xcode_target.id`) that this target transitively
depends on.
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

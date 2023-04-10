"""Providers that are used throughout the rules."""

XcodeProjAutomaticTargetProcessingInfo = provider(
    """\
Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return a `XcodeProjInfo` provider instance instead.

**Warning:** This provider currently has an unstable API and may change in the
future. If you are using this provider, please let us know so we can prioritize
stabilizing it.
""",
    fields = {
        "all_attrs": "",
        "alternate_icons": """\
An attribute name (or `None`) to collect the application alternate icons.
""",
        "app_icons": """\
An attribute name (or `None`) to collect the application icons.
""",
        "args": """\
A `List` (or `None`) representing the command line arguments that this target should execute or
test with.
""",
        "bazel_build_mode_error": """\
If `build_mode = "bazel"`, then if this is non-`None`, it will be raised as an
error during analysis.
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
A `dict` representing the environment variables that this target should execute or
test with.
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
        "launchdplists": """\
A sequence of attribute names to collect `File`s from for the `launchdplists`-like
attributes.
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
        "should_generate_target": """\
Whether or an Xcode target should be generated for this target. Even if this
value is `False`, setting values for the other attributes can cause inputs to be
collected and shown in the Xcode project.
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
target id of the target and `arg` values
for the target (if applicable).
""",
        "compilation_providers": """\
A value returned from `compilation_providers.collect_for_{non_,}top_level`.
""",
        "dependencies": """\
A `depset` of target ids (see the `target` `struct`) that this target directly
depends on.
""",
        "envs": """\
A `depset` of `struct`s with `id` and `env` fields. The `id` field is the
target id of the target and `env` values
for the target (if applicable).
""",
        "extension_infoplists": """\
A `depset` of `struct`s with 'id' and 'infoplist' fields. The 'id' field is the
target id of the application extension target. The 'infoplist' field is a `File`
for the Info.plist for the target.
""",
        "hosted_targets": """\
A `depset` of `struct`s with 'host' and 'hosted' fields. The 'host' field is the
target id of the hosting target. The 'hosted' field is the target id of the
hosted target.
""",
        "inputs": """\
A value returned from `input_files.collect`, that contains the input files for
this target. It also includes the two extra fields that collect all of the
generated `Files` and all of the `Files` that should be added to the Xcode
project, but are not associated with any targets.
""",
        "is_top_level_target": """\
Whether this target is a top-level target. Top-level targets are targets that
are valid to be listed in the `top_level_targets` attribute of `xcodeproj`.
In particular, this means that they aren't library targets, which when
specified in `top_level_targets` cause duplicate mis-configured targets to be
added to the project.
""",
        "label": "The `Label` of the target.",
        "labels": """\
A `depset` of `Labels` for the target and its transitive dependencies.
""",
        "lldb_context": "A value returned from `lldb_context.collect`.",
        "mergable_xcode_library_targets": """\
A `List` of `struct`s with 'id' and 'product_path' fields. The 'id' field
is the id of the target. The 'product_path' is the path to the target's
product.
""",
        "potential_target_merges": """\
A `depset` of `struct`s with 'src' and 'dest' fields. The 'src' field is the id
of the target that can be merged into the target with the id of the 'dest'
field.
""",
        "outputs": """\
A value returned from `output_files.collect`, that contains information about
the output files for this target and its transitive dependencies.
""",
        "replacement_labels": """\
A `depset` of `struct`s with `id` and `label` fields. The `id` field is the
target id of the target that have its label (and name) be replaced with the
label in the `label` field.
""",
        "resource_bundle_informations": """\
A `depset` of `struct`s with information used to generate resource bundles,
which couldn't be collected from `AppleResourceInfo` alone.
""",
        "rule_kind": "The ctx.rule.kind of the target.",
        "search_paths": """\
A value returned from `_process_search_paths`, that contains the search paths
needed by this target. These search paths should be added to the search paths of
any target that depends on this target.
""",
        "target_type": """\
A string that categorizes the type of the current target. This will be one of
"compile", "resources", or `None`. Even if this target doesn't produce an Xcode
target, it can still have a non-`None` value for this field.
""",
        "transitive_dependencies": """\
A `depset` of target ids (see the `target` `struct`) that this target
transitively depends on.
""",
        "xcode_required_targets": """\
A `depset` of values returned from `xcode_targets.make` for targets that need to
be in projects that have `build_mode = "xcode"`. This means that they can't be
unfocused in BwX mode, and if requested it will be ignored.
""",
        "xcode_target": """\
An optional value returned from `xcode_targets.make`.
""",
        "xcode_targets": """\
A `depset` of values returned from `xcode_targets.make`, which potentially will
become targets in the Xcode project.
""",
    },
)

XcodeProjOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj` rule.",
    fields = {
        "installer": "The xcodeproj installer.",
        "project_name": "The installed project name.",
    },
)

XcodeProjRunnerOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj_runner` rule.",
    fields = {
        "project_name": "The installed project name.",
        "runner": "The xcodeproj runner.",
    },
)

XcodeProjProvisioningProfileInfo = provider(
    "Provides information about a provisioning profile.",
    fields = {
        "profile_name": """\
The profile name (e.g. "iOS Team Provisioning Profile: com.example.app").
""",
        "team_id": """\
The Team ID the profile is associated with (e.g. "V82V4GQZXM").
""",
        "is_xcode_managed": "Whether the profile is managed by Xcode.",
    },
)

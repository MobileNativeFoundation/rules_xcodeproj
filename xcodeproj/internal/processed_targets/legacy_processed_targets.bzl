"""Module for creating the data structure representing a processed target."""

def _make_legacy_processed_target(
        *,
        compilation_providers,
        direct_dependencies,
        extension_infoplists = None,
        hosted_targets = None,
        inputs,
        is_top_level = False,
        is_xcode_required = False,
        library = None,
        lldb_context,
        outputs,
        potential_target_merges = None,
        resource_bundle_ids = None,
        transitive_dependencies,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        compilation_providers: A value from `compilation_providers.collect`.
        direct_dependencies: A `depset` of `id`s of targets that this target
            directly depends on.
        extension_infoplists: A `list` of `File` for the Info.plist's of an
            application extension target, or `None`.
        hosted_targets: An optional `list` of `struct`s as used in
            `XcodeProjInfo.hosted_targets`.
        inputs: A value from `input_files.collect` that will
            provide values for the `XcodeProjInfo.inputs` field.
        is_top_level: If `True`, the target can be listed in
            `top_level_targets`. This is not the same as
            `automatic_target_info.is_top_level`, which includes more targets,
            such as application extensions.
        is_xcode_required: If `True`, the target is required in BwX mode.
        library: A `File` for the static library produced by this target, or
            `None`.
        lldb_context: A value from `lldb_context.collect`.
        outputs: A value from `output_files.collect` that will
            provide values for the `XcodeProjInfo.outputs` field.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        resource_bundle_ids: An optional `list` of `tuples`s that will be in the
            `XcodeProjInfo.resource_bundle_ids` `depset`.
        transitive_dependencies: A `depset` of target ids of transitive
            dependencies of this target.
        xcode_target: An optional value from `xcode_targets.make` that will be
            in the `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        compilation_providers = compilation_providers,
        extension_infoplists = extension_infoplists,
        direct_dependencies = direct_dependencies,
        hosted_targets = hosted_targets,
        inputs = inputs,
        is_top_level = is_top_level,
        is_xcode_required = is_xcode_required,
        library = library,
        lldb_context = lldb_context,
        outputs = outputs,
        potential_target_merges = potential_target_merges,
        resource_bundle_ids = resource_bundle_ids,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
        xcode_targets = [xcode_target] if xcode_target else None,
    )

legacy_processed_targets = struct(
    make = _make_legacy_processed_target,
)

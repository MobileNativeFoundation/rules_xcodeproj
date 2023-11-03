"""Functions for creating data structures related to processed bazel targets."""

load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_DEPSET")
load(":providers.bzl", "target_type")

def processed_target(
        *,
        bwb_output_groups,
        bwx_output_groups,
        compilation_providers,
        dependencies,
        extension_infoplists = None,
        framework_product_mappings = None,
        hosted_targets = None,
        inputs,
        is_top_level = False,
        lldb_context_key = None,
        mergeable_infos = None,
        merged_target_ids = None,
        outputs,
        platform = None,
        resource_bundle_ids = None,
        swift_debug_settings,
        top_level_focused_deps = None,
        top_level_swift_debug_settings = EMPTY_DEPSET,
        transitive_dependencies,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        bwb_output_groups: A value as returned from `bwb_output_groups.collect`.
        bwx_output_groups: A value as returned from `bwx_output_groups.collect`.
        compilation_providers: A value as returned from
            `compilation_providers.{collect,merge}`.
        dependencies: A `depset` of target ids of direct dependencies of this
            target.
        extension_infoplists: A `list` of `File`s for the Info.plist's of
            application extension targets, or `None`.
        framework_product_mappings: A `list` of `tuple`s for the
            `XcodeProjInfo.framework_product_mappings` field.
        hosted_targets: An optional `list` of `struct`s as used in
            `XcodeProjInfo.hosted_targets`.
        inputs: A value as returned from `input_files.{collect,merge}` that will
            provide values for the `XcodeProjInfo.inputs` field.
        is_top_level: If `True`, the target can be listed in
            `top_level_targets`. This is not the same as
            `automatic_target_info.is_top_level`, which includes more targets,
            such as application extensions.
        mergeable_infos:
        merged_target_ids: A `list` of `xcode_target.id`s that were merged into
            this target.
        outputs: A value as returned from `output_files.{collect,merge}` that
            will provide values for the `XcodeProjInfo.outputs` field.
        platform: An `apple_platform`, or `None`, that will be included in the
            `XcodeProjInfo.platforms` field.
        resource_bundle_ids: An optional `list` of `tuples`s that will be in the
            `XcodeProjInfo.resource_bundle_ids` `depset`.
        swift_debug_settings: A `depset` of `Files` to be set on the
            `XcodeProjInfo.swift_debug_settings` field.
        transitive_dependencies: A `depset` of target ids of transitive
            dependencies of this target.
        top_level_focused_deps: A `list` of `structs` that will be included in
            `XcodeProjInfo.top_level_focused_deps`.
        top_level_swift_debug_settings: A `depset` of `tuple`s to be set on the
            `XcodeProjInfo.top_level_swift_debug_settings` field.
        xcode_target: An optional value returned from `xcode_targets.make` that
            will be in the `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        bwb_output_groups = bwb_output_groups,
        bwx_output_groups = bwx_output_groups,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = extension_infoplists,
        framework_product_mappings = framework_product_mappings,
        hosted_targets = hosted_targets,
        inputs = inputs,
        is_top_level = is_top_level,
        lldb_context_key = lldb_context_key,
        mergeable_infos = mergeable_infos,
        merged_target_ids = merged_target_ids,
        outputs = outputs,
        platform = platform,
        resource_bundle_ids = resource_bundle_ids,
        swift_debug_settings = swift_debug_settings,
        target_type = target_type,
        top_level_focused_deps = top_level_focused_deps,
        top_level_swift_debug_settings = top_level_swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
        xcode_targets = [xcode_target] if xcode_target else None,
    )

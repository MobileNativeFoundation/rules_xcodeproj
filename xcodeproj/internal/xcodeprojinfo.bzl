"""Functions for creating `XcodeProjInfo` providers."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
)
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":input_files.bzl", "input_files")
load(":library_targets.bzl", "process_library_target")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":non_xcode_targets.bzl", "process_non_xcode_target")
load(":output_files.bzl", "output_files")
load(
    ":providers.bzl",
    "XcodeProjAutomaticTargetProcessingInfo",
    "XcodeProjInfo",
    "target_type",
)
load(":processed_target.bzl", "processed_target")
load(":target_search_paths.bzl", "target_search_paths")
load(":targets.bzl", "targets")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "should_bundle_resources",
)
load(":top_level_targets.bzl", "process_top_level_target")

# Creating `XcodeProjInfo`

def _should_skip_target(*, ctx, target):
    """Determines if the given target should be skipped for target generation.

    There are some rules, like the test runners for iOS tests, that we want to
    ignore. Nothing from those rules are considered.

    Args:
        ctx: The aspect context.
        target: The `Target` to check.

    Returns:
        `True` if `target` should be skipped for target generation.
    """

    # TODO: Find a way to detect TestEnvironment instead
    return targets.is_test_bundle(
        target = target,
        deps = getattr(ctx.rule.attr, "deps", None),
    )

def _target_info_fields(
        *,
        compilation_providers,
        dependencies,
        extension_infoplists,
        hosted_targets,
        inputs,
        lldb_context,
        non_mergable_targets,
        outputs,
        potential_target_merges,
        resource_bundle_informations,
        search_paths,
        target_type,
        transitive_dependencies,
        xcode_target,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        compilation_providers: Maps to the `XcodeProjInfo.compilation_providers`
            field.
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        extension_infoplists: Maps to the `XcodeProjInfo.extension_infoplists`
            field.
        hosted_targets: Maps to the `XcodeProjInfo.hosted_targets` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        lldb_context: Maps to the `XcodeProjInfo.lldb_context` field.
        non_mergable_targets: Maps to the `XcodeProjInfo.non_mergable_targets`
            field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        resource_bundle_informations: Maps to the
            `XcodeProjInfo.resource_bundle_informations` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        transitive_dependencies: Maps to the
            `XcodeProjInfo.transitive_dependencies` field.
        xcode_target: Maps to the `XcodeProjInfo.xcode_target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `compilation_providers`
        *   `dependencies`
        *   `extension_infoplists`
        *   `generated_inputs`
        *   `hosted_targets`
        *   `inputs`
        *   `lldb_context`
        *   `non_mergable_targets`
        *   `outputs`
        *   `potential_target_merges`
        *   `resource_bundle_informations`
        *   `search_paths`
        *   `target_type`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
    """
    return {
        "compilation_providers": compilation_providers,
        "dependencies": dependencies,
        "extension_infoplists": extension_infoplists,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "lldb_context": lldb_context,
        "non_mergable_targets": non_mergable_targets,
        "outputs": outputs,
        "potential_target_merges": potential_target_merges,
        "resource_bundle_informations": resource_bundle_informations,
        "search_paths": search_paths,
        "target_type": target_type,
        "transitive_dependencies": transitive_dependencies,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
    }

def _skip_target(*, deps, transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        deps: `ctx.attr.deps` for the target.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of the target.

    Returns:
        The return value of `_target_info_fields`, with values merged from
        `transitive_infos`.
    """
    compilation_providers = comp_providers.merge(
        transitive_compilation_providers = [
            (
                dep[XcodeProjInfo].xcode_target,
                dep[XcodeProjInfo].compilation_providers,
            )
            for dep in deps
        ],
    )
    search_paths = target_search_paths.make(
        compilation_providers = None,
        bin_dir_path = None,
    )

    dependencies, transitive_dependencies = process_dependencies(
        automatic_target_info = None,
        transitive_infos = transitive_infos,
    )

    return _target_info_fields(
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = depset(
            transitive = [
                info.extension_infoplists
                for _, info in transitive_infos
            ],
        ),
        hosted_targets = depset(
            transitive = [
                info.hosted_targets
                for _, info in transitive_infos
            ],
        ),
        inputs = input_files.merge(
            transitive_infos = transitive_infos,
        ),
        lldb_context = lldb_contexts.collect(
            id = None,
            is_swift = False,
            search_paths = search_paths,
            transitive_infos = [
                info
                for _, info in transitive_infos
            ],
        ),
        non_mergable_targets = depset(
            transitive = [
                info.non_mergable_targets
                for _, info in transitive_infos
            ],
        ),
        outputs = output_files.merge(
            automatic_target_info = None,
            transitive_infos = transitive_infos,
        ),
        potential_target_merges = depset(
            transitive = [
                info.potential_target_merges
                for _, info in transitive_infos
            ],
        ),
        resource_bundle_informations = depset(
            transitive = [
                info.resource_bundle_informations
                for _, info in transitive_infos
            ],
        ),
        search_paths = search_paths,
        target_type = target_type.compile,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
        xcode_targets = depset(
            transitive = [info.xcode_targets for _, info in transitive_infos],
        ),
    )

def _create_xcodeprojinfo(*, ctx, target, transitive_infos):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
    automatic_target_info = target[XcodeProjAutomaticTargetProcessingInfo]

    if (
        automatic_target_info.bazel_build_mode_error and
        should_bundle_resources(ctx = ctx)
    ):
        fail(automatic_target_info.bazel_build_mode_error)

    if not automatic_target_info.should_generate_target:
        processed_target = process_non_xcode_target(
            ctx = ctx,
            target = target,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )
    elif AppleBundleInfo in target:
        processed_target = process_top_level_target(
            ctx = ctx,
            target = target,
            automatic_target_info = automatic_target_info,
            bundle_info = target[AppleBundleInfo],
            transitive_infos = transitive_infos,
        )
    elif target[DefaultInfo].files_to_run.executable:
        processed_target = process_top_level_target(
            ctx = ctx,
            target = target,
            automatic_target_info = automatic_target_info,
            bundle_info = None,
            transitive_infos = transitive_infos,
        )
    else:
        processed_target = process_library_target(
            ctx = ctx,
            target = target,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )

    return _target_info_fields(
        compilation_providers = processed_target.compilation_providers,
        dependencies = processed_target.dependencies,
        extension_infoplists = depset(
            processed_target.extension_infoplists,
            transitive = [
                info.extension_infoplists
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        hosted_targets = depset(
            processed_target.hosted_targets,
            transitive = [
                info.hosted_targets
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        inputs = processed_target.inputs,
        lldb_context = processed_target.lldb_context,
        non_mergable_targets = depset(
            processed_target.non_mergable_targets,
            transitive = [
                info.non_mergable_targets
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        outputs = processed_target.outputs,
        potential_target_merges = depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        resource_bundle_informations = depset(
            processed_target.resource_bundle_informations,
            transitive = [
                info.resource_bundle_informations
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        search_paths = processed_target.search_paths,
        target_type = processed_target.automatic_target_info.target_type,
        transitive_dependencies = processed_target.transitive_dependencies,
        xcode_target = processed_target.xcode_target,
        xcode_targets = depset(
            processed_target.xcode_targets,
            transitive = [
                info.xcode_targets
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
    )

# API

def create_xcodeprojinfo(*, ctx, target, transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        An `XcodeProjInfo` populated with information from `target` and
        `transitive_infos`.
    """
    if _should_skip_target(ctx = ctx, target = target):
        info_fields = _skip_target(
            deps = getattr(ctx.rule.attr, "deps", []),
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _create_xcodeprojinfo(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )

    return XcodeProjInfo(
        **info_fields
    )

def merge_xcodeprojinfos(infos):
    """Creates a merged `XcodeProjInfo` for the given `XcodeProjInfo`s.

    Args:
        infos: A `list` of `XcodeProjInfo`s to merge.

    Returns:
        An `XcodeProjInfo` populated with information from `infos`.
    """
    info_fields = _skip_target(
        deps = [],
        transitive_infos = [(None, info) for info in infos],
    )
    return XcodeProjInfo(
        **info_fields
    )

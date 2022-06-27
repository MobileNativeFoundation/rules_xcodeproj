"""Functions for creating `XcodeProjInfo` providers."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":input_files.bzl", "input_files")
load(":library_targets.bzl", "process_library_target")
load(":linker_input_files.bzl", "linker_input_files")
load(":non_xcode_targets.bzl", "process_non_xcode_target")
load(":opts.bzl", "create_opts_search_paths")
load(":output_files.bzl", "output_files")
load(
    ":providers.bzl",
    "XcodeProjAutomaticTargetProcessingInfo",
    "XcodeProjInfo",
    "target_type",
)
load(":processed_target.bzl", "processed_target")
load(":search_paths.bzl", "process_search_paths")
load(":targets.bzl", "targets")
load(":target_properties.bzl", "process_dependencies")
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
        dependencies,
        inputs,
        linker_inputs,
        non_mergable_targets,
        non_target_linker_inputs,
        non_target_swift_info_modules,
        outputs,
        potential_target_merges,
        resource_bundle_informations,
        search_paths,
        target,
        target_libraries,
        target_type,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        linker_inputs: Maps to the `XcodeProjInfo.linker_inputs` field.
        non_mergable_targets: Maps to the `XcodeProjInfo.non_mergable_targets`
            field.
        non_target_linker_inputs: Maps to the
            `XcodeProjInfo.non_target_linker_inputs` field.
        non_target_swift_info_modules: Maps to the
            `XcodeProjInfo.non_target_swift_info_modules` field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        resource_bundle_informations: Maps to the
            `XcodeProjInfo.resource_bundle_informations` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        target: Maps to the `XcodeProjInfo.target` field.
        target_libraries: Maps to the `XcodeProjInfo.target_libraries` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `dependencies`
        *   `generated_inputs`
        *   `inputs`
        *   `linker_inputs`
        *   `non_mergable_targets`
        *   `non_target_linker_inputs`
        *   `non_target_swift_info_modules`
        *   `outputs`
        *   `potential_target_merges`
        *   `resource_bundle_informations`
        *   `search_paths`
        *   `target`
        *   `target_libraries`
        *   `target_type`
        *   `xcode_targets`
    """
    return {
        "dependencies": dependencies,
        "inputs": inputs,
        "linker_inputs": linker_inputs,
        "non_mergable_targets": non_mergable_targets,
        "non_target_linker_inputs": non_target_linker_inputs,
        "non_target_swift_info_modules": non_target_swift_info_modules,
        "outputs": outputs,
        "potential_target_merges": potential_target_merges,
        "resource_bundle_informations": resource_bundle_informations,
        "search_paths": search_paths,
        "target": target,
        "target_libraries": target_libraries,
        "target_type": target_type,
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
    return _target_info_fields(
        dependencies = process_dependencies(
            automatic_target_info = None,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.merge(
            transitive_infos = transitive_infos,
        ),
        non_mergable_targets = depset(
            transitive = [
                info.non_mergable_targets
                for _, info in transitive_infos
            ],
        ),
        non_target_linker_inputs = linker_input_files.merge(
            transitive_linker_inputs = [
                (info.target, info.non_target_linker_inputs)
                for _, info in transitive_infos
            ],
        ),
        non_target_swift_info_modules = depset(
            transitive = [
                info.non_target_swift_info_modules
                for _, info in transitive_infos
            ],
        ),
        outputs = output_files.merge(
            automatic_target_info = None,
            transitive_infos = transitive_infos,
        ),
        linker_inputs = linker_input_files.merge(
            transitive_linker_inputs = [
                (dep[XcodeProjInfo].target, dep[XcodeProjInfo].linker_inputs)
                for dep in deps
            ],
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
        search_paths = process_search_paths(
            cc_info = None,
            objc = None,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
                system_includes = [],
            ),
        ),
        target = None,
        target_libraries = depset(
            transitive = [
                info.target_libraries
                for _, info in transitive_infos
            ],
        ),
        target_type = target_type.compile,
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

    target_library = None
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
        target_library = linker_input_files.get_primary_static_library(
            processed_target.linker_inputs,
        )

    linker_inputs = processed_target.linker_inputs

    if processed_target.target:
        non_target_linker_inputs = linker_input_files.merge(
            transitive_linker_inputs = [
                (info.target, info.non_target_linker_inputs)
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        )
        non_target_swift_info_modules = depset(
            transitive = [
                info.non_target_swift_info_modules
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        )
    else:
        non_target_linker_inputs = linker_inputs
        swift_info = target[SwiftInfo] if SwiftInfo in target else None
        if swift_info:
            non_target_swift_info_modules = swift_info.transitive_modules
        else:
            non_target_swift_info_modules = depset()

    return _target_info_fields(
        dependencies = processed_target.dependencies,
        inputs = processed_target.inputs,
        linker_inputs = linker_inputs,
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
        non_target_linker_inputs = non_target_linker_inputs,
        non_target_swift_info_modules = non_target_swift_info_modules,
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
        target = processed_target.target,
        target_libraries = depset(
            [target_library] if target_library else None,
            transitive = [
                info.target_libraries
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.automatic_target_info.xcode_targets.get(
                        attr,
                        [None],
                    ))
            ],
        ),
        target_type = processed_target.automatic_target_info.target_type,
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

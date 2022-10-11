"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
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
    if AppleBinaryInfo in target and "deps" not in dir(ctx.rule.attr):
        return True

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
        is_top_level_target,
        lldb_context,
        outputs,
        potential_target_merges,
        replacement_labels,
        resource_bundle_informations,
        rule_kind,
        search_paths,
        target_type,
        test_envs,
        transitive_dependencies,
        xcode_target,
        xcode_targets,
        xcode_required_targets):
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
        is_top_level_target: Maps to the `XcodeProjInfo.is_top_level_target`
            field.
        lldb_context: Maps to the `XcodeProjInfo.lldb_context` field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        replacement_labels: Maps to the `XcodeProjInfo.replacement_labels`
            field.
        resource_bundle_informations: Maps to the
            `XcodeProjInfo.resource_bundle_informations` field.
        rule_kind: Maps to the `XcodeProjInfo.rule_kind` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        test_envs: Maps to the `XcodeProjInfo.test_envs` field.
        transitive_dependencies: Maps to the
            `XcodeProjInfo.transitive_dependencies` field.
        xcode_target: Maps to the `XcodeProjInfo.xcode_target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.
        xcode_required_targets: Maps to the
            `XcodeProjInfo.xcode_required_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `compilation_providers`
        *   `dependencies`
        *   `extension_infoplists`
        *   `generated_inputs`
        *   `hosted_targets`
        *   `inputs`
        *   `is_top_level_target`
        *   `lldb_context`
        *   `outputs`
        *   `potential_target_merges`
        *   `replacement_labels`
        *   `resource_bundle_informations`
        *   `rule_kind`
        *   `search_paths`
        *   `target_type`
        *   `test_envs`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
        *   `xcode_required_targets`
    """
    return {
        "compilation_providers": compilation_providers,
        "dependencies": dependencies,
        "extension_infoplists": extension_infoplists,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "is_top_level_target": is_top_level_target,
        "lldb_context": lldb_context,
        "outputs": outputs,
        "potential_target_merges": potential_target_merges,
        "replacement_labels": replacement_labels,
        "resource_bundle_informations": resource_bundle_informations,
        "rule_kind": rule_kind,
        "search_paths": search_paths,
        "target_type": target_type,
        "test_envs": test_envs,
        "transitive_dependencies": transitive_dependencies,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
        "xcode_required_targets": xcode_required_targets,
    }

def _skip_target(*, ctx, target, deps, deps_attrs, transitive_infos, automatic_target_info):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        target: The `Target` to skip.
        ctx: The aspect context.
        deps: `Target`s collected from `ctx.attr.deps`.
        deps_attrs: A sequence of attribute names to collect `Target`s from for
            `deps`-like attributes.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of the target.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.

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
        is_top_level_target = True,
        lldb_context = lldb_contexts.collect(
            id = None,
            is_swift = False,
            search_paths = search_paths,
            transitive_infos = [
                info
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
        replacement_labels = depset(
            [
                struct(id = info.xcode_target.id, label = target.label)
                for attr, info in transitive_infos
                if (target and
                    attr in deps_attrs and
                    info.xcode_target)
            ],
            transitive = [
                info.replacement_labels
                for _, info in transitive_infos
            ],
        ),
        resource_bundle_informations = depset(
            transitive = [
                info.resource_bundle_informations
                for _, info in transitive_infos
            ],
        ),
        rule_kind = None,
        search_paths = search_paths,
        target_type = target_type.compile,
        test_envs = depset(
            [
                _create_test_envs_depset(automatic_target_info = automatic_target_info, ctx = ctx, id = info.xcode_target.id, target = target)
                for attr, info in transitive_infos
                if (target and
                    attr in deps_attrs and
                    info.xcode_target)
            ],
            transitive = [
                info.test_envs
                for _, info in transitive_infos
            ],
        ),
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
        xcode_targets = depset(
            transitive = [info.xcode_targets for _, info in transitive_infos],
        ),
        xcode_required_targets = depset(
            transitive = [
                info.xcode_required_targets
                for _, info in transitive_infos
            ],
        ),
    )

def _create_test_envs_depset(*, automatic_target_info, ctx, id, target):
    test_env = getattr(ctx.rule.attr, automatic_target_info.env, {})
    raw_run_env = target[RunEnvironmentInfo].environment if RunEnvironmentInfo in target else {}

    # Some keys are not applicable in schemes, we will filter them out here
    run_env = {}
    denylist_run_env_keys = ["XCODE_VERSION_OVERRIDE", "XCODE_VERSION"]
    for key, value in raw_run_env.items():
        if key not in denylist_run_env_keys:
            run_env[key] = value

    return struct(id = id, env = struct(**dicts.add(test_env, run_env)))

def _create_xcodeprojinfo(
        *,
        ctx,
        target,
        transitive_infos,
        automatic_target_info):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
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
        is_top_level_target = processed_target.is_top_level_target,
        lldb_context = processed_target.lldb_context,
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
        replacement_labels = depset(
            transitive = [
                info.replacement_labels
                for _, info in transitive_infos
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
        rule_kind = ctx.rule.kind,
        search_paths = processed_target.search_paths,
        target_type = processed_target.automatic_target_info.target_type,
        test_envs = depset(
            transitive = [
                info.test_envs
                for _, info in transitive_infos
            ],
        ),
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
        xcode_required_targets = depset(
            processed_target.xcode_targets if processed_target.is_xcode_required else None,
            transitive = [
                info.xcode_required_targets
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
    automatic_target_info = target[XcodeProjAutomaticTargetProcessingInfo]

    if _should_skip_target(ctx = ctx, target = target):
        info_fields = _skip_target(
            automatic_target_info = automatic_target_info,
            ctx = ctx,
            target = target,
            deps = [
                dep
                for attr in automatic_target_info.deps
                for dep in getattr(ctx.rule.attr, attr, [])
            ],
            deps_attrs = automatic_target_info.deps,
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _create_xcodeprojinfo(
            ctx = ctx,
            target = target,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )

    return XcodeProjInfo(
        label = target.label,
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
        target = None,
        deps = [],
        deps_attrs = [],
        transitive_infos = [(None, info) for info in infos],
    )
    return XcodeProjInfo(
        label = None,
        **info_fields
    )

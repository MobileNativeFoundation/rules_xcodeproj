"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
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
load(":targets.bzl", "targets")
load(
    ":target_properties.bzl",
    "process_dependencies",
)
load(":top_level_targets.bzl", "process_top_level_target")

# Creating `XcodeProjInfo`

_INTERNAL_RULE_KINDS = {
    "apple_cc_toolchain": None,
    "apple_mac_tools_toolchain": None,
    "apple_xplat_tools_toolchain": None,
    "armeabi_cc_toolchain_config": None,
    "filegroup": None,
    "cc_toolchain": None,
    "cc_toolchain_alias": None,
    "cc_toolchain_suite": None,
    "macos_test_runner": None,
    "xcode_swift_toolchain": None,
}

_TOOLS_REPOS = {
    "build_bazel_rules_apple": None,
    "build_bazel_rules_swift": None,
    "bazel_tools": None,
    "xctestrunner": None,
}

# Just a slight optimization to not process things we know don't need to have
# out provider.
def _should_create_provider(*, ctx, target):
    if BuildSettingInfo in target:
        return False
    if target.label.workspace_name in _TOOLS_REPOS:
        return False
    if ctx.rule.kind in _INTERNAL_RULE_KINDS:
        return False
    return True

_BUILD_TEST_RULES = {
    "ios_build_test": None,
    "macos_build_test": None,
    "tvos_build_test": None,
    "watchos_build_test": None,
}

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
    if ctx.rule.kind in _BUILD_TEST_RULES:
        return True

    if AppleBinaryInfo in target and not hasattr(ctx.rule.attr, "deps"):
        return True

    return targets.is_test_bundle(
        target = target,
        deps = getattr(ctx.rule.attr, "deps", None),
    )

def _target_info_fields(
        *,
        args,
        compilation_providers,
        dependencies,
        envs,
        extension_infoplists,
        hosted_targets,
        inputs,
        is_top_level_target,
        lldb_context,
        mergable_xcode_library_targets,
        outputs,
        potential_target_merges,
        replacement_labels,
        resource_bundle_informations,
        rule_kind,
        search_paths,
        target_type,
        transitive_dependencies,
        xcode_target,
        xcode_targets,
        xcode_required_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        args: Maps to the `XcodeProjInfo.args` field.
        compilation_providers: Maps to the `XcodeProjInfo.compilation_providers`
            field.
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        envs: Maps to the `XcodeProjInfo.envs` field.
        extension_infoplists: Maps to the `XcodeProjInfo.extension_infoplists`
            field.
        hosted_targets: Maps to the `XcodeProjInfo.hosted_targets` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        is_top_level_target: Maps to the `XcodeProjInfo.is_top_level_target`
            field.
        lldb_context: Maps to the `XcodeProjInfo.lldb_context` field.
        mergable_xcode_library_targets: Maps to the
            `XcodeProjInfo.mergable_xcode_library_targets` field.
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
        transitive_dependencies: Maps to the
            `XcodeProjInfo.transitive_dependencies` field.
        xcode_target: Maps to the `XcodeProjInfo.xcode_target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.
        xcode_required_targets: Maps to the
            `XcodeProjInfo.xcode_required_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `args`
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
        *   `envs`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
        *   `xcode_required_targets`
    """
    return {
        "args": args,
        "compilation_providers": compilation_providers,
        "dependencies": dependencies,
        "extension_infoplists": extension_infoplists,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "is_top_level_target": is_top_level_target,
        "lldb_context": lldb_context,
        "outputs": outputs,
        "mergable_xcode_library_targets": mergable_xcode_library_targets,
        "potential_target_merges": potential_target_merges,
        "replacement_labels": replacement_labels,
        "resource_bundle_informations": resource_bundle_informations,
        "rule_kind": rule_kind,
        "search_paths": search_paths,
        "target_type": target_type,
        "envs": envs,
        "transitive_dependencies": transitive_dependencies,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
        "xcode_required_targets": xcode_required_targets,
    }

def _skip_target(
        *,
        ctx,
        target,
        deps,
        deps_attrs,
        transitive_infos,
        automatic_target_info):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        ctx: The aspect context.
        target: The `Target` to skip.
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
            if XcodeProjInfo in deps
        ],
    )

    dependencies, transitive_dependencies = process_dependencies(
        automatic_target_info = None,
        transitive_infos = transitive_infos,
    )

    return _target_info_fields(
        args = depset(
            [
                _create_args_depset(
                    ctx = ctx,
                    id = info.xcode_target.id,
                    automatic_target_info = automatic_target_info,
                )
                for attr, info in transitive_infos
                if (target and
                    attr in deps_attrs and
                    info.xcode_target and
                    automatic_target_info.args)
            ],
            transitive = [
                info.args
                for _, info in transitive_infos
            ],
        ),
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
            clang_opts = [],
            transitive_infos = [
                info
                for _, info in transitive_infos
            ],
        ),
        mergable_xcode_library_targets = depset(
            transitive = [
                info.mergable_xcode_library_targets
                for _, info in transitive_infos
            ],
        ),
        outputs = output_files.merge(
            ctx = ctx,
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
        search_paths = None,
        target_type = target_type.compile,
        envs = depset(
            [
                _create_envs_depset(
                    ctx = ctx,
                    id = info.xcode_target.id,
                    automatic_target_info = automatic_target_info,
                )
                for attr, info in transitive_infos
                if (target and
                    attr in deps_attrs and
                    info.xcode_target and
                    automatic_target_info.env)
            ],
            transitive = [
                info.envs
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

def _create_args_depset(*, ctx, id, automatic_target_info):
    return struct(
        id = id,
        args = getattr(ctx.rule.attr, automatic_target_info.args, []),
    )

def _create_envs_depset(*, ctx, id, automatic_target_info):
    test_env = getattr(ctx.rule.attr, automatic_target_info.env, {})

    return struct(
        id = id,
        env = struct(
            **dicts.add(test_env, ctx.configuration.test_env)
        ),
    )

def _create_xcodeprojinfo(
        *,
        ctx,
        build_mode,
        target,
        transitive_infos,
        automatic_target_info):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
    if not _should_create_provider(ctx = ctx, target = target):
        return None

    if automatic_target_info.bazel_build_mode_error and build_mode != "bazel":
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
            build_mode = build_mode,
            target = target,
            automatic_target_info = automatic_target_info,
            bundle_info = target[AppleBundleInfo],
            transitive_infos = transitive_infos,
        )
    elif target[DefaultInfo].files_to_run.executable:
        processed_target = process_top_level_target(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            automatic_target_info = automatic_target_info,
            bundle_info = None,
            transitive_infos = transitive_infos,
        )
    else:
        processed_target = process_library_target(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )

    return _target_info_fields(
        args = depset(
            transitive = [
                info.args
                for _, info in transitive_infos
            ],
        ),
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
        mergable_xcode_library_targets = depset(processed_target.mergable_xcode_library_targets),
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
        envs = depset(
            transitive = [
                info.envs
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

def create_xcodeprojinfo(*, ctx, build_mode, target, transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
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
            ctx = ctx,
            target = target,
            deps = [
                dep
                for attr in automatic_target_info.deps
                for dep in getattr(ctx.rule.attr, attr, [])
            ],
            deps_attrs = automatic_target_info.deps,
            transitive_infos = transitive_infos,
            automatic_target_info = automatic_target_info,
        )
    else:
        info_fields = _create_xcodeprojinfo(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )

    if not info_fields:
        return None

    return XcodeProjInfo(
        label = target.label,
        labels = depset(
            [target.label],
            transitive = [
                info.labels
                for _, info in transitive_infos
            ],
        ),
        **info_fields
    )

"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
)
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "NONE_LIST",
    "memory_efficient_depset",
)
load(":automatic_target_info.bzl", "calculate_automatic_target_info")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":input_files.bzl", "bwx_output_groups", "input_files")
load(":library_targets.bzl", "process_library_target")
load(":output_files.bzl", "bwb_output_groups", "output_files")
load(":processed_target.bzl", "processed_target")
load(
    ":providers.bzl",
    "XcodeProjInfo",
    "target_type",
)
load(
    ":target_properties.bzl",
    "process_dependencies",
)
load(":targets.bzl", "targets")
load(":top_level_targets.bzl", "process_top_level_target")
load(":unsupported_targets.bzl", "process_unsupported_target")

# Creating `XcodeProjInfo`

_INTERNAL_RULE_KINDS = {
    "apple_cc_toolchain": None,
    "apple_mac_tools_toolchain": None,
    "apple_xplat_tools_toolchain": None,
    "armeabi_cc_toolchain_config": None,
    "cc_toolchain": None,
    "cc_toolchain_alias": None,
    "cc_toolchain_suite": None,
    "filegroup": None,
    "macos_test_runner": None,
    "xcode_swift_toolchain": None,
}

_TOOLS_REPOS = {
    "apple_support": None,
    "bazel_tools": None,
    "build_bazel_apple_support": None,
    "build_bazel_rules_apple": None,
    "build_bazel_rules_swift": None,
    "rules_apple": None,
    "rules_swift": None,
    "xctestrunner": None,
}

_BUILD_TEST_RULES = {
    "ios_build_test": None,
    "macos_build_test": None,
    "tvos_build_test": None,
    "watchos_build_test": None,
}

_TEST_SUITE_RULES = {
    "test_suite": None,
}

skip_type = struct(
    apple_build_test = "apple_build_test",
    apple_binary_no_deps = "apple_binary_no_deps",
    apple_test_bundle = "apple_test_bundle",
    test_suite = "test_suite",
)

def _get_skip_type(*, ctx, target):
    """Determines if the given target should be skipped for target generation.

    There are some rules, like the test runners for iOS tests, that we want to
    ignore. Nothing from those rules are considered.

    Args:
        ctx: The aspect context.
        target: The `Target` to check.

    Returns:
        A `skip_type` if `target` should be skipped, otherwise `None`.
    """
    if ctx.rule.kind in _BUILD_TEST_RULES:
        return skip_type.apple_build_test

    if ctx.rule.kind in _TEST_SUITE_RULES:
        return skip_type.test_suite

    if AppleBinaryInfo in target and not hasattr(ctx.rule.attr, "deps"):
        return skip_type.apple_binary_no_deps

    if targets.is_test_bundle(
        target = target,
        deps = getattr(ctx.rule.attr, "deps", None),
    ):
        return skip_type.apple_test_bundle

    return None

def _target_info_fields(
        *,
        bwb_output_groups,
        bwx_output_groups,
        compilation_providers,
        dependencies,
        extension_infoplists,
        focused_deps,
        hosted_targets,
        inputs,
        mergeable_infos,
        merged_target_ids,
        non_top_level_rule_kind,
        outputs,
        platforms,
        resource_bundle_ids,
        target_type,
        top_level_focused_deps,
        transitive_dependencies,
        xcode_target,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        bwb_output_groups: Maps to the `XcodeProjInfo.bwb_output_groups` field.
        bwx_output_groups: Maps to the `XcodeProjInfo.bwx_output_groups` field.
        compilation_providers: Maps to the
            `XcodeProjInfo.compilation_providers` field.
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        extension_infoplists: Maps to the
            `XcodeProjInfo.extension_infoplists` field.
        focused_deps: Maps to the `XcodeProjInfo.focused_deps` field.
        hosted_targets: Maps to the `XcodeProjInfo.hosted_targets` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        mergeable_infos: Maps to the `XcodeProjInfo.mergeable_infos` field.
        merged_target_ids: Maps to the `XcodeProjInfo.merged_target_ids` field.
        non_top_level_rule_kind: Maps to the
            `XcodeProjInfo.non_top_level_rule_kind` field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        platforms: Maps to the `XcodeProjInfo.platforms` field.
        resource_bundle_ids: Maps to the
            `XcodeProjInfo.resource_bundle_ids` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        top_level_focused_deps: Maps to the
            `XcodeProjInfo.top_level_focused_deps` field.
        transitive_dependencies: Maps to the
            `XcodeProjInfo.transitive_dependencies` field.
        xcode_target: Maps to the `XcodeProjInfo.xcode_target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `bwb_output_groups`
        *   `bwx_output_groups`
        *   `compilation_providers`
        *   `dependencies`
        *   `extension_infoplists`
        *   `focused_deps`
        *   `hosted_targets`
        *   `inputs`
        *   `mergeable_infos`
        *   `merged_target_ids`
        *   `non_top_level_rule_kind`
        *   `outputs`
        *   `platforms`
        *   `resource_bundle_ids`
        *   `target_type`
        *   `top_level_focused_deps`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
    """
    return {
        "bwb_output_groups": bwb_output_groups,
        "bwx_output_groups": bwx_output_groups,
        "compilation_providers": compilation_providers,
        "dependencies": dependencies,
        "extension_infoplists": extension_infoplists,
        "focused_deps": focused_deps,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "mergeable_infos": mergeable_infos,
        "merged_target_ids": merged_target_ids,
        "non_top_level_rule_kind": non_top_level_rule_kind,
        "outputs": outputs,
        "platforms": platforms,
        "resource_bundle_ids": resource_bundle_ids,
        "target_type": target_type,
        "top_level_focused_deps": top_level_focused_deps,
        "transitive_dependencies": transitive_dependencies,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
    }

def _skip_target(
        *,
        ctx,
        build_mode,
        target,
        target_skip_type,
        deps,
        deps_attrs,
        transitive_infos,
        automatic_target_info):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
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

    valid_transitive_infos = [
        info
        for _, info in transitive_infos
    ]

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = valid_transitive_infos,
    )

    provider_outputs = output_files.merge(
        transitive_infos = valid_transitive_infos,
    )

    return _target_info_fields(
        bwb_output_groups = bwb_output_groups.merge(
            transitive_infos = valid_transitive_infos,
        ),
        bwx_output_groups = bwx_output_groups.merge(
            transitive_infos = valid_transitive_infos,
        ),
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = memory_efficient_depset(
            transitive = [
                info.extension_infoplists
                for info in valid_transitive_infos
            ],
        ),
        focused_deps = memory_efficient_depset(
            transitive = [
                info.focused_deps
                for info in valid_transitive_infos
            ],
        ),
        hosted_targets = memory_efficient_depset(
            transitive = [
                info.hosted_targets
                for info in valid_transitive_infos
            ],
        ),
        inputs = input_files.merge(
            transitive_infos = valid_transitive_infos,
        ),
        mergeable_infos = memory_efficient_depset(
            transitive = [
                info.mergeable_infos
                for info in valid_transitive_infos
            ],
        ),
        merged_target_ids = memory_efficient_depset(
            transitive = [
                info.merged_target_ids
                for info in valid_transitive_infos
            ],
        ),
        non_top_level_rule_kind = None,
        outputs = provider_outputs,
        platforms = memory_efficient_depset(
            transitive = [info.platforms for info in valid_transitive_infos],
        ),
        resource_bundle_ids = memory_efficient_depset(
            transitive = [
                info.resource_bundle_ids
                for info in valid_transitive_infos
            ],
        ),
        target_type = target_type.compile,
        top_level_focused_deps = memory_efficient_depset(
            transitive = [
                info.top_level_focused_deps
                for info in valid_transitive_infos
            ],
        ),
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
        xcode_targets = memory_efficient_depset(
            transitive = [
                info.xcode_targets
                for info in valid_transitive_infos
            ],
        ),
    )

def _create_xcodeprojinfo(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        transitive_infos,
        automatic_target_info):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
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

    valid_transitive_infos = [
        info
        for attr, info in transitive_infos
        if (info.target_type in automatic_target_info.xcode_targets.get(
            attr,
            NONE_LIST,
        ))
    ]

    generate_target = _should_generate_target(
        focused_labels = ctx.attr._focused_labels,
        label = automatic_target_info.label,
        unfocused_labels = ctx.attr._unfocused_labels,
    )

    if not automatic_target_info.is_supported:
        processed_target = process_unsupported_target(
            ctx = ctx,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            is_focused = generate_target,
            transitive_infos = valid_transitive_infos,
        )
        focused_deps = EMPTY_DEPSET
    elif automatic_target_info.is_top_level:
        processed_target = process_top_level_target(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            generate_target = generate_target,
            transitive_infos = valid_transitive_infos,
        )
        focused_deps = EMPTY_DEPSET
    else:
        processed_target = process_library_target(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            generate_target = generate_target,
            transitive_infos = valid_transitive_infos,
        )
        focused_deps = memory_efficient_depset(
            [
                struct(
                    label = str(target.label),
                    id = processed_target.xcode_target.id,
                )
            ] if processed_target.xcode_target else None,
            # We want the last one specified to be the one used
            order = "postorder",
            transitive = [
                info.focused_deps
                for info in valid_transitive_infos
            ],
        )

    return _target_info_fields(
        bwb_output_groups = processed_target.bwb_output_groups,
        bwx_output_groups = processed_target.bwx_output_groups,
        compilation_providers = processed_target.compilation_providers,
        focused_deps = focused_deps,
        dependencies = processed_target.dependencies,
        extension_infoplists = memory_efficient_depset(
            processed_target.extension_infoplists,
            transitive = [
                info.extension_infoplists
                for info in valid_transitive_infos
            ],
        ),
        hosted_targets = memory_efficient_depset(
            processed_target.hosted_targets,
            transitive = [
                info.hosted_targets
                for info in valid_transitive_infos
            ],
        ),
        inputs = processed_target.inputs,
        mergeable_infos = processed_target.mergeable_infos,
        merged_target_ids = memory_efficient_depset(
            processed_target.merged_target_ids,
            transitive = [
                info.merged_target_ids
                for info in valid_transitive_infos
            ],
        ),
        non_top_level_rule_kind = (
            None if processed_target.is_top_level else ctx.rule.kind
        ),
        outputs = processed_target.outputs,
        platforms = memory_efficient_depset(
            [processed_target.platform] if processed_target.platform else None,
            transitive = [info.platforms for info in valid_transitive_infos],
        ),
        resource_bundle_ids = memory_efficient_depset(
            processed_target.resource_bundle_ids,
            transitive = [
                info.resource_bundle_ids
                for info in valid_transitive_infos
            ],
        ),
        target_type = automatic_target_info.target_type,
        top_level_focused_deps = memory_efficient_depset(
            processed_target.top_level_focused_deps,
            transitive = [
                info.top_level_focused_deps
                for info in valid_transitive_infos
            ],
        ),
        transitive_dependencies = processed_target.transitive_dependencies,
        xcode_target = processed_target.xcode_target,
        xcode_targets = memory_efficient_depset(
            processed_target.xcode_targets,
            transitive = [
                info.xcode_targets
                for info in valid_transitive_infos
            ],
        ),
    )

# Just a slight optimization to not process things we know don't need to have
# out provider.
def _should_create_provider(*, ctx, target):
    if not target.label.workspace_name:
        return True
    if BuildSettingInfo in target:
        return False
    if ctx.rule.kind in _INTERNAL_RULE_KINDS:
        return False
    if target.label.workspace_name.split("~")[0] in _TOOLS_REPOS:
        return False
    return True

def _should_generate_target(*, focused_labels, label, unfocused_labels):
    if not focused_labels and not unfocused_labels:
        return True

    label_str = str(label)
    if label_str in unfocused_labels:
        return False

    if focused_labels and label_str not in focused_labels:
        return False

    return True

# API

def create_xcodeprojinfo(*, ctx, build_mode, target, attrs, transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        An `XcodeProjInfo` populated with information from `target` and
        `transitive_infos`.
    """
    automatic_target_info = calculate_automatic_target_info(
        ctx = ctx,
        build_mode = build_mode,
        target = target,
    )

    target_skip_type = _get_skip_type(ctx = ctx, target = target)
    if target_skip_type:
        info_fields = _skip_target(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            target_skip_type = target_skip_type,
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
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        )

    if not info_fields:
        return None

    return XcodeProjInfo(
        **info_fields
    )

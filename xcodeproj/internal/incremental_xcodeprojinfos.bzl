"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
)
load(
    "//xcodeproj/internal/files:incremental_input_files.bzl",
    input_files = "incremental_input_files",
)
load(
    "//xcodeproj/internal/files:incremental_output_files.bzl",
    "output_groups",
    output_files = "incremental_output_files",
)
load(
    "//xcodeproj/internal/processed_targets:incremental_library_targets.bzl",
    library_targets = "incremental_library_targets",
)
load(
    "//xcodeproj/internal/processed_targets:incremental_top_level_targets.bzl",
    top_level_targets = "incremental_top_level_targets",
)
load(
    "//xcodeproj/internal/processed_targets:incremental_unsupported_targets.bzl",
    unsupported_targets = "incremental_unsupported_targets",
)
load(
    "//xcodeproj/internal/processed_targets:mixed_language_library_targets.bzl",
    "mixed_language_library_targets",
)
load(":automatic_target_info.bzl", "calculate_automatic_target_info")
load(":compilation_providers.bzl", "compilation_providers")
load(":dependencies.bzl", "dependencies")
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "NONE_LIST",
    "memory_efficient_depset",
)
load(":targets.bzl", "targets")
load(":xcodeprojinfo.bzl", "XcodeProjInfo", "target_type")

# Creating `XcodeProjInfo`

_BUILD_TEST_RULES = {
    "ios_build_test": None,
    "macos_build_test": None,
    "tvos_build_test": None,
    "watchos_build_test": None,
}

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

_TEST_SUITE_RULES = {
    "test_suite": None,
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

_SKIP_TYPE = struct(
    apple_build_test = "apple_build_test",
    apple_binary_no_deps = "apple_binary_no_deps",
    apple_test_bundle = "apple_test_bundle",
    test_suite = "test_suite",
)

_FOCUSED_DEPS_COLLECTION_SKIPPED_TYPES = {
    _SKIP_TYPE.apple_build_test: None,
    _SKIP_TYPE.apple_binary_no_deps: None,
}

def _get_skip_type(*, rule_attr, rule_kind, target):
    """Determines if the given target should be skipped for target generation.

    There are some rules, like the test runners for iOS tests, that we want to
    ignore. Nothing from those rules are considered.

    Args:
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
        target: The `Target` to check.

    Returns:
        A `_SKIP_TYPE` if `target` should be skipped, otherwise `None`.
    """
    if rule_kind in _BUILD_TEST_RULES:
        return _SKIP_TYPE.apple_build_test

    if rule_kind in _TEST_SUITE_RULES:
        return _SKIP_TYPE.test_suite

    if AppleBinaryInfo in target and not hasattr(rule_attr, "deps"):
        return _SKIP_TYPE.apple_binary_no_deps

    if targets.is_test_bundle(
        target = target,
        deps = getattr(rule_attr, "deps", None),
    ):
        return _SKIP_TYPE.apple_test_bundle

    return None

def _process_test_command_line_args(args):
    # Currently we only support rules_apple based tests, and with those we need
    # to extract the `--command_line_args` based args
    return tuple([
        arg
        for raw_arg in args
        if raw_arg.startswith("--command_line_args=")
        for arg in raw_arg[20:].split(",")
    ])

def _target_info_fields(
        *,
        args,
        compilation_providers,
        direct_dependencies,
        envs,
        extension_infoplists,
        framework_product_mappings,
        focused_labels,
        focused_library_deps,
        hosted_targets,
        inputs,
        mergeable_infos,
        merged_target_ids,
        non_top_level_rule_kind,
        outputs,
        platforms,
        resource_bundle_ids,
        swift_debug_settings,
        target_output_groups,
        target_type,
        top_level_focused_deps,
        top_level_swift_debug_settings,
        transitive_dependencies,
        xcode_target,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        args: Maps to the `XcodeProjInfo.args` field.
        compilation_providers: Maps to the
            `XcodeProjInfo.compilation_providers` field.
        direct_dependencies: Maps to the `XcodeProjInfo.direct_dependencies`
            field.
        envs: Maps to the `XcodeProjInfo.envs` field.
        extension_infoplists: Maps to the
            `XcodeProjInfo.extension_infoplists` field.
        framework_product_mappings: Maps to the
            `XcodeProjInfo.framework_product_mappings` field.
        focused_labels: Maps to the `XcodeProjInfo.focused_labels` field.
        focused_library_deps: Maps to the `XcodeProjInfo.focused_library_deps`
            field.
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
        swift_debug_settings: Maps to the
            `XcodeProjInfo.swift_debug_settings` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        target_output_groups: Maps to the `XcodeProjInfo.target_output_groups`
            field.
        top_level_focused_deps: Maps to the
            `XcodeProjInfo.top_level_focused_deps` field.
        top_level_swift_debug_settings: Maps to the
            `XcodeProjInfo.top_level_swift_debug_settings` field.
        transitive_dependencies: Maps to the
            `XcodeProjInfo.transitive_dependencies` field.
        xcode_target: Maps to the `XcodeProjInfo.xcode_target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `args`
        *   `compilation_providers`
        *   `direct_dependencies`
        *   `envs`
        *   `extension_infoplists`
        *   `framework_product_mappings`
        *   `focused_labels`
        *   `focused_library_deps`
        *   `hosted_targets`
        *   `inputs`
        *   `mergeable_infos`
        *   `merged_target_ids`
        *   `non_top_level_rule_kind`
        *   `outputs`
        *   `platforms`
        *   `resource_bundle_ids`
        *   `swift_debug_settings`
        *   `target_output_groups`
        *   `target_type`
        *   `top_level_focused_deps`
        *   `top_level_swift_debug_settings`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
    """
    return {
        "args": args,
        "compilation_providers": compilation_providers,
        "direct_dependencies": direct_dependencies,
        "envs": envs,
        "extension_infoplists": extension_infoplists,
        "focused_labels": focused_labels,
        "focused_library_deps": focused_library_deps,
        "framework_product_mappings": framework_product_mappings,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "mergeable_infos": mergeable_infos,
        "merged_target_ids": merged_target_ids,
        "non_top_level_rule_kind": non_top_level_rule_kind,
        "outputs": outputs,
        "platforms": platforms,
        "resource_bundle_ids": resource_bundle_ids,
        "swift_debug_settings": swift_debug_settings,
        "target_output_groups": target_output_groups,
        "target_type": target_type,
        "top_level_focused_deps": top_level_focused_deps,
        "top_level_swift_debug_settings": top_level_swift_debug_settings,
        "transitive_dependencies": transitive_dependencies,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
    }

def _make_skipped_target_xcodeprojinfo(
        *,
        ctx,
        automatic_target_info,
        rule_attr,
        skip_type,
        test_env,
        transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        ctx: The aspect context.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `the target.
        rule_attr: `ctx.rule.attr`.
        skip_type: A value returned by `_get_skip_type`.
        test_env: `ctx.configuration.test_env`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of the target.

    Returns:
        The return value of `_target_info_fields`, with values merged from
        `transitive_infos`.
    """
    deps_attrs = automatic_target_info.deps
    deps = [
        dep
        for attr in deps_attrs
        for dep in getattr(rule_attr, attr, [])
    ]
    deps_transitive_infos = [
        info
        for attr, info in transitive_infos
        if attr in deps_attrs and info.xcode_target
    ]
    valid_transitive_infos = [
        info
        for _, info in transitive_infos
    ]

    # Test bundles already collect their focused library deps, so we shouldn't
    # here, otherwise we will override their id with whatever is picked here.
    # Collecting `top_level_focused_deps` here allows using `*_build_test` rules
    # in `xcschemes.top_level_anchor_target`.
    if skip_type in _FOCUSED_DEPS_COLLECTION_SKIPPED_TYPES:
        first_id = None
        for info in valid_transitive_infos:
            if info.xcode_target:
                # If this target gets listed in something like
                # `xcschemes.top_level_build_target`, we use the first available
                # target id. This isn't really a supported use case. We could
                # maybe handle multiple ids, but that requires a bit more work.
                first_id = info.xcode_target.id
                break

        focused_library_deps = {
            s.label: s.id
            for s in depset(
                order = "postorder",
                transitive = [
                    info.focused_library_deps
                    for info in valid_transitive_infos
                ],
            ).to_list()
        }
        top_level_focused_deps = [
            struct(
                id = first_id,
                label = str(automatic_target_info.label),
                deps = tuple([
                    struct(id = id, label = label)
                    for label, id in focused_library_deps.items()
                ]),
            ),
        ]
    else:
        top_level_focused_deps = None

    direct_dependencies, transitive_dependencies = dependencies.collect(
        transitive_infos = valid_transitive_infos,
    )

    provider_outputs = output_files.merge(
        transitive_infos = valid_transitive_infos,
    )

    # TODO: Don't do this? These are only top-level targets (maybe we should
    # rename function?) and nothing looks at them?
    (
        _,
        provider_compilation_providers,
    ) = compilation_providers.merge(
        propagate_providers = False,
        transitive_compilation_providers = [
            (
                dep[XcodeProjInfo].xcode_target,
                dep[XcodeProjInfo].compilation_providers,
            )
            for dep in deps
            if XcodeProjInfo in deps
        ],
    )

    if automatic_target_info.env:
        direct_envs = []
        for info in deps_transitive_infos:
            if not info.xcode_target:
                continue

            info_env = getattr(rule_attr, automatic_target_info.env, {})
            info_env = {
                k: ctx.expand_make_variables("env", v, {})
                for k, v in info_env.items()
            }
            env = dicts.add(info_env, test_env)
            direct_envs.append(struct(id = info.xcode_target.id, env = tuple([(k, v) for k, v in env.items()])))
    else:
        direct_envs = None

    return _target_info_fields(
        args = memory_efficient_depset(
            [
                struct(
                    id = info.xcode_target.id,
                    args = _process_test_command_line_args(
                        getattr(rule_attr, automatic_target_info.args, []),
                    ),
                )
                for info in deps_transitive_infos
                if info.xcode_target
            ] if automatic_target_info.args else None,
            transitive = [
                info.args
                for info in valid_transitive_infos
            ],
        ),
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        envs = memory_efficient_depset(
            direct_envs,
            transitive = [
                info.envs
                for info in valid_transitive_infos
            ],
        ),
        extension_infoplists = memory_efficient_depset(
            transitive = [
                info.extension_infoplists
                for info in valid_transitive_infos
            ],
        ),
        framework_product_mappings = memory_efficient_depset(
            transitive = [
                info.framework_product_mappings
                for info in valid_transitive_infos
            ],
        ),
        focused_labels = memory_efficient_depset(
            transitive = [
                info.focused_labels
                for info in valid_transitive_infos
            ],
        ),
        focused_library_deps = memory_efficient_depset(
            transitive = [
                info.focused_library_deps
                for info in valid_transitive_infos
            ],
        ),
        hosted_targets = memory_efficient_depset(
            transitive = [
                info.hosted_targets
                for info in valid_transitive_infos
            ],
        ),
        inputs = input_files.merge(transitive_infos = valid_transitive_infos),
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
        swift_debug_settings = EMPTY_DEPSET,
        target_output_groups = output_groups.merge(
            transitive_infos = valid_transitive_infos,
        ),
        top_level_swift_debug_settings = memory_efficient_depset(
            transitive = [
                info.top_level_swift_debug_settings
                for info in valid_transitive_infos
            ],
        ),
        target_type = target_type.compile,
        top_level_focused_deps = memory_efficient_depset(
            top_level_focused_deps,
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

def _make_non_skipped_target_xcodeprojinfo(
        *,
        ctx,
        aspect_attr,
        attrs,
        automatic_target_info,
        rule_attr,
        rule_kind,
        target,
        transitive_infos):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        aspect_attr: `ctx.attr`.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
    valid_transitive_infos = [
        info
        for attr, info in transitive_infos
        if (info.target_type in automatic_target_info.xcode_targets.get(
            attr,
            NONE_LIST,
        ))
    ]

    label_str = str(automatic_target_info.label)
    is_focused = _is_focused(
        focused_labels = aspect_attr._focused_labels,
        label_str = label_str,
        unfocused_labels = aspect_attr._unfocused_labels,
    )

    focused_labels = memory_efficient_depset(
        [label_str] if is_focused else None,
        transitive = [
            info.focused_labels
            for _, info in transitive_infos
        ],
    )

    if not automatic_target_info.is_supported:
        processed_target = unsupported_targets.process(
            ctx = ctx,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            is_focused = is_focused,
            rule_attr = rule_attr,
            transitive_infos = valid_transitive_infos,
        )
        focused_library_deps = memory_efficient_depset(
            # We want the last one specified to be the one used
            order = "postorder",
            transitive = [
                info.focused_library_deps
                for info in valid_transitive_infos
            ],
        )
    elif automatic_target_info.is_top_level:
        processed_target = top_level_targets.process(
            ctx = ctx,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            focused_labels = focused_labels,
            generate_target = (
                automatic_target_info.should_generate and is_focused
            ),
            rule_attr = rule_attr,
            transitive_infos = valid_transitive_infos,
        )
        focused_library_deps = EMPTY_DEPSET
    elif automatic_target_info.is_mixed_language:
        (
            processed_target,
            swift_label,
            clang_label,
        ) = mixed_language_library_targets.process(
            ctx = ctx,
            automatic_target_info = automatic_target_info,
            generate_target = (
                automatic_target_info.should_generate and is_focused
            ),
            target = target,
            transitive_infos = valid_transitive_infos,
            rule_attr = rule_attr,
        )
        focused_library_deps = memory_efficient_depset(
            [
                struct(
                    id = processed_target.xcode_target.id,
                    label = str(swift_label),
                ),
                struct(
                    id = processed_target.xcode_target.id,
                    label = str(clang_label),
                ),
                struct(
                    id = processed_target.xcode_target.id,
                    label = label_str,
                ),
            ] if processed_target.xcode_target else None,
            # We want the last one specified to be the one used
            order = "postorder",
            transitive = [
                info.focused_library_deps
                for info in valid_transitive_infos
            ],
        )
    else:
        processed_target = library_targets.process(
            ctx = ctx,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            generate_target = (
                automatic_target_info.should_generate and is_focused
            ),
            target = target,
            transitive_infos = valid_transitive_infos,
            rule_attr = rule_attr,
        )
        focused_library_deps = memory_efficient_depset(
            [
                struct(
                    id = processed_target.xcode_target.id,
                    label = label_str,
                ),
            ] if processed_target.xcode_target else None,
            # We want the last one specified to be the one used
            order = "postorder",
            transitive = [
                info.focused_library_deps
                for info in valid_transitive_infos
            ],
        )

    return _target_info_fields(
        args = memory_efficient_depset(
            transitive = [
                info.args
                for _, info in transitive_infos
            ],
        ),
        compilation_providers = processed_target.compilation_providers,
        focused_labels = focused_labels,
        focused_library_deps = focused_library_deps,
        direct_dependencies = processed_target.direct_dependencies,
        envs = memory_efficient_depset(
            transitive = [
                info.envs
                for _, info in transitive_infos
            ],
        ),
        extension_infoplists = memory_efficient_depset(
            processed_target.extension_infoplists,
            transitive = [
                info.extension_infoplists
                for info in valid_transitive_infos
            ],
        ),
        framework_product_mappings = memory_efficient_depset(
            processed_target.framework_product_mappings,
            transitive = [
                info.framework_product_mappings
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
            None if processed_target.is_top_level else rule_kind
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
        swift_debug_settings = processed_target.swift_debug_settings,
        target_output_groups = processed_target.target_output_groups,
        target_type = automatic_target_info.target_type,
        top_level_focused_deps = memory_efficient_depset(
            processed_target.top_level_focused_deps,
            transitive = [
                info.top_level_focused_deps
                for info in valid_transitive_infos
            ],
        ),
        top_level_swift_debug_settings = (
            processed_target.top_level_swift_debug_settings
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

def _should_create_provider(*, bin_dir_path, rule_kind, target):
    if "-exec-" in bin_dir_path:
        # We don't want to include "tools" (exec configuration) targets
        return False

    if rule_kind in _INTERNAL_RULE_KINDS:
        return False
    if BuildSettingInfo in target:
        return False
    if not target.label.workspace_name:
        return True

    bzlmod_components = target.label.workspace_name.split("~")
    if len(bzlmod_components) <= 2 and bzlmod_components[0] in _TOOLS_REPOS:
        # The check for 2 components is to not exclude module extension
        # dependencies
        return False

    return True

def _is_focused(*, focused_labels, label_str, unfocused_labels):
    if not focused_labels and not unfocused_labels:
        return True

    if label_str in unfocused_labels:
        return False

    if focused_labels and label_str not in focused_labels:
        return False

    return True

# API

def _make_xcodeprojinfo(
        *,
        ctx,
        attrs,
        rule_attr,
        rule_kind,
        target,
        transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        An `XcodeProjInfo` populated with information from `target` and
        `transitive_infos`.
    """
    if not _should_create_provider(
        bin_dir_path = ctx.bin_dir.path,
        rule_kind = rule_kind,
        target = target,
    ):
        return None

    automatic_target_info = calculate_automatic_target_info(
        ctx = ctx,
        rule_attr = rule_attr,
        rule_kind = rule_kind,
        target = target,
    )

    target_skip_type = _get_skip_type(
        rule_attr = rule_attr,
        rule_kind = rule_kind,
        target = target,
    )
    if target_skip_type:
        info_fields = _make_skipped_target_xcodeprojinfo(
            ctx = ctx,
            automatic_target_info = automatic_target_info,
            rule_attr = rule_attr,
            skip_type = target_skip_type,
            test_env = ctx.configuration.test_env,
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _make_non_skipped_target_xcodeprojinfo(
            ctx = ctx,
            aspect_attr = ctx.attr,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            rule_attr = rule_attr,
            rule_kind = rule_kind,
            target = target,
            transitive_infos = transitive_infos,
        )

    return XcodeProjInfo(
        label = target.label,
        **info_fields
    )

incremental_xcodeprojinfos = struct(
    make = _make_xcodeprojinfo,
)

"""Module for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
    "AppleBundleInfo",
)
load(
    "//xcodeproj/internal/files:legacy_input_files.bzl",
    input_files = "legacy_input_files",
)
load(
    "//xcodeproj/internal/files:legacy_output_files.bzl",
    output_files = "legacy_output_files",
)
load(
    "//xcodeproj/internal/processed_targets:legacy_library_targets.bzl",
    library_targets = "legacy_library_targets",
)
load(
    "//xcodeproj/internal/processed_targets:legacy_top_level_targets.bzl",
    top_level_targets = "legacy_top_level_targets",
)
load(
    "//xcodeproj/internal/processed_targets:legacy_unsupported_targets.bzl",
    unsupported_targets = "legacy_unsupported_targets",
)
load(":automatic_target_info.bzl", "calculate_automatic_target_info")
load(":bazel_labels.bzl", "bazel_labels")
load(":compilation_providers.bzl", "compilation_providers")
load(":legacy_target_properties.bzl", "process_dependencies")
load(":lldb_contexts.bzl", "lldb_contexts")
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

_SKIP_TYPE = struct(
    apple_build_test = "apple_build_test",
    apple_binary_no_deps = "apple_binary_no_deps",
    apple_test_bundle = "apple_test_bundle",
    test_suite = "test_suite",
)

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

# Just a slight optimization to not process things we know don't need to have
# our provider
def _should_create_provider(*, rule_kind, target):
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

def _target_info_fields(
        *,
        args,
        compilation_providers,
        direct_dependencies,
        envs,
        extension_infoplists,
        hosted_targets,
        inputs,
        lldb_context,
        mergable_xcode_library_targets,
        non_top_level_rule_kind,
        outputs,
        potential_target_merges,
        replacement_labels,
        resource_bundle_ids,
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
        direct_dependencies: Maps to the `XcodeProjInfo.direct_dependencies`
            field.
        envs: Maps to the `XcodeProjInfo.envs` field.
        extension_infoplists: Maps to the `XcodeProjInfo.extension_infoplists`
            field.
        hosted_targets: Maps to the `XcodeProjInfo.hosted_targets` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        lldb_context: Maps to the `XcodeProjInfo.lldb_context` field.
        mergable_xcode_library_targets: Maps to the
            `XcodeProjInfo.mergable_xcode_library_targets` field.
        non_top_level_rule_kind: Maps to the
            `XcodeProjInfo.non_top_level_rule_kind` field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        replacement_labels: Maps to the `XcodeProjInfo.replacement_labels`
            field.
        resource_bundle_ids: Maps to the
            `XcodeProjInfo.resource_bundle_ids` field.
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
        *   `direct_dependencies`
        *   `extension_infoplists`
        *   `envs`
        *   `generated_inputs`
        *   `hosted_targets`
        *   `inputs`
        *   `lldb_context`
        *   `non_top_level_rule_kind`
        *   `outputs`
        *   `potential_target_merges`
        *   `replacement_labels`
        *   `resource_bundle_ids`
        *   `target_type`
        *   `transitive_dependencies`
        *   `xcode_target`
        *   `xcode_targets`
        *   `xcode_required_targets`
    """
    return {
        "args": args,
        "compilation_providers": compilation_providers,
        "direct_dependencies": direct_dependencies,
        "envs": envs,
        "extension_infoplists": extension_infoplists,
        "hosted_targets": hosted_targets,
        "inputs": inputs,
        "lldb_context": lldb_context,
        "mergable_xcode_library_targets": mergable_xcode_library_targets,
        "non_top_level_rule_kind": non_top_level_rule_kind,
        "outputs": outputs,
        "potential_target_merges": potential_target_merges,
        "replacement_labels": replacement_labels,
        "resource_bundle_ids": resource_bundle_ids,
        "target_type": target_type,
        "transitive_dependencies": transitive_dependencies,
        "xcode_required_targets": xcode_required_targets,
        "xcode_target": xcode_target,
        "xcode_targets": xcode_targets,
    }

def _make_skipped_target_xcodeprojinfo(
        *,
        ctx,
        automatic_target_info,
        build_mode,
        deps,
        deps_attrs,
        rule_attr,
        target,
        target_skip_type,
        transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        ctx: The aspect context.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        build_mode: See `xcodeproj.build_mode`.
        deps: `Target`s collected from `ctx.attr.deps`.
        deps_attrs: A sequence of attribute names to collect `Target`s from for
            `deps`-like attributes.
        rule_attr: `ctx.rule.attr`.
        target_skip_type: The `_SKIP_TYPE` for `target`
            (see `_get_skip_type`).
        target: The `Target` to skip.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of the target.

    Returns:
        The return value of `_target_info_fields`, with values merged from
        `transitive_infos`.
    """
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

    valid_transitive_infos = [
        info
        for _, info in transitive_infos
    ]

    direct_dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = valid_transitive_infos,
    )

    provider_outputs = output_files.merge(
        transitive_infos = valid_transitive_infos,
    )

    deps_transitive_infos = [
        info
        for attr, info in transitive_infos
        if attr in deps_attrs and info.xcode_target
    ]

    def _target_replacement_label(info):
        if not info.xcode_target:
            return target.label
        if target_skip_type != _SKIP_TYPE.apple_test_bundle:
            return target.label

        # Normalizes label to ensure this works with and without bzlmod
        # and then drop the target name because that will be replaced below
        label_str = bazel_labels.normalize_label(info.xcode_target.label)
        package_label_str = label_str.split(":")[0]

        # Important notes:
        #
        # 1. This relies on implementation details of
        # https://github.com/bazelbuild/rules_apple/blob/master/apple/internal/testing/apple_test_assembler.bzl#L100-L125
        # 2. Since `target_skip_type` is `_SKIP_TYPE.apple_test_bundle`
        # we can assume that `runner` is present as it's a required attribute
        # 3. The `.replace` below is safe even if `runner` is the
        # default runner `ios_default_runner` since it's a no-op in that case.
        #
        # Removes `runner` from `target.label.name` to create a replacement
        # label that works in all scenarios. For context, this is why
        # other approaches won't work:
        #
        # 1. Simply use `target.label.name`
        #
        # As of https://github.com/bazelbuild/rules_apple/pull/1948
        # `bundle_name` can be used to name the bundle instead of the
        # target name and `bundle_name` is not accesible in this context.
        #
        # 2. Use `ctx.rule.attr.generator_name`
        #
        # In many scenarios `generator_name` would be enough since it holds the
        # name of the test rule generating it but if the test
        # targets are wrapped in macros then `generator_name` can be anything
        #
        # Example:
        #
        # `iOSAppObjCUnitTestSuite_iPhone-13-Pro__16.2` => `iOSAppObjCUnitTestSuite`
        #
        runner_label_name = rule_attr.runner.label.name
        label_name = target.label.name.replace("_{}".format(runner_label_name), "")

        return Label(
            "{}:{}".format(package_label_str, label_name),
        )

    if automatic_target_info.env:
        direct_envs = []
        for info in deps_transitive_infos:
            info_env = getattr(rule_attr, automatic_target_info.env, {})
            info_env = {
                k: ctx.expand_make_variables("env", v, {})
                for k, v in info_env.items()
            }
            env = dicts.add(info_env, ctx.configuration.test_env)
            direct_envs.append(struct(id = info.xcode_target.id, env = struct(**env)))
    else:
        direct_envs = None

    return _target_info_fields(
        args = memory_efficient_depset(
            [
                struct(
                    id = info.xcode_target.id,
                    args = (
                        getattr(rule_attr, automatic_target_info.args, [])
                    ),
                )
                for info in deps_transitive_infos
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
        hosted_targets = memory_efficient_depset(
            transitive = [
                info.hosted_targets
                for info in valid_transitive_infos
            ],
        ),
        inputs = input_files.merge(
            transitive_infos = valid_transitive_infos,
        ),
        lldb_context = lldb_contexts.collect(
            build_mode = build_mode,
            id = None,
            is_swift = False,
            transitive_infos = valid_transitive_infos,
        ),
        mergable_xcode_library_targets = memory_efficient_depset(
            transitive = [
                info.mergable_xcode_library_targets
                for info in valid_transitive_infos
            ],
        ),
        non_top_level_rule_kind = None,
        outputs = provider_outputs,
        potential_target_merges = memory_efficient_depset(
            transitive = [
                info.potential_target_merges
                for info in valid_transitive_infos
            ],
        ),
        replacement_labels = memory_efficient_depset(
            [
                struct(
                    id = info.xcode_target.id,
                    label = _target_replacement_label(info),
                )
                for info in deps_transitive_infos
            ],
            transitive = [
                info.replacement_labels
                for info in valid_transitive_infos
            ],
        ),
        resource_bundle_ids = memory_efficient_depset(
            transitive = [
                info.resource_bundle_ids
                for info in valid_transitive_infos
            ],
        ),
        target_type = target_type.compile,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
        xcode_targets = memory_efficient_depset(
            transitive = [
                info.xcode_targets
                for info in valid_transitive_infos
            ],
        ),
        xcode_required_targets = memory_efficient_depset(
            transitive = [
                info.xcode_required_targets
                for info in valid_transitive_infos
            ],
        ),
    )

def _make_non_skipped_target_xcodeprojinfo(
        *,
        ctx,
        attrs,
        automatic_target_info,
        build_mode,
        rule_attr,
        rule_kind,
        target,
        transitive_infos):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        build_mode: See `xcodeproj.build_mode`.
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
        target: The `Target` to process.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
    if not _should_create_provider(rule_kind = rule_kind, target = target):
        return None

    valid_transitive_infos = [
        info
        for attr, info in transitive_infos
        if (info.target_type in automatic_target_info.xcode_targets.get(
            attr,
            NONE_LIST,
        ))
    ]

    if not automatic_target_info.is_supported:
        processed_target = unsupported_targets.process(
            ctx = ctx,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            rule_attr = rule_attr,
            transitive_infos = valid_transitive_infos,
        )
    elif automatic_target_info.is_top_level:
        processed_target = top_level_targets.process(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            bundle_info = (
                target[AppleBundleInfo] if AppleBundleInfo in target else None
            ),
            rule_attr = rule_attr,
            transitive_infos = valid_transitive_infos,
        )
    else:
        processed_target = library_targets.process(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            rule_attr = rule_attr,
            transitive_infos = valid_transitive_infos,
        )

    if automatic_target_info.is_top_level:
        mergable_xcode_library_targets = EMPTY_DEPSET
    elif processed_target.xcode_target:
        mergable_xcode_library_targets = depset(
            [processed_target.xcode_target.id],
        )
    else:
        mergable_xcode_library_targets = memory_efficient_depset(
            transitive = [
                info.mergable_xcode_library_targets
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
        hosted_targets = memory_efficient_depset(
            processed_target.hosted_targets,
            transitive = [
                info.hosted_targets
                for info in valid_transitive_infos
            ],
        ),
        inputs = processed_target.inputs,
        lldb_context = processed_target.lldb_context,
        mergable_xcode_library_targets = mergable_xcode_library_targets,
        non_top_level_rule_kind = (
            None if processed_target.is_top_level else rule_kind
        ),
        outputs = processed_target.outputs,
        potential_target_merges = memory_efficient_depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges
                for info in valid_transitive_infos
            ],
        ),
        replacement_labels = memory_efficient_depset(
            transitive = [
                info.replacement_labels
                for _, info in transitive_infos
            ],
        ),
        resource_bundle_ids = memory_efficient_depset(
            processed_target.resource_bundle_ids,
            transitive = [
                info.resource_bundle_ids
                for info in valid_transitive_infos
            ],
        ),
        target_type = automatic_target_info.target_type,
        transitive_dependencies = processed_target.transitive_dependencies,
        xcode_target = processed_target.xcode_target,
        xcode_targets = memory_efficient_depset(
            processed_target.xcode_targets,
            transitive = [
                info.xcode_targets
                for info in valid_transitive_infos
            ],
        ),
        xcode_required_targets = memory_efficient_depset(
            processed_target.xcode_targets if processed_target.is_xcode_required else None,
            transitive = [
                info.xcode_required_targets
                for info in valid_transitive_infos
            ],
        ),
    )

# API

def _make_xcodeprojinfo(
        *,
        ctx,
        attrs,
        build_mode,
        rule_attr,
        rule_kind,
        target,
        transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        build_mode: See `xcodeproj.build_mode`.
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
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
            build_mode = build_mode,
            deps = [
                dep
                for attr in automatic_target_info.deps
                for dep in getattr(rule_attr, attr, [])
            ],
            deps_attrs = automatic_target_info.deps,
            rule_attr = rule_attr,
            target = target,
            target_skip_type = target_skip_type,
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _make_non_skipped_target_xcodeprojinfo(
            ctx = ctx,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            build_mode = build_mode,
            rule_attr = rule_attr,
            rule_kind = rule_kind,
            target = target,
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

legacy_xcodeprojinfos = struct(
    make = _make_xcodeprojinfo,
)

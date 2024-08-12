"""Functions for processing non-Xcode targets."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
)
load("//xcodeproj/internal:compilation_providers.bzl", "compilation_providers")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:dependencies.bzl", "dependencies")
load("//xcodeproj/internal:memory_efficiency.bzl", "memory_efficient_depset")
load("//xcodeproj/internal:target_id.bzl", "get_id")
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
    ":incremental_processed_targets.bzl",
    processed_targets = "incremental_processed_targets",
)

def _process_incremental_unsupported_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        is_focused,
        rule_attr,
        transitive_infos):
    """Gathers information about a non-Xcode target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        is_focused: Whether an Xcode target should be generated for this target,
            if it's a resource bundle target, or if extra files should be
            included in the project.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A value from `processed_target`.
    """
    label = automatic_target_info.label

    direct_dependencies, transitive_dependencies = dependencies.collect(
        transitive_infos = transitive_infos,
    )

    # FIXME: See if we even need PRODUCT_BUNDLE_IDENTIFIER (especially with only BwB mode)
    if (is_focused and
        AppleResourceBundleInfo in target and
        automatic_target_info.bundle_id):
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        is_resource_bundle = True
        resource_bundle_ids = [
            (
                get_id(
                    label = label,
                    configuration = calculate_configuration(
                        bin_dir_path = ctx.bin_dir.path,
                    ),
                ),
                getattr(rule_attr, automatic_target_info.bundle_id),
            ),
        ]
    else:
        is_resource_bundle = False
        resource_bundle_ids = None

    (
        _,
        provider_compilation_providers,
    ) = compilation_providers.collect(
        cc_info = target[CcInfo] if CcInfo in target else None,
        objc = target[apple_common.Objc] if apple_common.Objc in target else None,
    )

    if automatic_target_info.is_header_only_library:
        mergeable_infos = depset(
            [
                # We still set a value to prevent unfocused targets from
                # changing which targets _could_ merge. This is filtered out
                # in `top_level_targets.bzl`.
                struct(
                    id = None,
                    premerged_info = None,
                    swiftmodule = False,
                ),
            ],
        )
    else:
        mergeable_infos = memory_efficient_depset(
            transitive = [
                info.mergeable_infos
                for info in transitive_infos
            ],
        )

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        inputs = input_files.collect_unsupported(
            ctx = ctx,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            include_extra_files = is_focused,
            is_resource_bundle = is_resource_bundle,
            label = label,
            rule_attr = rule_attr,
            transitive_infos = transitive_infos,
        ),
        mergeable_infos = mergeable_infos,
        outputs = output_files.merge(transitive_infos = transitive_infos),
        resource_bundle_ids = resource_bundle_ids,
        swift_debug_settings = memory_efficient_depset(
            transitive = [
                info.swift_debug_settings
                for info in transitive_infos
            ],
            order = "topological",
        ),
        target_output_groups = output_groups.merge(
            transitive_infos = transitive_infos,
        ),
        top_level_swift_debug_settings = memory_efficient_depset(
            transitive = [
                info.top_level_swift_debug_settings
                for info in transitive_infos
            ],
        ),
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )

incremental_unsupported_targets = struct(
    process = _process_incremental_unsupported_target,
)

"""Functions for processing non-Xcode targets."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
)
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:memory_efficiency.bzl", "memory_efficient_depset")
load("//xcodeproj/internal:target_id.bzl", "get_id")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":input_files.bzl", "input_files", bwx_ogroups = "bwx_output_groups")
load(":output_files.bzl", "output_files", bwb_ogroups = "bwb_output_groups")
load(":processed_target.bzl", "processed_target")
load(
    ":target_properties.bzl",
    "process_dependencies",
)

def process_unsupported_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        is_focused,
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
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    build_mode = ctx.attr._build_mode

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
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
                    label = automatic_target_info.label,
                    configuration = calculate_configuration(
                        bin_dir_path = ctx.bin_dir.path,
                    ),
                ),
                getattr(
                    ctx.rule.attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ]
    else:
        is_resource_bundle = False
        resource_bundle_ids = None

    return processed_target(
        bwb_output_groups = bwb_ogroups.merge(
            transitive_infos = transitive_infos,
        ),
        bwx_output_groups = bwx_ogroups.merge(
            transitive_infos = transitive_infos,
        ),
        compilation_providers = comp_providers.collect(
            cc_info = target[CcInfo] if CcInfo in target else None,
            objc = target[apple_common.Objc] if apple_common.Objc in target else None,
        ),
        dependencies = dependencies,
        inputs = input_files.collect_unsupported(
            ctx = ctx,
            build_mode = build_mode,
            target = target,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            include_extra_files = is_focused,
            is_resource_bundle = is_resource_bundle,
            transitive_infos = transitive_infos,
        ),
        mergeable_infos = memory_efficient_depset(
            transitive = [
                info.mergeable_infos
                for info in transitive_infos
            ],
        ),
        outputs = output_files.merge(transitive_infos = transitive_infos),
        resource_bundle_ids = resource_bundle_ids,
        swift_debug_settings = memory_efficient_depset(
            transitive = [
                info.swift_debug_settings
                for info in transitive_infos
            ],
            order = "topological",
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

""" Functions for processing non-Xcode targets """

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load(":configuration.bzl", "get_configuration")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "create_opts_search_paths")
load(":output_files.bzl", "output_files")
load(":providers.bzl", "XcodeProjAutomaticTargetProcessingInfo")
load(":processed_target.bzl", "processed_target")
load(":search_paths.bzl", "process_search_paths")
load(":target_id.bzl", "get_id")
load(":target_properties.bzl", "process_dependencies")

def process_non_xcode_target(*, ctx, target, transitive_infos):
    """Gathers information about a non-Xcode target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    cc_info = target[CcInfo] if CcInfo in target else None
    objc = target[apple_common.Objc] if apple_common.Objc in target else None

    automatic_target_info = target[XcodeProjAutomaticTargetProcessingInfo]

    if AppleResourceBundleInfo in target and AppleResourceInfo not in target:
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        resource_bundle_informations = [
            struct(
                id = get_id(
                    label = target.label,
                    configuration = get_configuration(ctx),
                ),
                bundle_id = getattr(
                    ctx.rule.attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ]
    else:
        resource_bundle_informations = None

    return processed_target(
        automatic_target_info = automatic_target_info,
        dependencies = process_dependencies(
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.collect(
            ctx = ctx,
            target = target,
            platform = None,
            bundle_resources = False,
            is_bundle = False,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
            avoid_deps = [],
        ),
        linker_inputs = linker_input_files.collect_for_non_top_level(
            cc_info = cc_info,
            objc = objc,
            is_xcode_target = False,
        ),
        outputs = output_files.merge(
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        resource_bundle_informations = resource_bundle_informations,
        search_paths = process_search_paths(
            cc_info = cc_info,
            objc = objc,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
                system_includes = [],
            ),
        ),
        target = None,
        xcode_target = None,
    )

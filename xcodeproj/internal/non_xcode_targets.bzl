""" Functions for processing non-Xcode targets """

load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "create_opts_search_paths")
load(":output_files.bzl", "output_files")
load(
    ":providers.bzl",
    "InputFileAttributesInfo",
)
load(
    ":processed_target.bzl",
    "processed_target",
)
load(":resource_bundle_products.bzl", "resource_bundle_products")
load(":search_paths.bzl", "process_search_paths")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "should_bundle_resources",
)

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

    attrs_info = target[InputFileAttributesInfo]
    bundle_resources = should_bundle_resources(ctx = ctx)
    resource_owner = None

    return processed_target(
        attrs_info = attrs_info,
        dependencies = process_dependencies(
            attrs_info = attrs_info,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.collect(
            ctx = ctx,
            target = target,
            bundle_resources = bundle_resources,
            attrs_info = attrs_info,
            owner = resource_owner,
            transitive_infos = transitive_infos,
        ),
        linker_inputs = linker_input_files.collect_for_non_top_level(
            cc_info = cc_info,
            objc = objc,
            is_xcode_target = False,
        ),
        outputs = output_files.merge(
            attrs_info = attrs_info,
            transitive_infos = transitive_infos,
        ),
        potential_target_merges = None,
        required_links = None,
        resource_bundles = resource_bundle_products.collect(
            owner = resource_owner,
            is_consuming_bundle = False,
            bundle_resources = bundle_resources,
            attrs_info = attrs_info,
            transitive_infos = transitive_infos,
        ),
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

""" Functions for handling resource targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "parsed_file_path")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "create_opts_search_paths")
load(":output_files.bzl", "output_files")
load(":processed_target.bzl", "processed_target", "xcode_target")
load(":providers.bzl", "XcodeProjAutomaticTargetProcessingInfo")
load(":product.bzl", "process_product")
load(":search_paths.bzl", "process_search_paths")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
)

def _process_resource_bundle(bundle, *, information):
    name = bundle.name
    id = bundle.id

    build_settings = {}

    set_if_true(
        build_settings,
        "PRODUCT_BUNDLE_IDENTIFIER",
        information.bundle_id,
    )

    package_bin_dir = bundle.package_bin_dir
    bundle_file_path = parsed_file_path(paths.join(
        package_bin_dir,
        "{}.bundle".format(name),
    ))

    linker_inputs = linker_input_files.collect_for_non_top_level(
        cc_info = None,
        objc = None,
        is_xcode_target = True,
    )

    product = process_product(
        target = None,
        product_name = name,
        product_type = "com.apple.product-type.bundle",
        bundle_file_path = bundle_file_path,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    outputs = output_files.collect(
        target_files = [],
        bundle_info = None,
        default_info = None,
        swift_info = None,
        id = id,
        transitive_infos = [],
        should_produce_dto = False,
    )

    return xcode_target(
        id = id,
        name = name,
        label = bundle.label,
        configuration = bundle.configuration,
        package_bin_dir = package_bin_dir,
        platform = bundle.platform,
        product = product,
        is_swift = False,
        test_host = None,
        build_settings = build_settings,
        search_paths = {},
        modulemaps = process_modulemaps(swift_info = None),
        swiftmodules = process_swiftmodules(swift_info = None),
        inputs = input_files.from_resource_bundle(bundle),
        linker_inputs = linker_inputs,
        info_plist = None,
        dependencies = bundle.dependencies,
        outputs = outputs,
    )

def process_resource_bundles(bundles, *, resource_bundle_informations):
    """Turns a `list` of resource bundles into `xcode_target` `struct`s.

    Args:
        bundles: A list of resource bundle `struct`s, as returned from
            `collect_resources`.
        resource_bundle_informations: A list of `struct`s, as set in
            `process_resource_target`.

    Returns:
        A list of `xcode_target` `struct`s.
    """
    if not bundles:
        return None

    informations = {}
    for information in resource_bundle_informations:
        informations[information.id] = information

    return [
        _process_resource_bundle(
            bundle = bundle,
            information = informations[bundle.id],
        )
        for bundle in bundles
    ]

def process_resource_target(*, ctx, target, transitive_infos):
    """Gathers information about a resource target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)

    automatic_target_info = target[XcodeProjAutomaticTargetProcessingInfo]

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
            cc_info = None,
            objc = None,
            is_xcode_target = False,
        ),
        outputs = output_files.merge(
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        resource_bundle_informations = [
            struct(
                id = id,
                bundle_id = getattr(
                    ctx.rule.attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ],
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
        xcode_target = None,
    )

""" Functions for handling resource targets. """

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true")
load(":configuration.bzl", "get_configuration")
load(
    ":files.bzl",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "create_opts_search_paths")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(
    ":providers.bzl",
    "InputFileAttributesInfo",
)
load(
    ":processed_target.bzl",
    "processed_target",
    "xcode_target",
)
load(":product.bzl", "process_product")
load(":resource_bundle_products.bzl", "resource_bundle_products")
load(":search_paths.bzl", "process_search_paths")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
    "should_bundle_resources",
    "should_include_outputs",
)

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
    attrs_info = target[InputFileAttributesInfo]

    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)

    build_settings = {}

    set_if_true(
        build_settings,
        "PRODUCT_BUNDLE_IDENTIFIER",
        ctx.rule.attr.bundle_id,
    )

    # TODO: Set Info.plist if one is set
    build_settings["GENERATE_INFOPLIST_FILE"] = True

    bundle_name = ctx.rule.attr.bundle_name or ctx.rule.attr.name
    product_name = bundle_name
    dependencies = process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    bundle_file_path = parsed_file_path(paths.join(
        package_bin_dir,
        "{}.bundle".format(bundle_name),
    ))

    linker_inputs = linker_input_files.collect_for_non_top_level(
        cc_info = None,
        objc = None,
        is_xcode_target = True,
    )

    platform = platform_info.collect(
        ctx = ctx,
        minimum_deployment_os_version = None,
    )
    product = process_product(
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.bundle",
        bundle_file_path = bundle_file_path,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    bundle_resources = should_bundle_resources(ctx = ctx)

    resource_owner = str(label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        bundle_resources = bundle_resources,
        attrs_info = attrs_info,
        owner = resource_owner,
        transitive_infos = transitive_infos,
    )
    outputs = output_files.collect(
        target_files = [],
        bundle_info = None,
        default_info = target[DefaultInfo],
        swift_info = None,
        id = id,
        transitive_infos = transitive_infos,
        should_produce_dto = should_include_outputs(ctx = ctx),
    )

    resource_bundles = resource_bundle_products.collect(
        bundle_file_path = bundle_file_path,
        owner = resource_owner,
        is_consuming_bundle = False,
        bundle_resources = bundle_resources,
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    search_paths = process_search_paths(
        cc_info = None,
        objc = None,
        opts_search_paths = create_opts_search_paths(
            quote_includes = [],
            includes = [],
            system_includes = [],
        ),
    )

    if bundle_resources:
        target = struct(
            id = id,
            label = label,
            is_bundle = True,
            product_path = product.path,
        )
        xctarget = xcode_target(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            is_bundle = True,
            is_swift = False,
            test_host = None,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = process_modulemaps(swift_info = None),
            swiftmodules = process_swiftmodules(swift_info = None),
            resource_bundles = resource_bundles,
            inputs = inputs,
            linker_inputs = linker_inputs,
            info_plist = None,
            dependencies = dependencies,
            outputs = outputs,
        )
    else:
        target = None
        xctarget = None

    return processed_target(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        outputs = outputs,
        potential_target_merges = None,
        required_links = None,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        target = target,
        xcode_target = xctarget,
    )

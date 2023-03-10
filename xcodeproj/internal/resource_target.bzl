""" Functions for handling resource targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true")
load(":files.bzl", "parsed_file_path")
load(":input_files.bzl", "input_files")
load(":output_files.bzl", "output_files")
load(":product.bzl", "process_product")
load(
    ":target_properties.bzl",
    "process_modulemaps",
)
load(":xcode_targets.bzl", "xcode_targets")

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
    bundle_path = paths.join(package_bin_dir, "{}.bundle".format(name))
    bundle_file_path = parsed_file_path(bundle_path)

    product = process_product(
        ctx = None,
        target = None,
        product_name = name,
        product_type = "com.apple.product-type.bundle",
        is_resource_bundle = True,
        bundle_file = None,
        bundle_path = bundle_path,
        bundle_file_path = bundle_file_path,
        linker_inputs = None,
    )

    outputs = output_files.collect(
        ctx = None,
        debug_outputs = None,
        id = id,
        output_group_info = None,
        swift_info = None,
        transitive_infos = [],
        should_produce_dto = False,
        should_produce_output_groups = False,
    )

    return xcode_targets.make(
        id = id,
        label = bundle.label,
        configuration = bundle.configuration,
        package_bin_dir = package_bin_dir,
        platform = bundle.platform,
        product = product,
        is_swift = False,
        build_settings = build_settings,
        modulemaps = process_modulemaps(swift_info = None),
        swiftmodules = [],
        inputs = input_files.from_resource_bundle(bundle),
        dependencies = bundle.dependencies,
        transitive_dependencies = bundle.dependencies,
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
        return []

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

""" Functions for handling resource targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true")
load(":files.bzl", "build_setting_path")
load(":input_files.bzl", "input_files")
load(":memory_efficiency.bzl", "EMPTY_LIST")
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

    if bundle.infoplist:
        build_settings["INFOPLIST_FILE"] = build_setting_path(
            file = bundle.infoplist,
        )

    package_bin_dir = bundle.package_bin_dir
    bundle_path = paths.join(package_bin_dir, "{}.bundle".format(name))

    product = process_product(
        ctx = None,
        target = None,
        product_name = name,
        product_type = "com.apple.product-type.bundle",
        # For resource bundles, we want to use the bundle name instead of
        # `module_name`
        module_name_attribute = name,
        is_resource_bundle = True,
        bundle_file = None,
        bundle_path = bundle_path,
        bundle_file_path = bundle_path,
        linker_inputs = None,
    )

    (target_outputs, _) = output_files.collect(
        ctx = None,
        debug_outputs = None,
        id = id,
        output_group_info = None,
        swift_info = None,
        transitive_infos = EMPTY_LIST,
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
        build_settings = build_settings,
        modulemaps = process_modulemaps(swift_info = None),
        swiftmodules = EMPTY_LIST,
        inputs = input_files.from_resource_bundle(bundle),
        dependencies = bundle.dependencies,
        transitive_dependencies = bundle.dependencies,
        outputs = target_outputs,
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

""" Functions for handling resource targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj/internal/files:files.bzl", "build_setting_path")
load(
    "//xcodeproj/internal/files:legacy_input_files.bzl",
    input_files = "legacy_input_files",
)
load(
    "//xcodeproj/internal/files:legacy_output_files.bzl",
    output_files = "legacy_output_files",
)
load(":collections.bzl", "set_if_true")
load(
    ":legacy_target_properties.bzl",
    "process_modulemaps",
)
load(":memory_efficiency.bzl", "EMPTY_LIST")
load(":product.bzl", "process_product")
load(":xcode_targets.bzl", "xcode_targets")

def _process_resource_bundle(bundle, *, bundle_id):
    name = bundle.name
    id = bundle.id

    build_settings = {}

    set_if_true(
        build_settings,
        "PRODUCT_BUNDLE_IDENTIFIER",
        bundle_id,
    )

    if bundle.infoplist:
        build_settings["INFOPLIST_FILE"] = build_setting_path(
            file = bundle.infoplist,
        )

    package_bin_dir = bundle.package_bin_dir
    bundle_path = paths.join(package_bin_dir, "{}.bundle".format(name))

    product = process_product(
        actions = None,
        bin_dir_path = None,
        bundle_file = None,
        bundle_path = bundle_path,
        is_resource_bundle = True,
        linker_inputs = None,
        # For resource bundles, we want to use the bundle name instead of
        # `module_name`
        module_name_attribute = name,
        product_name = name,
        product_type = "com.apple.product-type.bundle",
        target = None,
    )

    (target_outputs, _) = output_files.collect(
        ctx = None,
        debug_outputs = None,
        id = id,
        output_group_info = None,
        rule_attr = None,
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
        direct_dependencies = bundle.dependencies,
        transitive_dependencies = bundle.dependencies,
        outputs = target_outputs,
    )

def process_resource_bundles(bundles, *, resource_bundle_ids):
    """Turns a `list` of resource bundles into `xcode_target` `struct`s.

    Args:
        bundles: A `list` of resource bundle `struct`s, as returned from
            `collect_resources`.
        resource_bundle_ids: A list of `tuples`s mapping target id to bundle id.

    Returns:
        A list of `xcode_target` `struct`s.
    """
    if not bundles:
        return []

    ids = {}
    for target_id, bundle_id in resource_bundle_ids:
        ids[target_id] = bundle_id

    return [
        _process_resource_bundle(
            bundle = bundle,
            bundle_id = ids[bundle.id],
        )
        for bundle in bundles
    ]

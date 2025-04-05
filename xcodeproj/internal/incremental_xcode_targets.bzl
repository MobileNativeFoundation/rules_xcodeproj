"""Module dealing with the `xcode_target` data structure."""

load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_STRING",
    "memory_efficient_depset",
)

_NON_COMPILE_PRODUCT_TYPES = {
    "M": None,  # com.apple.product-type.application.messages
    "c": None,  # com.apple.product-type.application.watchapp2-container
    "w": None,  # com.apple.product-type.application.watchapp2
    # Resource bundle not included, because we don't need to check it
}

# `xcode_target`

def _from_resource_bundle(bundle):
    # We only return a subset of a full `xcode_target` `struct` here, because
    # it's only used in `_collect_files`
    return struct(
        compile_stub_needed = False,
        inputs = struct(
            entitlements = EMPTY_DEPSET,
            extra_file_paths = bundle.resource_file_paths,
            extra_files = bundle.resources,
            extra_generated_file_paths = bundle.generated_resource_file_paths,
            infoplist = None,
            non_arc_srcs = EMPTY_DEPSET,
            srcs = EMPTY_DEPSET,
        ),
        label = None,
    )

def _from_resource_bundles(bundles, *, resource_bundle_ids):
    """Turns a `list` of resource bundles into `xcode_target` `struct`s.

    Args:
        bundles: A `list` of resource bundle `struct`s, as returned from
            `collect_resources`.
        resource_bundle_ids: A `list of ``tuples`s mapping target id to bundle
            id.

    Returns:
        A list of `xcode_target` `struct`s.
    """
    if not bundles:
        return []

    ids = {}
    for target_id, bundle_id in resource_bundle_ids:
        ids[target_id] = bundle_id

    return [
        _from_resource_bundle(bundle)
        for bundle in bundles
        # id not being in `ids` means `is_focused == False`
        if bundle.label and bundle.id in ids
    ]

def _make_incremental_xcode_target(
        *,
        build_settings_file = None,
        bundle_id = None,
        configuration,
        direct_dependencies,
        has_c_params,
        has_cxx_params,
        id,
        inputs,
        is_top_level,
        label,
        link_params = None,
        mergeable_info = None,
        module_name,
        module_name_attribute,
        outputs,
        package_bin_dir,
        platform,
        product,
        test_host = None,
        transitive_dependencies,
        unfocus_if_not_test_host = False,
        watchkit_extension = None,
        linker_inputs_for_libs_search_paths,
        libraries_path_to_link):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        build_settings_file: A `File` containing some build settings for the
            target, or `None`.
        bundle_id: The bundle id of the target, or `None` if the target isn't a
            bundle.
        configuration: The configuration of the `Target`.
        direct_dependencies: A `depset` of `id`s of targets that this target
            directly depends on.
        has_c_params: Whether the target has a `c.params` file.
        has_cxx_params: Whether the target has a `cxx.params` file.
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        inputs: A value from `input_files.{collect,merge}().xcode`.
        is_top_level: Whether the target is a top-level target.
        label: The `Label` of the `Target`.
        link_params: A value from `_create_link_params`, or `None`.
        mergeable_info: A value from `_calculate_mergeable_info`.
        module_name: The derived module name of the target.
        module_name_attribute: The raw value of the `module_name` attribute of
            the target.
        outputs: A value from `output_files.collect`.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: A value from `platforms.collect`.
        product: A value from `process_product`.
        test_host: The target ID of this target's test host, or `None`.
        transitive_dependencies: A `depset` of `id`s of all transitive targets
            that this target depends on.
        unfocus_if_not_test_host: Whether the target should be unfocused if it
            isn't another target's test host.
        watchkit_extension: the target ID of this target's WatchKit extension,
            or `None`.
        linker_inputs_for_libs_search_paths: Used to generated the
            `LIBRARY_SEARCH_PATHS` build setting.
        libraries_path_to_link: A depset of libraries paths to link to the
            target.
    """
    if not is_top_level:
        compile_stub_needed = False
    elif mergeable_info:
        compile_stub_needed = (
            product.type not in _NON_COMPILE_PRODUCT_TYPES and
            not (mergeable_info.srcs or mergeable_info.non_arc_srcs)
        )
        inputs = _merge_xcode_inputs(
            dest_inputs = inputs,
            mergeable_info = mergeable_info,
        )
    else:
        compile_stub_needed = (
            product.type not in _NON_COMPILE_PRODUCT_TYPES and
            not (inputs.srcs or inputs.non_arc_srcs)
        )

    if mergeable_info:
        compile_target_ids = mergeable_info.compile_target_ids
        module_name = mergeable_info.module_name or module_name
    else:
        compile_target_ids = EMPTY_STRING
        module_name = module_name

    return struct(
        build_settings_file = build_settings_file,
        bundle_id = bundle_id,
        compile_stub_needed = compile_stub_needed,
        compile_target_ids = compile_target_ids,
        configuration = configuration,
        direct_dependencies = direct_dependencies,
        has_c_params = has_c_params,
        has_cxx_params = has_cxx_params,
        id = id,
        inputs = inputs,
        label = label,
        link_params = link_params,
        module_name = module_name or EMPTY_STRING,
        module_name_attribute = module_name_attribute or EMPTY_STRING,
        outputs = _to_xcode_target_outputs(outputs),
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product,
        unfocus_if_not_test_host = unfocus_if_not_test_host,
        test_host = test_host,
        watchkit_extension = watchkit_extension,
        transitive_dependencies = transitive_dependencies,
        linker_inputs_for_libs_search_paths = linker_inputs_for_libs_search_paths,
        libraries_path_to_link = libraries_path_to_link,
    )

def _merge_xcode_inputs(*, dest_inputs, mergeable_info):
    return struct(
        extra_file_paths = memory_efficient_depset(
            transitive = [
                dest_inputs.extra_file_paths,
                mergeable_info.extra_file_paths,
            ],
        ),
        extra_files = memory_efficient_depset(
            transitive = [dest_inputs.extra_files, mergeable_info.extra_files],
        ),
        extra_generated_file_paths = dest_inputs.extra_generated_file_paths,
        infoplist = dest_inputs.infoplist,
        non_arc_srcs = mergeable_info.non_arc_srcs,
        srcs = mergeable_info.srcs,
    )

def _to_xcode_target_outputs(outputs):
    direct_outputs = outputs.direct_outputs

    swift_generated_header = None
    if direct_outputs:
        swift = direct_outputs.swift
        if swift:
            if swift.generated_header:
                swift_generated_header = swift.generated_header

    return struct(
        dsym_files = (
            (direct_outputs.dsym_files if direct_outputs else None) or EMPTY_DEPSET
        ),
        products_output_group_name = outputs.products_output_group_name,
        product_path = (
            direct_outputs.product_path if direct_outputs else None
        ),
        swift_generated_header = swift_generated_header,
        transitive_infoplists = outputs.transitive_infoplists,
    )

# Other

def _dicts_from_xcode_configurations(
        *,
        infos_per_xcode_configuration,
        merged_target_ids):
    """Creates `xcode_target`s `dicts` from multiple Xcode configurations.

    Args:
        infos_per_xcode_configuration: A `dict` mapping Xcode configuration
            names to a `list` of `XcodeProjInfo`s.
        merged_target_ids: A `dict` of `tuple`s of destination and source
            `xcode_target.id`s of all targets that have been merged into another
            target.

    Returns:
        A `tuple` with three elements:

        *   A `dict` mapping `xcode_target.id` to `xcode_target`s.
        *   A `dict` mapping `xcode_target.label` to a `dict` mapping
            `xcode_target.id` to `xcode_target`s.
        *   A `dict` mapping `xcode_target.id` to a `list` of Xcode
            configuration names that the target is present in.
    """
    focused_xcode_targets_by_configuration = []
    for xcode_configuration, infos in infos_per_xcode_configuration.items():
        raw_xcode_targets = depset(
            transitive = [info.xcode_targets for info in infos],
        ).to_list()

        # FIXME: See if we can reuse this for pbxpartials?
        # Collect test hosts from focused targets
        test_hosts = {
            t.test_host: None
            for t in raw_xcode_targets
            if t.test_host
        }

        # Remove unfocused potential test hosts
        focused_xcode_targets = []
        for xcode_target in raw_xcode_targets:
            if (xcode_target.unfocus_if_not_test_host and
                xcode_target.id not in test_hosts):
                # Un-merge if top-level becomes unfocused
                merged_target_ids.pop(xcode_target.id, None)
                continue
            focused_xcode_targets.append(xcode_target)

        focused_xcode_targets_by_configuration.append(
            (xcode_configuration, focused_xcode_targets),
        )

    library_merged_target_ids = {
        src: None
        for srcs in merged_target_ids.values()
        for src in srcs
    }

    # We need to collect Info.plist files by label, to fix Xcode not showing
    # the Info pane unless all of the files exist
    additional_outputs = {}
    transitive_infoplists_by_label = {}

    xcode_targets = {}
    xcode_targets_by_label = {}
    xcode_target_configurations = {}
    for t in focused_xcode_targets_by_configuration:
        xcode_configuration, focused_xcode_targets = t

        # Remove merged targets from remaining (focused) targets
        configuration_xcode_targets = {
            xcode_target.id: xcode_target
            for xcode_target in focused_xcode_targets
            if xcode_target.id not in library_merged_target_ids
        }
        xcode_targets.update(configuration_xcode_targets)

        for xcode_target in configuration_xcode_targets.values():
            id = xcode_target.id
            xcode_targets_by_label.setdefault(xcode_target.label, {})[id] = (
                xcode_target
            )
            xcode_target_configurations.setdefault(id, []).append(
                xcode_configuration,
            )

            products_output_group_name = (
                xcode_target.outputs.products_output_group_name
            )
            if not products_output_group_name:
                # Resource bundles don't have the product output group
                continue

            infoplists = xcode_target.outputs.transitive_infoplists
            if infoplists:
                if xcode_target.label in transitive_infoplists_by_label:
                    transitive_infoplists = (
                        transitive_infoplists_by_label[xcode_target.label]
                    )
                else:
                    transitive_infoplists = []
                    transitive_infoplists_by_label[xcode_target.label] = (
                        transitive_infoplists
                    )

                # We rely on the fact that `transitive_infoplists` will be
                # mutated for future xcode_targets with the same label,
                # to prevent having to iterate over all of the targets again
                # to have each target have all of the same-label targets'
                # Info.plist files
                transitive_infoplists.append(infoplists)
                additional_outputs[products_output_group_name] = (
                    transitive_infoplists
                )

    return (
        additional_outputs,
        xcode_targets,
        xcode_targets_by_label,
        xcode_target_configurations,
    )

def _write_swift_debug_settings(
        *,
        actions,
        colorize,
        generator_name,
        infos_per_xcode_configuration,
        install_path,
        tool):
    swift_debug_settings = []
    for xcode_configuration, infos in infos_per_xcode_configuration.items():
        top_level_swift_debug_settings = depset(
            transitive = [
                info.top_level_swift_debug_settings
                for info in infos
            ],
        ).to_list()
        configuration_swift_debug_settings = pbxproj_partials.write_swift_debug_settings(
            actions = actions,
            colorize = colorize,
            generator_name = generator_name,
            install_path = install_path,
            tool = tool,
            top_level_swift_debug_settings = top_level_swift_debug_settings,
            xcode_configuration = xcode_configuration,
        )
        swift_debug_settings.append(configuration_swift_debug_settings)
    return swift_debug_settings

incremental_xcode_targets = struct(
    dicts_from_xcode_configurations = _dicts_from_xcode_configurations,
    from_resource_bundles = _from_resource_bundles,
    make = _make_incremental_xcode_target,
    write_swift_debug_settings = _write_swift_debug_settings,
)

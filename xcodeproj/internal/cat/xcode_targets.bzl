"""Module containing functions dealing with the `xcode_target` data \
structure."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_STRING",
    "EMPTY_TUPLE",
    "FALSE_ARG",
    "TRUE_ARG",
    "memory_efficient_depset",
)
load(":input_files.bzl", "input_files")
load(":product.bzl", "from_resource_bundle")

_NON_COMPILE_PRODUCT_TYPES = {
    "M": None,  # com.apple.product-type.application.messages
    "c": None,  # com.apple.product-type.application.watchapp2-container
    "w": None,  # com.apple.product-type.application.watchapp2
    # Resource bundle not included, because we don't need to check it
}

# `xcode_target`

def _from_resource_bundle(bundle, *, bundle_id):
    return struct(
        build_settings_file = None,
        bundle_id = bundle_id,
        compile_stub_needed = False,
        compile_target_ids = EMPTY_STRING,
        configuration = bundle.configuration,
        dependencies = bundle.dependencies,
        has_c_params = False,
        has_cxx_params = False,
        id = bundle.id,
        inputs = struct(
            entitlements = EMPTY_DEPSET,
            extra_files = EMPTY_DEPSET,
            extra_file_paths = EMPTY_DEPSET,
            folder_resources = bundle.folder_resources,
            non_arc_srcs = EMPTY_DEPSET,
            resources = bundle.resources,
            srcs = EMPTY_DEPSET,
        ),
        label = bundle.label,
        linker_inputs = None,
        merged_product_files = EMPTY_TUPLE,
        module_name = EMPTY_STRING,
        outputs = struct(
            dsym_files = EMPTY_DEPSET,
            linking_output_group_name = None,
            products_output_group_name = None,
            product_path = None,
            swift_generated_header = None,
            transitive_infoplists = EMPTY_DEPSET,
        ),
        package_bin_dir = bundle.package_bin_dir,
        platform = bundle.platform,
        product = from_resource_bundle(bundle),
        remove_if_not_test_host = False,
        test_host = None,
        watchkit_extension = None,
        transitive_dependencies = EMPTY_DEPSET,
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
        _from_resource_bundle(bundle, bundle_id = ids[bundle.id])
        for bundle in bundles
        # id not being in `ids` means `is_focused == False`
        if bundle.label and bundle.id in ids
    ]

def _make_xcode_target(
        *,
        build_settings_file = None,
        bundle_id = None,
        configuration,
        dependencies,
        has_c_params,
        has_cxx_params,
        id,
        inputs = None,
        label,
        library_inputs = None,
        linker_inputs = None,
        mergeable_info = None,
        outputs,
        package_bin_dir,
        platform,
        product,
        remove_if_not_test_host = False,
        test_host = None,
        transitive_dependencies,
        watchkit_extension = None):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        build_settings_file: A `File` containing some build settings for the
            target, or `None`.
        bundle_id: The bundle id of the target, or `None` if the target isn't a
            bundle.
        configuration: The configuration of the `Target`.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        label: The `Label` of the `Target`.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        transitive_dependencies: A `depset` of `id`s of all transitive targets
            that this target depends on.
    """
    if library_inputs:
        inputs = library_inputs
        compile_stub_needed = False
    elif mergeable_info:
        compile_stub_needed = (
            product.type not in _NON_COMPILE_PRODUCT_TYPES and
            not (mergeable_info.srcs or mergeable_info.non_arc_srcs)
        )
        inputs = _merge_xcode_target_inputs(
            dest_inputs = inputs,
            mergeable_info = mergeable_info,
        )
    else:
        compile_stub_needed = (
            product.type not in _NON_COMPILE_PRODUCT_TYPES and
            not (inputs.srcs or inputs.non_arc_srcs)
        )
        inputs = _make_xcode_inputs(inputs)

    if mergeable_info:
        compile_target_ids = mergeable_info.compile_target_ids
        merged_product_files = mergeable_info.product_files
        module_name = mergeable_info.module_name or product.module_name
    else:
        compile_target_ids = EMPTY_STRING
        merged_product_files = EMPTY_TUPLE
        module_name = product.module_name

    return struct(
        build_settings_file = build_settings_file,
        bundle_id = bundle_id,
        compile_stub_needed = compile_stub_needed,
        compile_target_ids = compile_target_ids,
        configuration = configuration,
        dependencies = dependencies,
        has_c_params = has_c_params,
        has_cxx_params = has_cxx_params,
        id = id,
        inputs = inputs,
        label = label,
        linker_inputs = _to_xcode_target_linker_inputs(linker_inputs),
        merged_product_files = merged_product_files,
        # FIXME: Remove module_name from `product` (or just reduce what we store here?)
        module_name = module_name or EMPTY_STRING,
        outputs = _to_xcode_target_outputs(outputs),
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product,
        remove_if_not_test_host = remove_if_not_test_host,
        test_host = test_host,
        watchkit_extension = watchkit_extension,
        transitive_dependencies = transitive_dependencies,
    )

# FIXME: Have `input_files` return this exact struct
def _make_xcode_inputs(inputs):
    return struct(
        extra_files = inputs.extra_files,
        extra_file_paths = inputs.extra_file_paths,
        folder_resources = inputs.folder_resources,
        non_arc_srcs = memory_efficient_depset(inputs.non_arc_srcs),
        resources = inputs.resources,
        srcs = memory_efficient_depset(inputs.srcs),
    )

def _merge_xcode_target_inputs(*, dest_inputs, mergeable_info):
    return struct(
        extra_files = memory_efficient_depset(
            transitive = [mergeable_info.extra_files, dest_inputs.extra_files],
        ),
        extra_file_paths = memory_efficient_depset(
            transitive = [
                mergeable_info.extra_file_paths,
                dest_inputs.extra_file_paths,
            ],
        ),
        folder_resources = dest_inputs.folder_resources,
        non_arc_srcs = mergeable_info.non_arc_srcs,
        resources = dest_inputs.resources,
        srcs = mergeable_info.srcs,
    )

def _to_xcode_target_linker_inputs(linker_inputs):
    if not linker_inputs:
        return None

    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return None

    return struct(
        link_args = top_level_values.link_args,
        link_args_inputs = top_level_values.link_args_inputs,
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
        linking_output_group_name = outputs.linking_output_group_name,
        products_output_group_name = outputs.products_output_group_name,
        product_path = (
            direct_outputs.product_path if direct_outputs else None
        ),
        swift_generated_header = swift_generated_header,
        transitive_infoplists = outputs.transitive_infoplists,
    )

# Other

def _create_single_link_params(
        *,
        actions,
        generator_name,
        link_params_processor,
        params_index,
        xcode_target):
    linker_inputs = xcode_target.linker_inputs

    if not linker_inputs:
        return None

    link_args = linker_inputs.link_args

    if not link_args:
        return None

    name = xcode_target.label.name

    link_params = actions.declare_file(
        "{}-params/{}.{}.link.params".format(
            generator_name,
            name,
            params_index,
        ),
    )

    if xcode_target.merged_product_files:
        self_product_paths = [
            file.path
            for file in xcode_target.merged_product_files
            if file
        ]
    else:
        # Handle `{cc,swift}_{binary,test}` with `srcs` case
        self_product_paths = [
            paths.join(
                xcode_target.product.package_dir,
                "lib{}.lo".format(name),
            ),
        ]

    generated_product_paths_file = actions.declare_file(
        "{}-params/{}.{}.generated_product_paths_file.json".format(
            generator_name,
            name,
            params_index,
        ),
    )
    actions.write(
        output = generated_product_paths_file,
        content = json.encode(self_product_paths),
    )

    is_framework = (
        xcode_target.product.type == "com.apple.product-type.framework"
    )

    args = actions.args()
    args.add(link_params)
    args.add(generated_product_paths_file)
    args.add(TRUE_ARG if is_framework else FALSE_ARG)

    actions.run(
        executable = link_params_processor,
        arguments = [args] + link_args,
        mnemonic = "ProcessLinkParams",
        progress_message = "Generating %{output}",
        inputs = (
            [generated_product_paths_file] +
            list(linker_inputs.link_args_inputs)
        ),
        outputs = [link_params],
    )

    return link_params

def _create_link_params(
        *,
        actions,
        generator_name,
        link_params_processor,
        xcode_targets):
    """Creates the `link_params` for each `xcode_target`.

    Args:
        actions: `ctx.actions`.
        generator_name: The name of the `xcodeproj` generator target.
        link_params_processor: Executable to process the link params.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A `dict` mapping `xcode_target.id` to a `link.params` file for that
        target, if one is needed.
    """
    link_params = {}
    for idx, xcode_target in enumerate(xcode_targets.values()):
        a_link_params = _create_single_link_params(
            actions = actions,
            generator_name = generator_name,
            link_params_processor = link_params_processor,
            params_index = idx,
            xcode_target = xcode_target,
        )
        if a_link_params:
            link_params[xcode_target.id] = a_link_params

    return link_params

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
            if (xcode_target.remove_if_not_test_host and
                xcode_target.id not in test_hosts):
                # Un-merge if top-level becomes unfocused
                merged_target_ids.pop(xcode_target.id, None)
                continue
            focused_xcode_targets.append(xcode_target)

        # FIXME: Find a way to not have to do a wasteful inputs merge
        configuration_inputs = input_files.merge(
            transitive_infos = infos,
        )
        resource_bundle_xcode_targets = _from_resource_bundles(
            bundles = configuration_inputs.resource_bundles.to_list(),
            resource_bundle_ids = depset(
                transitive = [
                    info.resource_bundle_ids
                    for info in infos
                ],
            ).to_list(),
        )

        focused_xcode_targets_by_configuration.append(
            (
                xcode_configuration,
                focused_xcode_targets + resource_bundle_xcode_targets,
            ),
        )

    dest_merged_target_ids = {
        src: None
        for srcs in merged_target_ids.values()
        for src in srcs
    }

    # We need to collect Info.plist files by label, to fix Xcode not showing
    # the Info pane unless all of the files exist
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
            if xcode_target.id not in dest_merged_target_ids
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

            infoplist = xcode_target.outputs.transitive_infoplists
            if infoplist:
                transitive_infoplists_by_label.setdefault(
                    xcode_target.label,
                    [],
                ).append(infoplist)

    return (
        transitive_infoplists_by_label,
        xcode_targets,
        xcode_targets_by_label,
        xcode_target_configurations,
    )

xcode_targets = struct(
    create_link_params = _create_link_params,
    dicts_from_xcode_configurations = _dicts_from_xcode_configurations,
    make = _make_xcode_target,
    make_inputs = _make_xcode_inputs,
)

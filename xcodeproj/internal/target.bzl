"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    ":build_settings.bzl",
    "get_product_module_name",
)
load(":collections.bzl", "set_if_true")
load(":configuration.bzl", "calculate_configuration", "get_configuration")
load(
    ":files.bzl",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "create_opts_search_paths", "process_opts")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "process_platform")
load(
    ":providers.bzl",
    "InputFileAttributesInfo",
    "XcodeProjInfo",
    "target_type",
)
load(
    ":processed_target.bzl",
    "processed_target",
    "xcode_target",
)
load(
    ":product.bzl",
    "process_product",
)
load(":resource_bundle_products.bzl", "resource_bundle_products")
load(":search_paths.bzl", "process_search_paths")
load(":target_id.bzl", "get_id")
load(":targets.bzl", "targets")
load(
    ":target_properties.bzl",
    "process_defines",
    "process_dependencies",
    "process_modulemaps",
    "process_sdk_links",
    "process_swiftmodules",
    "should_bundle_resources",
    "should_include_outputs",
)
load(
    ":top_level_targets.bzl",
    "process_top_level_properties",
    "process_top_level_target",
)

# Library targets

def _process_library_target(*, ctx, target, transitive_infos):
    """Gathers information about a library target.

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

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    opts_search_paths = process_opts(
        ctx = ctx,
        target = target,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )
    product_name = ctx.rule.attr.name
    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        get_product_module_name(ctx = ctx, target = target),
    )
    dependencies = process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    objc = target[apple_common.Objc] if apple_common.Objc in target else None

    linker_inputs = linker_input_files.collect_for_non_top_level(
        cc_info = target[CcInfo],
        objc = objc,
        is_xcode_target = True,
    )

    cpp = ctx.fragments.cpp

    # TODO: Get the value for device builds, even when active config is not for
    # device, as Xcode only uses this value for device builds
    build_settings["ENABLE_BITCODE"] = str(cpp.apple_bitcode_mode) != "none"

    debug_format = "dwarf-with-dsym" if cpp.apple_generate_dsym else "dwarf"
    build_settings["DEBUG_INFORMATION_FORMAT"] = debug_format

    set_if_true(
        build_settings,
        "CLANG_ENABLE_MODULES",
        getattr(ctx.rule.attr, "enable_modules", False),
    )

    set_if_true(
        build_settings,
        "ENABLE_TESTING_SEARCH_PATHS",
        getattr(ctx.rule.attr, "testonly", False),
    )

    build_settings["OTHER_LDFLAGS"] = ["-ObjC"] + build_settings.get(
        "OTHER_LDFLAGS",
        [],
    )

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = None,
        build_settings = build_settings,
    )
    product = process_product(
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.library.static",
        bundle_file_path = None,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    bundle_resources = should_bundle_resources(ctx = ctx)

    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = process_modulemaps(swift_info = swift_info)
    resource_owner = str(target.label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        bundle_resources = bundle_resources,
        attrs_info = attrs_info,
        owner = resource_owner,
        additional_files = modulemaps.files,
        transitive_infos = transitive_infos,
    )
    outputs = output_files.collect(
        target_files = [],
        bundle_info = None,
        default_info = target[DefaultInfo],
        swift_info = swift_info,
        id = id,
        transitive_infos = transitive_infos,
        should_produce_dto = should_include_outputs(ctx = ctx),
    )

    resource_bundles = resource_bundle_products.collect(
        owner = resource_owner,
        is_consuming_bundle = False,
        bundle_resources = bundle_resources,
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    cc_info = target[CcInfo] if CcInfo in target else None
    process_defines(
        cc_info = cc_info,
        build_settings = build_settings,
    )
    process_sdk_links(
        objc = objc,
        build_settings = build_settings,
    )
    search_paths = process_search_paths(
        cc_info = cc_info,
        objc = objc,
        opts_search_paths = opts_search_paths,
    )

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
        target = struct(
            id = id,
            label = label,
            is_bundle = False,
            product_path = product.path,
        ),
        xcode_target = xcode_target(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            is_bundle = False,
            is_swift = is_swift,
            test_host = None,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            swiftmodules = process_swiftmodules(swift_info = swift_info),
            resource_bundles = resource_bundles,
            inputs = inputs,
            linker_inputs = linker_inputs,
            info_plist = None,
            entitlements = None,
            dependencies = dependencies,
            outputs = outputs,
        ),
    )

# Resource targets

def _process_resource_target(*, ctx, target, transitive_infos):
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

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = None,
        build_settings = build_settings,
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
            entitlements = None,
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

# Non-Xcode targets

def _process_non_xcode_target(*, ctx, target, transitive_infos):
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

# Creating `XcodeProjInfo`

def _should_skip_target(*, ctx, target):
    """Determines if the given target should be skipped for target generation.

    There are some rules, like the test runners for iOS tests, that we want to
    ignore. Nothing from those rules are considered.

    Args:
        ctx: The aspect context.
        target: The `Target` to check.

    Returns:
        `True` if `target` should be skipped for target generation.
    """

    # TODO: Find a way to detect TestEnvironment instead
    return targets.is_test_bundle(
        target = target,
        deps = getattr(ctx.rule.attr, "deps", None),
    )

def _target_info_fields(
        *,
        dependencies,
        inputs,
        linker_inputs,
        outputs,
        potential_target_merges,
        required_links,
        resource_bundles,
        search_paths,
        target,
        target_type,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        linker_inputs: Maps to the `XcodeProjInfo.linker_inputs` field.
        outputs: Maps to the `XcodeProjInfo.outputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        required_links: Maps to the `XcodeProjInfo.required_links` field.
        resource_bundles: Maps to the `XcodeProjInfo.resource_bundles` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        target: Maps to the `XcodeProjInfo.target` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `dependencies`
        *   `generated_inputs`
        *   `inputs`
        *   `linker_inputs`
        *   `outputs`
        *   `potential_target_merges`
        *   `required_links`
        *   `resource_bundles`
        *   `search_paths`
        *   `target`
        *   `target_type`
        *   `xcode_targets`
    """
    return {
        "dependencies": dependencies,
        "inputs": inputs,
        "linker_inputs": linker_inputs,
        "outputs": outputs,
        "potential_target_merges": potential_target_merges,
        "required_links": required_links,
        "resource_bundles": resource_bundles,
        "search_paths": search_paths,
        "target": target,
        "target_type": target_type,
        "xcode_targets": xcode_targets,
    }

def _skip_target(*, deps, transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        deps: `ctx.attr.deps` for the target.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of the target.

    Returns:
        The return value of `_target_info_fields`, with values merged from
        `transitive_infos`.
    """
    return _target_info_fields(
        dependencies = process_dependencies(
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.merge(
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
        outputs = output_files.merge(
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
        linker_inputs = linker_input_files.merge(deps = deps),
        potential_target_merges = depset(
            transitive = [
                info.potential_target_merges
                for _, info in transitive_infos
            ],
        ),
        required_links = depset(
            transitive = [info.required_links for _, info in transitive_infos],
        ),
        resource_bundles = resource_bundle_products.collect(
            owner = None,
            is_consuming_bundle = False,
            bundle_resources = False,
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
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
        target_type = target_type.compile,
        xcode_targets = depset(
            transitive = [info.xcode_targets for _, info in transitive_infos],
        ),
    )

def _process_target(*, ctx, target, transitive_infos):
    """Creates the target portion of an `XcodeProjInfo` for a `Target`.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A `dict` of fields to be merged into the `XcodeProjInfo`. See
        `_target_info_fields`.
    """
    if not targets.should_become_xcode_target(target):
        processed_target = _process_non_xcode_target(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )
    elif AppleBundleInfo in target:
        processed_target = process_top_level_target(
            ctx = ctx,
            target = target,
            bundle_info = target[AppleBundleInfo],
            transitive_infos = transitive_infos,
        )
    elif target[DefaultInfo].files_to_run.executable:
        processed_target = process_top_level_target(
            ctx = ctx,
            target = target,
            bundle_info = None,
            transitive_infos = transitive_infos,
        )
    elif AppleResourceBundleInfo in target:
        processed_target = _process_resource_target(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )
    else:
        processed_target = _process_library_target(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )

    return _target_info_fields(
        dependencies = processed_target.dependencies,
        inputs = processed_target.inputs,
        linker_inputs = processed_target.linker_inputs,
        outputs = processed_target.outputs,
        potential_target_merges = depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        required_links = depset(
            processed_target.required_links,
            transitive = [
                info.required_links
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        resource_bundles = processed_target.resource_bundles,
        search_paths = processed_target.search_paths,
        target = processed_target.target,
        target_type = processed_target.attrs_info.target_type,
        xcode_targets = depset(
            processed_target.xcode_targets,
            transitive = [
                info.xcode_targets
                for attr, info in transitive_infos
                if (info.target_type in
                    processed_target.attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
    )

# API

def process_target(*, ctx, target, transitive_infos):
    """Creates an `XcodeProjInfo` for the given target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        An `XcodeProjInfo` populated with information from `target` and
        `transitive_infos`.
    """
    if _should_skip_target(ctx = ctx, target = target):
        info_fields = _skip_target(
            deps = getattr(ctx.rule.attr, "deps", []),
            transitive_infos = transitive_infos,
        )
    else:
        info_fields = _process_target(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )

    return XcodeProjInfo(
        **info_fields
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    calculate_configuration = calculate_configuration,
    process_top_level_properties = process_top_level_properties,
)

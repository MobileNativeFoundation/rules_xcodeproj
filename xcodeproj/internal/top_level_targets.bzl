""" Functions for processing top level targets """

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    ":build_settings.bzl",
    "get_targeted_device_family",
)
load(":collections.bzl", "set_if_true", "uniq")
load("configuration.bzl", "get_configuration")
load(
    ":files.bzl",
    "file_path",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":info_plists.bzl", "info_plists")
load(":entitlements.bzl", "entitlements")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "process_opts")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "process_platform")
load(
    ":providers.bzl",
    "InputFileAttributesInfo",
    "XcodeProjInfo",
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

def process_top_level_properties(
        *,
        target_name,
        files,
        bundle_info,
        tree_artifact_enabled,
        build_settings):
    """ Processes a top level target

    Args:
        target_name: Name of the target
        files: Files for the target
        bundle_info: AppleBundleInfo for the target
        tree_artifact_enabled: Boolean controlling if tree artifacts is enabled
        build_settings: A dictionary of build settings

    Returns:
        A struct of information from the top level target
    """
    if bundle_info:
        product_name = bundle_info.bundle_name
        product_type = bundle_info.product_type
        minimum_deployment_version = bundle_info.minimum_deployment_os_version

        if tree_artifact_enabled:
            bundle_path = file_path(bundle_info.archive)
        else:
            bundle_extension = bundle_info.bundle_extension
            bundle = "{}{}".format(bundle_info.bundle_name, bundle_extension)
            if bundle_extension == ".app":
                bundle_path = parsed_file_path(
                    paths.join(
                        bundle_info.archive_root,
                        "Payload",
                        bundle,
                    ),
                )
            else:
                bundle_path = parsed_file_path(
                    paths.join(bundle_info.archive_root, bundle),
                )

        build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_info.bundle_id
    else:
        product_name = target_name
        minimum_deployment_version = None

        xctest = None
        for file in files:
            if ".xctest/" in file.short_path:
                xctest = file.short_path
                break
        if xctest:
            # This is something like `swift_test`: it creates an xctest bundle
            product_type = "com.apple.product-type.bundle.unit-test"

            # "some/test.xctest/binary" -> "some/test.xctest"
            bundle_path = parsed_file_path(
                xctest[:-(len(xctest.split(".xctest/")[1]) + 1)],
            )
        else:
            product_type = "com.apple.product-type.tool"
            bundle_path = None

    build_settings["PRODUCT_MODULE_NAME"] = "_{}_Stub".format(product_name)

    return struct(
        bundle_path = bundle_path,
        minimum_deployment_os_version = minimum_deployment_version,
        product_name = product_name,
        product_type = product_type,
    )

def _process_test_host(test_host):
    if test_host:
        return test_host[XcodeProjInfo]
    return None

def process_top_level_target(*, ctx, target, bundle_info, transitive_infos):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        bundle_info: The `AppleBundleInfo` provider for `target`, or `None`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    attrs_info = target[InputFileAttributesInfo]

    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)
    dependencies = process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )
    test_host = getattr(ctx.rule.attr, "test_host", None)
    test_host_target_info = _process_test_host(test_host)

    deps = getattr(ctx.rule.attr, "deps", [])
    avoid_deps = [test_host] if test_host else []

    additional_files = []
    is_bundle = bundle_info != None
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = process_modulemaps(swift_info = swift_info)
    additional_files.extend(modulemaps.files)

    info_plist = None
    info_plist_file = info_plists.get_file(target)
    if info_plist_file:
        info_plist = file_path(info_plist_file)
        additional_files.append(info_plist_file)

    entitlements_file_path = None
    entitlements_file = entitlements.get_file(target)
    if entitlements_file:
        entitlements_file_path = file_path(entitlements_file)
        additional_files.append(entitlements_file)

    resource_owner = str(target.label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        attrs_info = attrs_info,
        owner = resource_owner,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
    )
    outputs = output_files.collect(
        bundle_info = bundle_info,
        swift_info = swift_info,
        id = id,
        transitive_infos = transitive_infos,
    )

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

    tree_artifact_enabled = (
        ctx.var.get("apple.experimental.tree_artifact_outputs", "").lower() in
        ("true", "yes", "1")
    )
    props = process_top_level_properties(
        target_name = ctx.rule.attr.name,
        # The common case is to have a `bundle_info`, so this check prevents
        # expanding the `depset` unless needed. Yes, this uses knowledge of what
        # `process_top_level_properties` does internally.
        files = [] if bundle_info else target.files.to_list(),
        bundle_info = bundle_info,
        tree_artifact_enabled = tree_artifact_enabled,
        build_settings = build_settings,
    )

    if (test_host_target_info and
        props.product_type == "com.apple.product-type.bundle.unit-test"):
        avoid_linker_inputs = test_host_target_info.linker_inputs
    else:
        avoid_linker_inputs = None

    linker_inputs = linker_input_files.collect_for_top_level(
        deps = deps,
        avoid_linker_inputs = avoid_linker_inputs,
    )
    xcode_library_targets = linker_inputs.xcode_library_targets

    if len(xcode_library_targets) == 1 and not inputs.srcs:
        mergeable_target = xcode_library_targets[0]
        mergeable_label = mergeable_target.label
        potential_target_merges = [struct(
            src = struct(
                id = mergeable_target.id,
                product_path = mergeable_target.product_path,
            ),
            dest = id,
        )]
    elif bundle_info and len(xcode_library_targets) > 1:
        fail("""\
The xcodeproj rule requires {} rules to have a single library dep. {} has {}.\
""".format(ctx.rule.kind, label, len(xcode_library_targets)))
    else:
        potential_target_merges = None
        mergeable_label = None

    static_libraries = linker_input_files.get_static_libraries(linker_inputs)
    required_links = [
        library
        for library in static_libraries
        if mergeable_label and library.owner != mergeable_label
    ]

    build_settings["OTHER_LDFLAGS"] = ["-ObjC"] + build_settings.get(
        "OTHER_LDFLAGS",
        [],
    )

    set_if_true(
        build_settings,
        "TARGETED_DEVICE_FAMILY",
        get_targeted_device_family(getattr(ctx.rule.attr, "families", [])),
    )

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = props.minimum_deployment_os_version,
        build_settings = build_settings,
    )
    product = process_product(
        target = target,
        product_name = props.product_name,
        product_type = props.product_type,
        bundle_path = props.bundle_path,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    resource_bundles = resource_bundle_products.collect(
        owner = resource_owner,
        is_consuming_bundle = is_bundle,
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    cc_info = target[CcInfo] if CcInfo in target else None
    objc = target[apple_common.Objc] if apple_common.Objc in target else None
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
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = label,
            is_bundle = is_bundle,
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
            is_bundle = is_bundle,
            is_swift = is_swift,
            test_host = (
                test_host_target_info.target.id if test_host_target_info else None
            ),
            avoid_infos = [
                ("test_host", dep[XcodeProjInfo])
                for dep in avoid_deps
            ],
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            swiftmodules = process_swiftmodules(swift_info = swift_info),
            resource_bundles = resource_bundles,
            inputs = inputs,
            linker_inputs = linker_inputs,
            info_plist = info_plist,
            entitlements = entitlements_file_path,
            dependencies = dependencies,
        ),
    )

def process_dependencies(*, attrs_info, transitive_infos):
    """ Logic for processing target dependencies

    Args:
        attrs_info: Attribute information
        transitive_infos: Transitive information of the deps

    Returns:
        A depset of direct and transitive dependencies
    """
    direct_dependencies = []
    transitive_dependencies = []
    for attr, info in transitive_infos:
        if not (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None])):
            continue
        if info.target:
            direct_dependencies.append(info.target.id)
        else:
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            transitive_dependencies.append(info.dependencies)

    return depset(
        direct_dependencies,
        transitive = transitive_dependencies,
    )

def process_modulemaps(*, swift_info):
    """ Logic for working with modulemaps and their paths

    Args:
        swift_info: A SwiftInfo provider

    Returns:
        A struct containing the files and paths of the modules maps of the passed SwiftInfo
    """
    if not swift_info:
        return struct(
            file_paths = [],
            files = [],
        )

    modulemap_file_paths = []
    modulemap_files = []
    for module in swift_info.direct_modules:
        for module_map in module.compilation_context.module_maps:
            if type(module_map) == "File":
                modulemap = file_path(module_map)
                modulemap_files.append(module_map)
            else:
                modulemap = module_map

            modulemap_file_paths.append(modulemap)

    # Different modules might be defined in the same modulemap file, so we need
    # to deduplicate them.
    return struct(
        file_paths = uniq(modulemap_file_paths),
        files = uniq(modulemap_files),
    )

def process_defines(*, cc_info, build_settings):
    """ Logic for processing defines of a module

    Args:
        cc_info: A CcInfo provider object
        build_settings: build settings of the target

    Return:
        The modified build settings object
    """
    if cc_info and build_settings != None:
        # We don't set `SWIFT_ACTIVE_COMPILATION_CONDITIONS` because the way we
        # process Swift compile options already accounts for `defines`

        # Order should be:
        # - toolchain defines
        # - defines
        # - local defines
        # - copt defines
        # but since build_settings["GCC_PREPROCESSOR_DEFINITIONS"] will have
        # "toolchain defines" and "copt defines", those will both be first
        # before "defines" and "local defines". This will only matter if `copts`
        # is used to override `defines` instead of `local_defines`. If that
        # becomes an issue in practice, we can refactor `process_copts` to
        # support this better.

        defines = depset(
            transitive = [
                cc_info.compilation_context.defines,
                cc_info.compilation_context.local_defines,
            ],
        )
        escaped_defines = [
            define.replace("\\", "\\\\").replace('"', '\\"')
            for define in defines.to_list()
        ]

        setting = build_settings.get(
            "GCC_PREPROCESSOR_DEFINITIONS",
            [],
        ) + escaped_defines

        # Remove duplicates
        setting = reversed(uniq(reversed(setting)))

        set_if_true(build_settings, "GCC_PREPROCESSOR_DEFINITIONS", setting)

def process_sdk_links(*, objc, build_settings):
    """ Processing sdk linker options

    Args:
        objc: A ObjC provider
        build_settings: Build settings for the passed target

    Returns:
        The mutated build settings object
    """
    if not objc or build_settings == None:
        return

    sdk_framework_flags = collections.before_each(
        "-framework",
        objc.sdk_framework.to_list(),
    )
    weak_sdk_framework_flags = collections.before_each(
        "-weak_framework",
        objc.weak_sdk_framework.to_list(),
    )
    sdk_dylib_flags = [
        "-l" + dylib
        for dylib in objc.sdk_dylib.to_list()
    ]

    set_if_true(
        build_settings,
        "OTHER_LDFLAGS",
        (sdk_framework_flags +
         weak_sdk_framework_flags +
         sdk_dylib_flags +
         build_settings.get("OTHER_LDFLAGS", [])),
    )

def process_swiftmodules(*, swift_info):
    """ Processs swiftmodules

    Args:
        swift_info: A SwiftInfo provider object

    Returns:
        The filepaths of all direct module swiftmodules
    """
    if not swift_info:
        return []

    swiftmodules = []
    for module in swift_info.direct_modules:
        for swiftmodule in module.compilation_context.swiftmodules:
            swiftmodules.append(file_path(swiftmodule))

    return swiftmodules

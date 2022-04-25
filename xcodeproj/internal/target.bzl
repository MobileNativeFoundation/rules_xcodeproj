"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
    "AppleResourceBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    ":build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
load(":collections.bzl", "set_if_true", "uniq")
load("configuration.bzl", "calculate_configuration", "get_configuration")
load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":info_plists.bzl", "info_plists")
load(":input_files.bzl", "input_files")
load(":opts.bzl", "create_opts_search_paths", "process_opts")
load(":platform.bzl", "process_platform")
load(
    ":providers.bzl",
    "InputFileAttributesInfo",
    "XcodeProjInfo",
    "target_type",
)
load(
    ":product.bzl",
    "get_linker_inputs",
    "get_static_framework_files",
    "get_static_libraries",
    "process_product",
    "product_to_dto",
)
load(":resource_bundle_products.bzl", "resource_bundle_products")
load(":target_id.bzl", "get_id")
load(":targets.bzl", "targets")

# Processed target

def _processed_target(
        *,
        attrs_info,
        dependencies,
        inputs,
        linker_inputs,
        potential_target_merges,
        required_links,
        resource_bundles,
        search_paths,
        static_framework_files,
        target,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        attrs_info: The `InputFileAttributesInfo` for the target.
        dependencies: A `list` of target ids of direct dependencies of this
            target.
        inputs: A value as returned from `input_files.collect` that will
            provide values for the `XcodeProjInfo.inputs` field.
        linker_inputs: A `depset` of `LinkerInput`s for this target.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        required_links: An optional `list` of strings that will be in the
            `XcodeProjInfo.required_links` `depset`.
        resource_bundles: The value returned from
            `resource_bundle_products.collect`.
        search_paths: The value returned from `_process_search_paths`.
        static_framework_files: The value returned from
            `get_static_framework_files`.
        target: An optional `XcodeProjInfo.target` `struct`.
        xcode_target: An optional string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        static_framework_files = static_framework_files,
        target = target,
        target_type = target_type,
        xcode_targets = [xcode_target] if xcode_target else None,
    )

def _xcode_target(
        *,
        id,
        name,
        label,
        configuration,
        package_bin_dir,
        platform,
        product,
        is_bundle,
        is_swift,
        test_host,
        avoid_infos = [],
        build_settings,
        search_paths,
        frameworks,
        modulemaps,
        swiftmodules,
        resource_bundles,
        inputs,
        links,
        info_plist,
        dependencies):
    """Generates the partial json string representation of an Xcode target.

    Args:
        id: A unique identifier. No two `_xcode_target` will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        name: The base name that the Xcode target should use. Multiple
            `_xcode_target`s can have the same name; the generator will
            disambiguate them.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: The value returned from `process_platform`.
        product: The value returned from `process_product`.
        is_bundle: Whether the target is a bundle.
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        avoid_infos: A list of `XcodeProjInfo`s for the targets that have
            already consumed resources, or linked to libraries.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: The value returned from `_process_search_paths`.
        frameworks: The value returned from `_process_frameworks.
        modulemaps: The value returned from `_process_modulemaps`.
        swiftmodules: The value returned from `_process_swiftmodules`.
        resource_bundles: The value returned from
            `resource_bundle_products.collect`.
        inputs: The value returned from `input_files.collect`.
        links: A `list` of file paths for libraries that the target links
            against.
        info_plist: A value as returned by `files.file_path` or `None`.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.

    Returns:
        An element of a json array string. This should be wrapped with `"[{}]"`
        to create a json array string, possibly joining multiples of these
        strings with `","`.
    """
    target = json.encode(struct(
        name = name,
        label = str(label),
        configuration = configuration,
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product_to_dto(product),
        is_swift = is_swift,
        test_host = test_host,
        build_settings = build_settings,
        search_paths = search_paths,
        frameworks = [file_path_to_dto(fp) for fp in frameworks],
        modulemaps = [file_path_to_dto(fp) for fp in modulemaps.file_paths],
        swiftmodules = [file_path_to_dto(fp) for fp in swiftmodules],
        resource_bundles = resource_bundle_products.to_dto(
            resource_bundles,
            avoid_infos = avoid_infos,
        ),
        inputs = input_files.to_dto(
            inputs,
            is_bundle = is_bundle,
            avoid_infos = avoid_infos,
        ),
        links = [file_path_to_dto(fp) for fp in links],
        info_plist = file_path_to_dto(info_plist),
        dependencies = dependencies.to_list(),
    ))

    # Since we use a custom dictionary key type in
    # `//tools/generator/src:DTO.swift`, we need to use alternating keys and
    # values to get the correct dictionary representation.
    return '"{id}",{target}'.format(id = id, target = target)

# Top-level targets

def _process_top_level_properties(
        *,
        target_name,
        files,
        bundle_info,
        tree_artifact_enabled,
        build_settings):
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

def _process_libraries(
        *,
        product_type,
        test_host_libraries,
        links,
        required_links):
    if (test_host_libraries and
        product_type == "com.apple.product-type.bundle.unit-test"):
        # Unit tests have their test host as a bundle loader. So the
        # test host and its dependencies should be removed from the
        # unit test's links.
        avoid_links = [
            file
            for file in test_host_libraries
        ]

        def remove_avoided(links):
            return sets.to_list(
                sets.difference(sets.make(links), sets.make(avoid_links)),
            )

        links = [file for file in remove_avoided(links)]
        required_links = [file for file in remove_avoided(required_links)]

    links = [file_path(file) for file in links]

    return links, required_links

def _process_test_host(test_host):
    if test_host:
        return test_host[XcodeProjInfo]
    return None

def _process_top_level_target(*, ctx, target, bundle_info, transitive_infos):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        bundle_info: The `AppleBundleInfo` provider for `target`, or `None`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `_processed_target`.
    """
    attrs_info = target[InputFileAttributesInfo]

    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)
    dependencies = _process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )
    test_host = getattr(ctx.rule.attr, "test_host", None)

    deps = getattr(ctx.rule.attr, "deps", [])
    avoid_deps = [test_host] if test_host else []

    framework_import_infos = [
        dep[AppleFrameworkImportInfo]
        for dep in deps
        if AppleFrameworkImportInfo in dep
    ]
    avoid_framework_import_infos = [
        dep[AppleFrameworkImportInfo]
        for dep in avoid_deps
        if AppleFrameworkImportInfo in dep
    ]

    library_dep_infos = [
        dep[XcodeProjInfo]
        for dep in deps
        if dep[XcodeProjInfo].target and dep[XcodeProjInfo].linker_inputs
    ]
    library_dep_targets = [
        info.target
        for info in library_dep_infos
    ]

    linker_inputs = depset(
        transitive = [
            dep[XcodeProjInfo].linker_inputs
            for dep in deps
        ],
    )
    static_framework_files = depset(
        transitive = [
            dep[XcodeProjInfo].static_framework_files
            for dep in deps
        ],
    )

    additional_files = []
    is_bundle = bundle_info != None
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = _process_modulemaps(swift_info = swift_info)
    additional_files.extend(modulemaps.files)

    info_plist = None
    info_plist_file = info_plists.get_file(target)
    if info_plist_file:
        info_plist = file_path(info_plist_file)
        additional_files.append(info_plist_file)

    resource_owner = str(target.label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        attrs_info = attrs_info,
        owner = resource_owner,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
    )

    if len(library_dep_targets) == 1 and not inputs.srcs:
        mergeable_target = library_dep_targets[0]
        mergeable_label = mergeable_target.label
        potential_target_merges = [struct(
            src = struct(
                id = mergeable_target.id,
                product_path = mergeable_target.product_path,
            ),
            dest = id,
        )]
    elif bundle_info and len(library_dep_targets) > 1:
        fail("""\
The xcodeproj rule requires {} rules to have a single library dep. {} has {}.\
""".format(ctx.rule.kind, label, len(library_dep_targets)))
    else:
        potential_target_merges = None
        mergeable_label = None

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
    props = _process_top_level_properties(
        target_name = ctx.rule.attr.name,
        # The common case is to have a `bundle_info`, so this check prevents
        # expanding the `depset` unless needed. Yes, this uses knowledge of what
        # `_process_top_level_properties` does internally.
        files = [] if bundle_info else target.files.to_list(),
        bundle_info = bundle_info,
        tree_artifact_enabled = tree_artifact_enabled,
        build_settings = build_settings,
    )

    test_host_target_info = _process_test_host(test_host)

    if test_host_target_info:
        test_host_libraries = get_static_libraries(
            linker_inputs = test_host_target_info.linker_inputs,
            static_framework_files = (
                test_host_target_info.static_framework_files
            ),
        )
    else:
        test_host_libraries = None

    libraries = get_static_libraries(
        linker_inputs = linker_inputs,
        static_framework_files = static_framework_files,
    )
    links, required_links = _process_libraries(
        product_type = props.product_type,
        test_host_libraries = test_host_libraries,
        links = libraries,
        required_links = [
            library
            for library in libraries
            if mergeable_label and library.owner != mergeable_label
        ],
    )

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
    _process_defines(
        cc_info = cc_info,
        build_settings = build_settings,
    )
    _process_sdk_frameworks(
        objc = objc,
        build_settings = build_settings,
    )
    search_paths = _process_search_paths(
        cc_info = cc_info,
        objc = objc,
        opts_search_paths = opts_search_paths,
    )

    return _processed_target(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        static_framework_files = static_framework_files,
        target = struct(
            id = id,
            label = label,
            is_bundle = is_bundle,
            product_path = product.path,
        ),
        xcode_target = _xcode_target(
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
            frameworks = _process_frameworks(
                framework_import_infos = framework_import_infos,
                avoid_framework_import_infos = avoid_framework_import_infos,
            ),
            modulemaps = modulemaps,
            swiftmodules = _process_swiftmodules(swift_info = swift_info),
            resource_bundles = resource_bundles,
            inputs = inputs,
            links = links,
            info_plist = info_plist,
            dependencies = dependencies,
        ),
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
        The value returned from `_processed_target`.
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
    dependencies = _process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )
    linker_inputs = get_linker_inputs(cc_info = target[CcInfo])

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    static_framework_files = get_static_framework_files(objc = objc)

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
        bundle_path = None,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = _process_modulemaps(swift_info = swift_info)
    resource_owner = str(target.label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        attrs_info = attrs_info,
        owner = resource_owner,
        additional_files = modulemaps.files,
        transitive_infos = transitive_infos,
    )

    resource_bundles = resource_bundle_products.collect(
        owner = resource_owner,
        is_consuming_bundle = False,
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    cc_info = target[CcInfo] if CcInfo in target else None
    _process_defines(
        cc_info = cc_info,
        build_settings = build_settings,
    )
    _process_sdk_frameworks(
        objc = objc,
        build_settings = build_settings,
    )
    search_paths = _process_search_paths(
        cc_info = cc_info,
        objc = objc,
        opts_search_paths = opts_search_paths,
    )

    return _processed_target(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = None,
        required_links = None,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        static_framework_files = static_framework_files,
        target = struct(
            id = id,
            label = label,
            is_bundle = False,
            product_path = product.path,
        ),
        xcode_target = _xcode_target(
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
            frameworks = _process_frameworks(framework_import_infos = []),
            modulemaps = modulemaps,
            swiftmodules = _process_swiftmodules(swift_info = swift_info),
            resource_bundles = resource_bundles,
            inputs = inputs,
            links = [],
            info_plist = None,
            dependencies = dependencies,
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
        The value returned from `_processed_target`.
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
    dependencies = _process_dependencies(
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    bundle_path = parsed_file_path(paths.join(
        package_bin_dir,
        "{}.bundle".format(bundle_name),
    ))
    linker_inputs = depset()

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = None,
        build_settings = build_settings,
    )
    product = process_product(
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.bundle",
        bundle_path = bundle_path,
        linker_inputs = linker_inputs,
        build_settings = build_settings,
    )

    resource_owner = str(label)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        attrs_info = attrs_info,
        owner = resource_owner,
        transitive_infos = transitive_infos,
    )

    resource_bundles = resource_bundle_products.collect(
        bundle_path = bundle_path,
        owner = resource_owner,
        is_consuming_bundle = False,
        attrs_info = attrs_info,
        transitive_infos = transitive_infos,
    )

    search_paths = _process_search_paths(
        cc_info = None,
        objc = None,
        opts_search_paths = create_opts_search_paths(
            quote_includes = [],
            includes = [],
            system_includes = [],
        ),
    )

    static_framework_files = depset()

    return _processed_target(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = None,
        required_links = None,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        static_framework_files = static_framework_files,
        target = struct(
            id = id,
            label = label,
            is_bundle = True,
            product_path = product.path,
        ),
        xcode_target = _xcode_target(
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
            frameworks = _process_frameworks(framework_import_infos = []),
            modulemaps = _process_modulemaps(swift_info = None),
            swiftmodules = _process_swiftmodules(swift_info = None),
            resource_bundles = resource_bundles,
            inputs = inputs,
            links = [],
            info_plist = None,
            dependencies = dependencies,
        ),
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
        The value returned from `_processed_target`.
    """
    if CcInfo in target:
        cc_info = target[CcInfo]
        linker_inputs = get_linker_inputs(cc_info = cc_info)
    else:
        cc_info = None
        linker_inputs = depset()

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    static_framework_files = get_static_framework_files(objc = objc)

    attrs_info = target[InputFileAttributesInfo]
    resource_owner = None
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        attrs_info = attrs_info,
        owner = resource_owner,
        transitive_infos = transitive_infos,
    )

    return _processed_target(
        attrs_info = attrs_info,
        dependencies = _process_dependencies(
            attrs_info = attrs_info,
            transitive_infos = transitive_infos,
        ),
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = None,
        required_links = None,
        resource_bundles = resource_bundle_products.collect(
            owner = resource_owner,
            is_consuming_bundle = False,
            attrs_info = attrs_info,
            transitive_infos = transitive_infos,
        ),
        search_paths = _process_search_paths(
            cc_info = cc_info,
            objc = objc,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
                system_includes = [],
            ),
        ),
        static_framework_files = static_framework_files,
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
        potential_target_merges,
        required_links,
        resource_bundles,
        search_paths,
        static_framework_files,
        target,
        target_type,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        linker_inputs: Maps to the `XcodeProjInfo.linker_inputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        required_links: Maps to the `XcodeProjInfo.required_links` field.
        resource_bundles: Maps to the `XcodeProjInfo.resource_bundles` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        static_framework_files: Maps to the
            `XcodeProjInfo.static_framework_files` field.
        target: Maps to the `XcodeProjInfo.target` field.
        target_type: Maps to the `XcodeProjInfo.target_type` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `dependencies`
        *   `generated_inputs`
        *   `inputs`
        *   `linker_inputs`
        *   `potential_target_merges`
        *   `required_links`
        *   `resource_bundles`
        *   `search_paths`
        *   `static_framework_files`
        *   `target`
        *   `target_type`
        *   `xcode_targets`
    """
    return {
        "dependencies": dependencies,
        "inputs": inputs,
        "linker_inputs": linker_inputs,
        "potential_target_merges": potential_target_merges,
        "required_links": required_links,
        "resource_bundles": resource_bundles,
        "search_paths": search_paths,
        "static_framework_files": static_framework_files,
        "target": target,
        "target_type": target_type,
        "xcode_targets": xcode_targets,
    }

def _skip_target(*, target, transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        target: The `Target` to skip.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The return value of `_target_info_fields`, with values merged from
        `transitive_infos`.
    """
    return _target_info_fields(
        dependencies = _process_dependencies(
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.merge(
            attrs_info = target[InputFileAttributesInfo],
            transitive_infos = transitive_infos,
        ),
        linker_inputs = depset(
            transitive = [
                info.linker_inputs
                for _, info in transitive_infos
            ],
        ),
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
            attrs_info = None,
            transitive_infos = transitive_infos,
        ),
        search_paths = _process_search_paths(
            cc_info = None,
            objc = None,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
                system_includes = [],
            ),
        ),
        static_framework_files = depset(
            transitive = [
                info.static_framework_files
                for _, info in transitive_infos
            ],
        ),
        target = None,
        target_type = target_type.compile,
        xcode_targets = depset(
            transitive = [info.xcode_targets for _, info in transitive_infos],
        ),
    )

def _process_dependencies(*, attrs_info, transitive_infos):
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

def _process_defines(*, cc_info, build_settings):
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

def _process_sdk_frameworks(*, objc, build_settings):
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

    set_if_true(
        build_settings,
        "OTHER_LDFLAGS",
        (sdk_framework_flags +
         weak_sdk_framework_flags +
         build_settings.get("OTHER_LDFLAGS", [])),
    )

# TODO: Refactor this into a search_paths module
def _process_search_paths(*, cc_info, objc, opts_search_paths):
    search_paths = {}
    if cc_info:
        compilation_context = cc_info.compilation_context
        set_if_true(
            search_paths,
            "quote_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in compilation_context.quote_includes.to_list() +
                            opts_search_paths.quote_includes
            ],
        )
        set_if_true(
            search_paths,
            "includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.includes.to_list() +
                             opts_search_paths.includes)
            ],
        )
        set_if_true(
            search_paths,
            "system_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.system_includes.to_list() +
                             opts_search_paths.system_includes)
            ],
        )

    if objc:
        framework_paths = depset(
            transitive = [
                objc.static_framework_paths,
                objc.dynamic_framework_paths,
            ],
        )

        set_if_true(
            search_paths,
            "framework_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in framework_paths.to_list()
            ],
        )

    return search_paths

def _farthest_parent_file_path(file, extension):
    """Returns the part of a file path with the given extension closest to the root.

    For example, if `file` is `"foo/bar.bundle/baz.bundle"`, passing `".bundle"`
    as the extension will return `"foo/bar.bundle"`.

    Args:
        file: The `File`.
        extension: The extension of the directory to find.

    Returns:
        A `FilePath` with the portion of the path that ends in the given
        extension that is closest to the root of the path.
    """
    prefix, ext, _ = file.path.partition("." + extension)
    if not ext:
        fail("Expected file.path %r to contain %r, but it did not" % (
            file,
            "." + extension,
        ))

    return file_path(file, prefix + ext)

def _process_frameworks(
        *,
        framework_import_infos,
        avoid_framework_import_infos = []):
    framework_imports = depset(transitive = [
        info.framework_imports
        for info in framework_import_infos
        if hasattr(info, "framework_imports")
    ])
    avoid_framework_imports = depset(transitive = [
        info.framework_imports
        for info in avoid_framework_import_infos
        if hasattr(info, "framework_imports")
    ])
    avoid_files = avoid_framework_imports.to_list()
    framework_paths = uniq([
        _farthest_parent_file_path(file, "framework")
        for file in framework_imports.to_list()
        if file not in avoid_files
    ])

    return framework_paths

def _process_modulemaps(*, swift_info):
    if not swift_info:
        return struct(
            file_paths = [],
            files = [],
        )

    direct_modules = swift_info.direct_modules

    modulemap_file_paths = []
    modulemap_files = []
    for module in swift_info.transitive_modules.to_list():
        if module in direct_modules:
            continue
        clang_module = module.clang
        if not clang_module:
            continue
        module_map = clang_module.module_map
        if not module_map:
            continue

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

def _process_swiftmodules(*, swift_info):
    if not swift_info:
        return []

    direct_modules = swift_info.direct_modules

    file_paths = []
    for module in swift_info.transitive_modules.to_list():
        if module in direct_modules:
            continue
        swift_module = module.swift
        if not swift_module:
            continue
        file_paths.append(file_path(swift_module.swiftmodule))

    return file_paths

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
        processed_target = _process_top_level_target(
            ctx = ctx,
            target = target,
            bundle_info = target[AppleBundleInfo],
            transitive_infos = transitive_infos,
        )
    elif target[DefaultInfo].files_to_run.executable:
        processed_target = _process_top_level_target(
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
        static_framework_files = processed_target.static_framework_files,
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
            target = target,
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
    process_libraries = _process_libraries,
    process_top_level_properties = _process_top_level_properties,
)

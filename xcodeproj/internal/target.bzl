"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
    "IosXcTestBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    ":build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
load(":collections.bzl", "flatten", "set_if_true", "uniq")
load(
    ":files.bzl",
    "file_path",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":input_files.bzl", "input_files")
load(":opts.bzl", "create_opts_search_paths", "process_opts")
load(":platform.bzl", "process_platform")
load(":providers.bzl", "XcodeProjInfo")

# Configuration

def _calculate_configuration(*, bin_dir_path):
    """Calculates a configuration string from `ctx.bin_dir`.

    Args:
        bin_dir_path: `ctx.bin_dir.path`.

    Returns:
        A string that represents a configuration.
    """
    path_components = bin_dir_path.split("/")
    if len(path_components) > 2:
        return path_components[1]
    return ""

def _get_configuration(ctx):
    """Generates a configuration identifier for a target.

    `ConfiguredTarget.getConfigurationKey()` isn't exposed to Starlark, so we
    are using the output directory as a proxy.

    Args:
        ctx: The aspect context.

    Returns:
        A string that uniquely identifies the configuration of a target.
    """
    return _calculate_configuration(bin_dir_path = ctx.bin_dir.path)

# Target ID

def _get_id(*, label, configuration):
    """Generates a unique identifier for a target.

    Args:
        label: The `Label` of the `Target`.
        configuration: The value returned from `_get_configuration()`.

    Returns:
        An opaque string that uniquely identifies the target.
    """
    return "{} {}".format(label, configuration)

# Product

def _get_linker_inputs(*, cc_info):
    return cc_info.linking_context.linker_inputs

def _get_static_libraries(*, linker_inputs):
    return [
        library.static_library
        for library in flatten([
            input.libraries
            for input in linker_inputs.to_list()
        ])
    ]

def _get_static_library(*, linker_inputs):
    for input in linker_inputs.to_list():
        # Ideally we would only return the static library that is owned by this
        # target, but sometimes another rule creates the output and this rule
        # outputs it. So far the first library has always been the correct one.
        return input.libraries[0].static_library.path
    return None

def _process_product(
        *,
        target,
        product_name,
        product_type,
        bundle_path,
        linker_inputs,
        build_settings):
    """Generates information about the target's product.

    Args:
        target: The `Target` the product information is gathered from.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A PBXProductType string. See
            https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
            for examples.
        bundle_path: If the product is a bundle, this is the the path to the
            bundle, otherwise `None`.
        linker_inputs: A `depset` of `LinkerInput`s for this target.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.
    """
    if bundle_path:
        path = bundle_path
    elif target[DefaultInfo].files_to_run.executable:
        path = target[DefaultInfo].files_to_run.executable.path
    elif CcInfo in target or SwiftInfo in target:
        path = _get_static_library(linker_inputs = linker_inputs)
    else:
        path = None

    if not path:
        fail("Could not find product for target {}".format(target.label))

    build_settings["PRODUCT_NAME"] = product_name

    return {
        "name": product_name,
        "path": path,
        "type": product_type,
    }

# Outputs

def _process_outputs(target):
    """Generates information about the target's outputs.

    Args:
        target: The `Target` the output information is gathered from.

    Returns:
        A `dict` containing the targets output information. See `Output` in
        `//tools/generator/src:DTO.swift` for what it transforms into.
    """
    outputs = {}
    if OutputGroupInfo in target:
        if "dsyms" in target[OutputGroupInfo]:
            outputs["dsyms"] = [
                file.path
                for file in target[OutputGroupInfo].dsyms.to_list()
            ]
    if SwiftInfo in target:
        outputs["swift_module"] = _swift_module_output([
            module
            for module in target[SwiftInfo].direct_modules
            if module.swift
        ][0])
    return outputs

def _swift_module_output(module):
    """Generates information about the target's Swift module.

    Args:
        module: The value returned from `swift_common.create_module()`. See
            https://github.com/bazelbuild/rules_swift/blob/master/doc/api.md#swift_commoncreate_module.

    Returns:
        A `dict` containing the Swift module's output information. See
        `Output.SwiftModule` in `//tools/generator/src:DTO.swift` for what it
        transforms into.
    """
    swift = module.swift

    output = {
        "name": module.name + ".swiftmodule",
        "swiftdoc": swift.swiftdoc.path,
        "swiftmodule": swift.swiftmodule.path,
    }
    if swift.swiftsourceinfo:
        output["swiftsourceinfo"] = swift.swiftsourceinfo.path
    if swift.swiftinterface:
        output["swiftinterface"] = swift.swiftinterface.path

    return output

# Processed target

def _processed_target(
        *,
        defines,
        dependencies,
        inputs,
        linker_inputs,
        potential_target_merges,
        required_links,
        search_paths,
        target,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        defines: The value returned from `_process_defines()`.
        dependencies: A `list` of target ids of direct dependencies of this
            target.
        inputs: A value as returned from `input_files.collect()` that will
            provide values for the `XcodeProjInfo.inputs` field.
        linker_inputs: A `depset` of `LinkerInput`s for this target.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        required_links: An optional `list` of strings that will be in the
            `XcodeProjInfo.required_links` `depset`.
        search_paths: The value value returned from `_process_search_paths()`.
        target: An optional `XcodeProjInfo.target` `struct`.
        xcode_target: An optional string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        defines = defines,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        search_paths = search_paths,
        target = target,
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
        is_swift,
        test_host,
        build_settings,
        search_paths,
        frameworks,
        modulemaps,
        swiftmodules,
        inputs,
        links,
        info_plist,
        dependencies,
        outputs):
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
        platform: The value returned from `process_platform()`.
        product: The value returned from `_process_product()`.
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: The value returned from `_process_search_paths()`.
        frameworks: The value returned from `_process_frameworks().
        modulemaps: The value returned from `_process_modulemaps()`.
        swiftmodules: The value returned from `_process_swiftmodules()`.
        inputs: The value returned from `input_files.collect()`.
        links: A `list` of file paths for libraries that the target links
            against.
        info_plist: A value as returned by `files.file_path()` or `None`.
        dependencies: A `list` of `id`s of targets that this target depends on.
        outputs: The value returned from `_process_outputs()`.

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
        product = product,
        is_swift = is_swift,
        test_host = test_host,
        build_settings = build_settings,
        search_paths = search_paths,
        frameworks = frameworks,
        modulemaps = modulemaps.file_paths,
        swiftmodules = swiftmodules,
        inputs = input_files.to_dto(inputs),
        links = links,
        info_plist = info_plist,
        dependencies = dependencies,
        outputs = outputs,
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
            bundle_path = bundle_info.archive.path
        else:
            bundle_extension = bundle_info.bundle_extension
            bundle = "{}{}".format(bundle_info.bundle_name, bundle_extension)
            if bundle_extension == ".app":
                bundle_path = paths.join(
                    bundle_info.archive_root,
                    "Payload",
                    bundle,
                )
            else:
                bundle_path = paths.join(bundle_info.archive_root, bundle)

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
            bundle_path = xctest[:-(len(xctest.split(".xctest/")[1]) + 1)]
        else:
            product_type = "com.apple.product-type.tool"
            bundle_path = None

    build_settings["PRODUCT_MODULE_NAME"] = "_{}_".format(product_name)

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
            file.path
            for file in test_host_libraries
        ]

        def remove_avoided(links):
            return sets.to_list(
                sets.difference(sets.make(links), sets.make(avoid_links)),
            )

        links = [file for file in remove_avoided(links)]
        required_links = [file for file in remove_avoided(required_links)]

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
        The value returned from `_processed_target()`.
    """
    configuration = _get_configuration(ctx)
    label = target.label
    id = _get_id(label = label, configuration = configuration)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        transitive_infos = transitive_infos,
    )
    dependencies = _process_dependencies(transitive_infos = transitive_infos)
    test_host = getattr(ctx.rule.attr, "test_host", None)

    deps = getattr(ctx.rule.attr, "deps", [])

    framework_import_infos = [
        dep[AppleFrameworkImportInfo]
        for dep in deps
        if AppleFrameworkImportInfo in dep
    ]
    avoid_framework_import_infos = [
        dep[AppleFrameworkImportInfo]
        for dep in ([test_host] if test_host else [])
        if AppleFrameworkImportInfo in dep
    ]

    library_dep_targets = [
        dep[XcodeProjInfo].target
        for dep in deps
        if dep[XcodeProjInfo].target and dep[XcodeProjInfo].linker_inputs
    ]

    linker_inputs = depset(
        transitive = [
            dep[XcodeProjInfo].linker_inputs
            for dep in deps
        ],
    )

    if len(library_dep_targets) == 1 and not inputs.srcs:
        mergeable_target = library_dep_targets[0]
        mergeable_label = mergeable_target.label
        potential_target_merges = [
            struct(src = mergeable_target.id, dest = id),
        ]
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
        # `_process_top_level_properties()` does internally.
        files = [] if bundle_info else target.files.to_list(),
        bundle_info = bundle_info,
        tree_artifact_enabled = tree_artifact_enabled,
        build_settings = build_settings,
    )

    test_host_target_info = _process_test_host(test_host)

    if test_host_target_info:
        test_host_libraries = _get_static_libraries(
            linker_inputs = test_host_target_info.linker_inputs,
        )
    else:
        test_host_libraries = None

    libraries = _get_static_libraries(linker_inputs = linker_inputs)
    links, required_links = _process_libraries(
        product_type = props.product_type,
        test_host_libraries = test_host_libraries,
        links = [
            library.path
            for library in libraries
        ],
        required_links = [
            library.path
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

    additional_files = []

    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = _process_modulemaps(swift_info = swift_info)
    additional_files.extend(modulemaps.files)

    info_plist = None
    if bundle_info:
        info_plist = file_path(bundle_info.infoplist)
        additional_files.append(bundle_info.infoplist)

    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
    )
    search_paths = _process_search_paths(
        cc_info = target[CcInfo] if CcInfo in target else None,
        opts_search_paths = opts_search_paths,
    )

    return _processed_target(
        defines = _process_defines(
            is_swift = is_swift,
            defines = getattr(ctx.rule.attr, "defines", []),
            local_defines = getattr(ctx.rule.attr, "local_defines", []),
            transitive_infos = transitive_infos,
            build_settings = build_settings,
        ),
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = label,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = _process_product(
                target = target,
                product_name = props.product_name,
                product_type = props.product_type,
                bundle_path = props.bundle_path,
                linker_inputs = linker_inputs,
                build_settings = build_settings,
            ),
            is_swift = is_swift,
            test_host = (
                test_host_target_info.target.id if test_host_target_info else None
            ),
            build_settings = build_settings,
            search_paths = search_paths,
            frameworks = _process_frameworks(
                framework_import_infos = framework_import_infos,
                avoid_framework_import_infos = avoid_framework_import_infos,
            ),
            modulemaps = modulemaps,
            swiftmodules = _process_swiftmodules(swift_info = swift_info),
            inputs = inputs,
            links = links,
            dependencies = dependencies,
            outputs = _process_outputs(target),
            info_plist = info_plist,
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
        The value returned from `_processed_target()`.
    """
    configuration = _get_configuration(ctx)
    label = target.label
    id = _get_id(label = label, configuration = configuration)

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
    build_settings["PRODUCT_MODULE_NAME"] = get_product_module_name(
        ctx = ctx,
        target = target,
    )
    dependencies = _process_dependencies(transitive_infos = transitive_infos)
    linker_inputs = _get_linker_inputs(cc_info = target[CcInfo])

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

    platform = process_platform(
        ctx = ctx,
        minimum_deployment_os_version = None,
        build_settings = build_settings,
    )

    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None
    modulemaps = _process_modulemaps(swift_info = swift_info)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        additional_files = modulemaps.files,
        transitive_infos = transitive_infos,
    )
    search_paths = _process_search_paths(
        cc_info = target[CcInfo] if CcInfo in target else None,
        opts_search_paths = opts_search_paths,
    )

    return _processed_target(
        defines = _process_defines(
            is_swift = SwiftInfo in target,
            defines = getattr(ctx.rule.attr, "defines", []),
            local_defines = getattr(ctx.rule.attr, "local_defines", []),
            transitive_infos = transitive_infos,
            build_settings = build_settings,
        ),
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = None,
        required_links = None,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = label,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = _process_product(
                target = target,
                product_name = product_name,
                product_type = "com.apple.product-type.library.static",
                bundle_path = None,
                linker_inputs = linker_inputs,
                build_settings = build_settings,
            ),
            is_swift = is_swift,
            test_host = None,
            build_settings = build_settings,
            search_paths = search_paths,
            frameworks = _process_frameworks(framework_import_infos = []),
            modulemaps = modulemaps,
            swiftmodules = _process_swiftmodules(swift_info = swift_info),
            inputs = inputs,
            links = [],
            dependencies = dependencies,
            outputs = _process_outputs(target),
            info_plist = None,
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
        The value returned from `_processed_target()`.
    """
    if CcInfo in target:
        linker_inputs = _get_linker_inputs(cc_info = target[CcInfo])
    else:
        linker_inputs = depset()

    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        transitive_infos = transitive_infos,
    )

    return _processed_target(
        defines = _process_defines(
            is_swift = SwiftInfo in target,
            defines = getattr(ctx.rule.attr, "defines", []),
            local_defines = getattr(ctx.rule.attr, "local_defines", []),
            transitive_infos = transitive_infos,
            build_settings = None,
        ),
        dependencies = _process_dependencies(
            transitive_infos = transitive_infos,
        ),
        inputs = inputs,
        linker_inputs = linker_inputs,
        potential_target_merges = None,
        required_links = None,
        search_paths = _process_search_paths(
            cc_info = target[CcInfo] if CcInfo in target else None,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
            ),
        ),
        target = None,
        xcode_target = None,
    )

# Creating `XcodeProjInfo`

def _should_become_xcode_target(target):
    """Determines if the given target should be included in the Xcode project.

    Args:
        target: The `Target` to check.

    Returns:
        `False` if `target` shouldn't become an actual target in the generated
        Xcode project. Resource bundles are a current example of this, as we
        only include their files in the project, but we don't create targets
        for them.
    """

    # Top-level bundles
    if AppleBundleInfo in target:
        return True

    # Libraries
    # Targets that don't produce files are ignored (e.g. imports)
    if CcInfo in target and target.files != depset():
        return True

    # Command-line tools
    executable = target[DefaultInfo].files_to_run.executable
    if executable and not executable.is_source:
        return True

    return False

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
    return (
        IosXcTestBundleInfo in target and
        len(ctx.rule.attr.deps) == 1 and
        IosXcTestBundleInfo in ctx.rule.attr.deps[0]
    )

def _target_info_fields(
        *,
        defines,
        dependencies,
        inputs,
        linker_inputs,
        potential_target_merges,
        required_links,
        search_paths,
        target,
        xcode_targets):
    """Generates target specific fields for the `XcodeProjInfo`.

    This should be merged with other fields to fully create an `XcodeProjInfo`.

    Args:
        defines: Maps to `XcodeProjInfo.defines`.
        dependencies: Maps to the `XcodeProjInfo.dependencies` field.
        inputs: Maps to the `XcodeProjInfo.inputs` field.
        linker_inputs: Maps to the `XcodeProjInfo.linker_inputs` field.
        potential_target_merges: Maps to the
            `XcodeProjInfo.potential_target_merges` field.
        required_links: Maps to the `XcodeProjInfo.required_links` field.
        search_paths: Maps to the `XcodeProjInfo.search_paths` field.
        target: Maps to the `XcodeProjInfo.target` field.
        xcode_targets: Maps to the `XcodeProjInfo.xcode_targets` field.

    Returns:
        A `dict` containing the following fields:

        *   `defines`
        *   `dependencies`
        *   `extra_files`
        *   `generated_inputs`
        *   `inputs`
        *   `linker_inputs`
        *   `potential_target_merges`
        *   `required_links`
        *   `search_paths`
        *   `target`
        *   `xcode_targets`
    """
    return {
        "defines": defines,
        "dependencies": dependencies,
        "inputs": inputs,
        "linker_inputs": linker_inputs,
        "potential_target_merges": potential_target_merges,
        "required_links": required_links,
        "search_paths": search_paths,
        "target": target,
        "xcode_targets": xcode_targets,
    }

def _skip_target(*, transitive_infos):
    """Passes through existing target info fields, not collecting new ones.

    Merges `XcodeProjInfo`s for the dependencies of the current target, and
    forwards them on, not collecting any information for the current target.

    Args:
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The return value of `_target_info_fields()`, with values merged from
        `transitive_infos`.
    """
    return _target_info_fields(
        defines = _process_defines(
            is_swift = False,
            defines = [],
            local_defines = [],
            transitive_infos = transitive_infos,
            build_settings = None,
        ),
        dependencies = _process_dependencies(
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.merge(
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
        search_paths = _process_search_paths(
            cc_info = None,
            opts_search_paths = create_opts_search_paths(
                quote_includes = [],
                includes = [],
            ),
        ),
        target = None,
        xcode_targets = depset(
            transitive = [info.xcode_targets for _, info in transitive_infos],
        ),
    )

def _process_dependencies(*, transitive_infos):
    return [
        dependency
        for dependency in flatten([
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            [info.target.id] if info.target else info.dependencies
            for _, info in transitive_infos
        ])
    ]

def _process_defines(
        *,
        is_swift,
        defines,
        local_defines,
        transitive_infos,
        build_settings):
    transitive_cc_defines = []
    for _, info in transitive_infos:
        transitive_defines = info.defines
        transitive_cc_defines.extend(transitive_defines.cc_defines)

    # We only want to use this target's defines if it's a Swift target
    if is_swift:
        cc_defines = transitive_cc_defines
    else:
        transitive_cc_defines.extend(defines)
        cc_defines = transitive_cc_defines + local_defines

    if build_settings:
        # We don't set `SWIFT_ACTIVE_COMPILATION_CONDITIONS` because the way we
        # process Swift compile options already accounts for `defines`

        # We need to prepend, in case `process_opts` has already set them
        setting = cc_defines + build_settings.get(
            "GCC_PREPROCESSOR_DEFINITIONS",
            [],
        )

        # Remove duplicates
        setting = reversed(uniq(reversed(setting)))

        set_if_true(build_settings, "GCC_PREPROCESSOR_DEFINITIONS", setting)

    return struct(
        cc_defines = transitive_cc_defines,
    )

def _process_search_paths(
        *,
        cc_info,
        opts_search_paths):
    search_paths = {}
    if cc_info:
        compilation_context = cc_info.compilation_context
        set_if_true(
            search_paths,
            "framework_includes",
            [
                parsed_file_path(path)
                for path in compilation_context.framework_includes.to_list()
            ],
        )
        set_if_true(
            search_paths,
            "quote_includes",
            [
                parsed_file_path(path)
                for path in compilation_context.quote_includes.to_list() +
                            opts_search_paths.quote_includes
            ],
        )
        set_if_true(
            search_paths,
            "includes",
            [
                parsed_file_path(path)
                for path in (compilation_context.includes.to_list() +
                             opts_search_paths.includes)
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
    if ext:
        return file_path(file, prefix + ext)

    fail("Expected file.path %r to contain %r, but it did not" % (
        file,
        "." + extension,
    ))

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

    modulemap_file_paths = []
    modulemap_files = []
    for module in swift_info.transitive_modules.to_list():
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
        `_target_info_fields()`.
    """
    if not _should_become_xcode_target(target):
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
    else:
        processed_target = _process_library_target(
            ctx = ctx,
            target = target,
            transitive_infos = transitive_infos,
        )

    return _target_info_fields(
        defines = processed_target.defines,
        dependencies = processed_target.dependencies,
        inputs = input_files.merge(
            processed_target.inputs,
            transitive_infos = transitive_infos,
        ),
        linker_inputs = processed_target.linker_inputs,
        potential_target_merges = depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges
                for _, info in transitive_infos
            ],
        ),
        required_links = depset(
            processed_target.required_links,
            transitive = [info.required_links for _, info in transitive_infos],
        ),
        search_paths = processed_target.search_paths,
        target = processed_target.target,
        xcode_targets = depset(
            processed_target.xcode_targets,
            transitive = [info.xcode_targets for _, info in transitive_infos],
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
    calculate_configuration = _calculate_configuration,
    process_libraries = _process_libraries,
    process_top_level_properties = _process_top_level_properties,
)

"""Functions for creating `XcodeProjInfo` providers."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "IosXcTestBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    ":build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
    "set_if_true",
)
load(":collections.bzl", "flatten")
load(
    ":files.bzl",
    "external_file_path",
    "file_path",
    "generated_file_path",
    "join_paths_ignoring_empty",
    "project_file_path",
)
load(":input_files_aspect.bzl", "InputFilesInfo")
load(":opts.bzl", "process_opts")
load(":platform.bzl", "process_platform")

XcodeProjInfo = provider(
    "Provides information needed to generate an Xcode project.",
    fields = {
        "defines": """\
A value returned from `_process_defines()` that contains the defines set by
this target that should be propagated to dependent targets.
""",
        "dependencies": """\
A `list` of target ids (see the `target` `struct`) that this target directly
depends on.
""",
        "extra_files": """\
A `depset` of `File`s that should be added to the Xcode project, but not
associated with any targets.
""",
        "generated_inputs": """\
A `depset` of generated `File`s that are used by the Xcode project.
""",
        "linker_inputs": "A `depset` of `LinkerInput`s for this target.",
        "potential_target_merges": """\
A `depset` of structs with 'src' and 'dest' fields. The 'src' field is the id of
the target that can be merged into the target with the id of the 'dest' field.
""",
        "required_links": """\
A `depset` of all static library files that are linked into top-level targets
besides their primary top-level targets.
""",
        "search_paths": """\
A `struct` as returned by `_process_search_paths()` that contains the search
paths needed by this target. These search paths should be added to the search
paths of any target that depends on this target.
""",
        "target": """\
A `struct` that contains information about the current target that is
potentially needed by the dependent targets.
""",
        "xcode_targets": """\
A `depset` of partial json `dict` strings (e.g. a single '"Key": "Value"'
without the enclosing braces), which potentially will become targets in the
Xcode project.
""",
    },
)

# Files

def _process_inputs(inputs_info):
    """Generates a `dict` for inputs of a target for use with `_xcode_target()`.

    Args:
        inputs_info: An `InputFilesInfo`.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
    """
    inputs = {}

    def _process_attr(attr):
        value = getattr(inputs_info, attr)
        if value:
            inputs[attr] = [file_path(file) for file in value]

    _process_attr("srcs")
    _process_attr("non_arc_srcs")
    _process_attr("hdrs")

    return inputs

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
        configuration: The configuration as returned by `_get_configuration()`.

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

def _get_static_library(*, label, linker_inputs):
    for input in linker_inputs.to_list():
        for library in input.libraries:
            static_library = library.static_library
            if static_library.owner == label:
                return static_library.path
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
        path = _get_static_library(
            label = target.label,
            linker_inputs = linker_inputs,
        )
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
        module: A `struct` as returned from `swift_common.create_module()`. See
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
        extra_files,
        generated,
        inputs_info,
        linker_inputs,
        modulemaps,
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
        extra_files:
        generated: A `list` of generated `File`s that are inputs to this target.
        inputs_info: An `InputFilesInfo` that will provide values for the
            `XcodeProjInfo.extra_files` and `XcodeProjInfo.generated_inputs`
            fields.
        linker_inputs: A `depset` of `LinkerInput`s for this target.
        modulemaps: A `struct` as returned from `_process_modulemaps()`.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        required_links: An optional `list` of strings that will be in the
            `XcodeProjInfo.required_links` `depset`.
        search_paths: A search paths `struct` as returned from
            `_process_search_paths()`.
        target: An optional `XcodeProjInfo.target` `struct`.
        xcode_target: An optional string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        defines = defines,
        dependencies = dependencies,
        extra_files = extra_files,
        generated = generated + [
            file
            for file in modulemaps.files
            if not file.is_source
        ],
        inputs_info = inputs_info,
        linker_inputs = linker_inputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        search_paths = search_paths,
        target = target,
        xcode_targets = [xcode_target] if xcode_target else None,
    )

def _needs_search_paths(*, inputs_info):
    for src in inputs_info.srcs:
        if not src.path.endswith(".swift"):
            return True
    return False

def _xcode_target(
        *,
        id,
        name,
        label,
        configuration,
        platform,
        product,
        test_host,
        build_settings,
        search_paths,
        modulemaps,
        inputs_info,
        links,
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
        platform: The platform `dict` as returned by `process_platform()`.
        product: The product `dict` as returned by `_process_product()`.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: A search paths `struct` as returned from
            `_process_search_paths()`.
        modulemaps: A `struct` as returned from `_process_modulemaps()`.
        inputs_info: An `InputFilesInfo` provider.
        links: A `list` of file paths for libraries that the target links
            against.
        dependencies: A `list` of `id`s of targets that this target depends on.
        outputs: The outputs `dict` as returned by `_process_outputs()`.

    Returns:
        An element of a json array string. This should be wrapped with `"[{}]"`
        to create a json array string, possibly joining multiples of these
        strings with `","`.
    """

    # We can send search paths for all targets, but not sending them for
    # certain targets reduces the size of the spec, the time it takes to parse
    # the spec, and the size of the produced project.
    if not _needs_search_paths(inputs_info = inputs_info):
        search_paths = {}

    target = json.encode(struct(
        name = name,
        label = str(label),
        configuration = configuration,
        platform = platform,
        product = product,
        test_host = test_host,
        build_settings = build_settings,
        search_paths = search_paths,
        modulemaps = modulemaps.file_paths,
        inputs = _process_inputs(inputs_info),
        links = links,
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

        build_settings["GENERATE_INFOPLIST_FILE"] = True
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
            build_settings["GENERATE_INFOPLIST_FILE"] = True

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
        A `struct` as returned from `_processed_target()`.
    """
    configuration = _get_configuration(ctx)
    id = _get_id(label = target.label, configuration = configuration)
    inputs_info = target[InputFilesInfo]
    dependencies = _process_dependencies(transitive_infos = transitive_infos)

    library_dep_targets = [
        dep[XcodeProjInfo].target
        for dep in ctx.rule.attr.deps
        if dep[XcodeProjInfo].target and dep[XcodeProjInfo].linker_inputs
    ]

    linker_inputs = depset(
        transitive = [
            dep[XcodeProjInfo].linker_inputs
            for dep in ctx.rule.attr.deps
        ],
    )

    if len(library_dep_targets) == 1 and not inputs_info.srcs:
        mergeable_target = library_dep_targets[0]
        mergeable_label = mergeable_target.label
        potential_target_merges = [
            struct(src = mergeable_target.id, dest = id),
        ]
    elif bundle_info and len(library_dep_targets) > 1:
        fail("""\
The xcodeproj rule requires {} rules to have a single library dep. {} has {}.\
""".format(ctx.rule.kind, target.label, len(library_dep_targets)))
    else:
        potential_target_merges = None
        mergeable_label = None

    build_settings = {}

    process_opts(ctx = ctx, target = target, build_settings = build_settings)

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

    test_host_target_info = _process_test_host(
        getattr(ctx.rule.attr, "test_host", None),
    )

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

    inputs_info = target[InputFilesInfo]
    modulemaps = _process_modulemaps(
        swift_info = target[SwiftInfo] if SwiftInfo in target else None,
    )
    search_paths = _process_search_paths(
        bin_dir_path = ctx.bin_dir.path,
        includes = getattr(ctx.rule.attr, "includes", []),
        target = target,
        transitive_infos = transitive_infos,
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
        extra_files = inputs_info.other,
        generated = inputs_info.generated,
        inputs_info = inputs_info,
        linker_inputs = linker_inputs,
        modulemaps = modulemaps,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = target.label,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = props.product_name,
            label = target.label,
            configuration = configuration,
            platform = platform,
            product = _process_product(
                target = target,
                product_name = props.product_name,
                product_type = props.product_type,
                bundle_path = props.bundle_path,
                linker_inputs = linker_inputs,
                build_settings = build_settings,
            ),
            test_host = test_host_target_info.target.id if test_host_target_info else None,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            inputs_info = inputs_info,
            links = links,
            dependencies = dependencies,
            outputs = _process_outputs(target),
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
        A `struct` as returned from `_processed_target()`.
    """
    configuration = _get_configuration(ctx)
    id = _get_id(label = target.label, configuration = configuration)

    build_settings = {}

    process_opts(ctx = ctx, target = target, build_settings = build_settings)
    product_name = ctx.rule.attr.name
    module_name = get_product_module_name(ctx = ctx, target = target)
    build_settings["PRODUCT_MODULE_NAME"] = module_name
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

    inputs_info = target[InputFilesInfo]
    modulemaps = _process_modulemaps(
        swift_info = target[SwiftInfo] if SwiftInfo in target else None,
    )
    search_paths = _process_search_paths(
        bin_dir_path = ctx.bin_dir.path,
        includes = getattr(ctx.rule.attr, "includes", []),
        target = target,
        transitive_infos = transitive_infos,
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
        extra_files = inputs_info.other,
        generated = inputs_info.generated,
        inputs_info = inputs_info,
        linker_inputs = linker_inputs,
        modulemaps = modulemaps,
        potential_target_merges = None,
        required_links = None,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = target.label,
        ),
        xcode_target = _xcode_target(
            id = id,
            name = module_name,
            label = target.label,
            product = _process_product(
                target = target,
                product_name = product_name,
                product_type = "com.apple.product-type.library.static",
                bundle_path = None,
                linker_inputs = linker_inputs,
                build_settings = build_settings,
            ),
            configuration = configuration,
            platform = platform,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            test_host = None,
            inputs_info = inputs_info,
            links = [],
            dependencies = dependencies,
            outputs = _process_outputs(target),
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
        A `struct` as returned from `_processed_target()`.
    """
    if CcInfo in target:
        linker_inputs = _get_linker_inputs(cc_info = target[CcInfo])
    else:
        linker_inputs = depset()

    inputs_info = target[InputFilesInfo]

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
        extra_files = (
            inputs_info.srcs +
            inputs_info.non_arc_srcs +
            inputs_info.hdrs +
            inputs_info.other
        ),
        generated = inputs_info.generated,
        inputs_info = inputs_info,
        linker_inputs = linker_inputs,
        modulemaps = _process_modulemaps(swift_info = None),
        potential_target_merges = None,
        required_links = None,
        search_paths = _process_search_paths(
            bin_dir_path = ctx.bin_dir.path,
            includes = getattr(ctx.rule.attr, "includes", []),
            target = target,
            transitive_infos = transitive_infos,
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

    # Targets that don't produce files are ignored (e.g. imports)
    return target.files != depset() and (
        # Top level bundles
        AppleBundleInfo in target or
        # Libraries
        CcInfo in target or
        # Bare executables
        target[DefaultInfo].files_to_run.executable
    )

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
        extra_files,
        generated_inputs,
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
        extra_files: Maps to the `XcodeProjInfo.extra_files` field.
        generated_inputs: Maps to the `XcodeProjInfo.generated_inputs` field.
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
        "extra_files": extra_files,
        "generated_inputs": generated_inputs,
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
        extra_files = depset(
            transitive = [
                info.extra_files
                for info in transitive_infos
            ],
        ),
        generated_inputs = depset(
            transitive = [
                info.generated_inputs
                for info in transitive_infos
            ],
        ),
        linker_inputs = depset(
            transitive = [
                info.linker_inputs
                for info in transitive_infos
            ],
        ),
        potential_target_merges = depset(
            transitive = [
                info.potential_target_merges
                for info in transitive_infos
            ],
        ),
        required_links = depset(
            transitive = [info.required_links for info in transitive_infos],
        ),
        search_paths = _process_search_paths(
            bin_dir_path = None,
            includes = [],
            target = None,
            transitive_infos = transitive_infos,
        ),
        target = None,
        xcode_targets = depset(
            transitive = [info.xcode_targets for info in transitive_infos],
        ),
    )

def _process_dependencies(*, transitive_infos):
    return [
        dependency
        for dependency in flatten([
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            [info.target.id] if info.target else info.dependencies
            for info in transitive_infos
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
    for info in transitive_infos:
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
        setting = reversed({x: None for x in reversed(setting)}.keys())

        set_if_true(build_settings, "GCC_PREPROCESSOR_DEFINITIONS", setting)

    return struct(
        cc_defines = transitive_cc_defines,
    )

def _append_if_new(existing, new):
    """Appends elements to a `list` if they are not already present in it.

    Args:
        existing: The existing `list` to append to.
        new: The new `list` to append elements from.
    """
    for element in new:
        if element not in existing:
            existing.append(element)

def _process_search_paths(*, bin_dir_path, target, includes, transitive_infos):
    if target and CcInfo in target:
        # First add our search paths
        root = target.label.workspace_root
        rooted_package = join_paths_ignoring_empty(root, target.label.package)
        quote_headers = [
            external_file_path(root) if root else project_file_path("."),
            generated_file_path(join_paths_ignoring_empty(bin_dir_path, root)),
        ]
        include_paths = []
        for include in includes:
            include_path = join_paths_ignoring_empty(rooted_package, include)
            if root:
                include_paths.append(external_file_path(include_path))
            else:
                include_paths.append(project_file_path(include_path))

            include_paths.append(
                generated_file_path(
                    join_paths_ignoring_empty(
                        bin_dir_path,
                        rooted_package,
                        include,
                    ),
                ),
            )
    else:
        quote_headers = []
        include_paths = []

    # Then add dependency search paths
    for info in transitive_infos:
        search_paths = info.search_paths
        if not search_paths:
            continue
        _append_if_new(quote_headers, search_paths.quote_headers)
        _append_if_new(include_paths, search_paths.includes)

    return struct(
        includes = include_paths,
        quote_headers = quote_headers,
    )

def _process_modulemaps(*, swift_info):
    if not swift_info:
        return struct(
            file_paths = [],
            files = [],
        )

    modulemap_file_paths = []
    modulemap_files = []
    for module in swift_info.transitive_modules.to_list():
        module_map = module.clang.module_map
        if not module.clang or not module_map:
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
        file_paths = {x: None for x in modulemap_file_paths}.keys(),
        files = {x: None for x in modulemap_files}.keys(),
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

    inputs_info = processed_target.inputs_info

    return _target_info_fields(
        defines = processed_target.defines,
        dependencies = processed_target.dependencies,
        extra_files = depset(
            depset(
                processed_target.extra_files,
                transitive = inputs_info.transitive_non_generated,
            ).to_list(),
            transitive = [
                info.extra_files
                for info in transitive_infos
            ],
        ),
        generated_inputs = depset(
            processed_target.generated,
            transitive = [
                info.generated_inputs
                for info in transitive_infos
            ],
        ),
        linker_inputs = processed_target.linker_inputs,
        potential_target_merges = depset(
            processed_target.potential_target_merges,
            transitive = [
                info.potential_target_merges
                for info in transitive_infos
            ],
        ),
        required_links = depset(
            processed_target.required_links,
            transitive = [info.required_links for info in transitive_infos],
        ),
        search_paths = processed_target.search_paths,
        target = processed_target.target,
        xcode_targets = depset(
            processed_target.xcode_targets,
            transitive = [info.xcode_targets for info in transitive_infos],
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

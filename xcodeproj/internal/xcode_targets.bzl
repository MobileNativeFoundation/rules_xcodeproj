"""Module containing functions dealing with the `Target` DTO."""

load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
    "normalized_file_path",
    "parsed_file_path",
)
load(":lldb_contexts.bzl", "lldb_contexts")
load(":platform.bzl", "platform_info")

def _make_xcode_target(
        *,
        id,
        name,
        label,
        configuration,
        package_bin_dir,
        platform,
        product,
        is_testonly = False,
        is_swift,
        test_host = None,
        build_settings,
        search_paths = None,
        modulemaps,
        swiftmodules,
        inputs,
        linker_inputs = None,
        infoplist = None,
        watch_application = None,
        extensions = [],
        app_clips = [],
        dependencies,
        transitive_dependencies,
        outputs,
        lldb_context = None,
        xcode_required_targets = depset()):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        name: The base name that the Xcode target should use. Multiple
            Xcode targets can have the same name; the generator will
            disambiguate them.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: The value returned from `process_platform`.
        product: The value returned from `process_product`.
        is_testonly: Whether the `Target` has `testonly = True` set.
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: A value returned from `target_search_paths.make`, or
            `None`.
        modulemaps: The value returned from `process_modulemaps`.
        swiftmodules: The value returned from `process_swiftmodules`.
        inputs: The value returned from `input_files.collect`.
        linker_inputs: A value returned from `linker_input_files.collect` or
            `None`.
        infoplist: A `File` or `None`.
        watch_application: The `id` of the watch application target that should
            be embedded in this target, or `None`.
        extensions: A `list` of `id`s of application extension targets that
            should be embedded in this target.
        app_clips: A `list` of `id`s of app clip targets that should be embedded
            in this target.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.
        transitive_dependencies: A `depset` of `id`s of all transitive targets
            that this target depends on.
        outputs: A value returned from `output_files.collect`.
        lldb_context: A value returned from `lldb_contexts.collect`.
        xcode_required_targets: A `depset` of values returned from
            `xcode_targets.make`, which represent targets that are required in
            BwX mode.

    Returns:
        A mostly opaque `struct` that can be passed to `xcode_targets.to_dto`.
    """
    return struct(
        _name = name,
        _configuration = configuration,
        _package_bin_dir = package_bin_dir,
        _is_testonly = is_testonly,
        _test_host = test_host,
        _build_settings = struct(**build_settings),
        _search_paths = search_paths,
        _modulemaps = modulemaps,
        _swiftmodules = tuple(swiftmodules),
        _watch_application = watch_application,
        _extensions = tuple(extensions),
        _app_clips = tuple(app_clips),
        _dependencies = dependencies,
        _lldb_context = lldb_context,
        id = id,
        label = label,
        platform = platform,
        product = product,
        linker_inputs = _to_xcode_target_linker_inputs(linker_inputs),
        inputs = _to_xcode_target_inputs(inputs),
        is_swift = is_swift,
        outputs = _to_xcode_target_outputs(outputs),
        infoplist = infoplist,
        transitive_dependencies = transitive_dependencies,
        xcode_required_targets = xcode_required_targets,
    )

def _to_xcode_target_inputs(inputs):
    return struct(
        srcs = inputs.srcs,
        non_arc_srcs = inputs.non_arc_srcs,
        hdrs = inputs.hdrs,
        exported_symbols_lists = inputs.exported_symbols_lists,
        pch = inputs.pch,
        entitlements = inputs.entitlements,
        resources = inputs.resources,
        resource_bundle_dependencies = inputs.resource_bundle_dependencies,
        generated = inputs.generated,
        indexstores = inputs.indexstores,
        unfocused_generated_compiling = inputs.unfocused_generated_compiling,
        unfocused_generated_indexstores = (
            inputs.unfocused_generated_indexstores
        ),
        unfocused_generated_linking = inputs.unfocused_generated_linking,
        compiling_output_group_name = inputs.compiling_output_group_name,
        indexstores_output_group_name = inputs.indexstores_output_group_name,
        linking_output_group_name = inputs.linking_output_group_name,
    )

def _to_xcode_target_linker_inputs(linker_inputs):
    if not linker_inputs:
        return None

    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return None

    return struct(
        dynamic_frameworks = top_level_values.dynamic_frameworks,
        force_load_libraries = top_level_values.force_load_libraries,
        linkopts = top_level_values.linkopts,
        static_libraries = top_level_values.static_libraries,
        static_frameworks = top_level_values.static_frameworks,
    )

def _to_xcode_target_outputs(outputs):
    direct_outputs = outputs.direct_outputs

    return struct(
        product_file_path = (
            direct_outputs.product_file_path if direct_outputs else None
        ),
        products_output_group_name = outputs.products_output_group_name,
        swift = direct_outputs.swift if direct_outputs else None,
        transitive_infoplists = outputs.transitive_infoplists,
    )

def _xcode_target_to_dto(
        xcode_target,
        *,
        additional_scheme_target_ids = None,
        include_lldb_context,
        is_unfocused_dependency = False,
        unfocused_targets = {}):
    inputs = xcode_target.inputs

    dto = {
        "name": xcode_target._name,
        "label": str(xcode_target.label),
        "configuration": xcode_target._configuration,
        "package_bin_dir": xcode_target._package_bin_dir,
        "platform": platform_info.to_dto(xcode_target.platform),
        "product": _product_to_dto(xcode_target.product),
    }

    if xcode_target._is_testonly:
        dto["is_testonly"] = True

    if not xcode_target.is_swift:
        dto["is_swift"] = False

    if is_unfocused_dependency:
        dto["is_unfocused_dependency"] = True

    if xcode_target._test_host not in unfocused_targets:
        set_if_true(dto, "test_host", xcode_target._test_host)

    if xcode_target._watch_application not in unfocused_targets:
        set_if_true(dto, "watch_application", xcode_target._watch_application)

    if include_lldb_context:
        set_if_true(
            dto,
            "lldb_context",
            lldb_contexts.to_dto(xcode_target._lldb_context),
        )

    set_if_true(dto, "build_settings", xcode_target._build_settings)
    set_if_true(
        dto,
        "search_paths",
        _search_paths_to_dto(xcode_target._search_paths),
    )
    set_if_true(
        dto,
        "modulemaps",
        [file_path_to_dto(fp) for fp in xcode_target._modulemaps.file_paths],
    )
    set_if_true(
        dto,
        "swiftmodules",
        [file_path_to_dto(fp) for fp in xcode_target._swiftmodules],
    )
    set_if_true(
        dto,
        "resource_bundle_dependencies",
        [
            id
            for id in inputs.resource_bundle_dependencies.to_list()
            if id not in unfocused_targets
        ],
    )
    set_if_true(dto, "inputs", _inputs_to_dto(inputs))
    set_if_true(
        dto,
        "linker_inputs",
        _linker_inputs_to_dto(xcode_target.linker_inputs),
    )
    set_if_true(
        dto,
        "info_plist",
        file_path_to_dto(file_path(xcode_target.infoplist)),
    )
    set_if_true(
        dto,
        "extensions",
        [
            id
            for id in xcode_target._extensions
            if id not in unfocused_targets
        ],
    )
    set_if_true(
        dto,
        "app_clips",
        [
            id
            for id in xcode_target._app_clips
            if id not in unfocused_targets
        ],
    )
    set_if_true(
        dto,
        "dependencies",
        [
            id
            for id in xcode_target._dependencies.to_list()
            if id not in unfocused_targets
        ],
    )
    set_if_true(dto, "outputs", _outputs_to_dto(xcode_target.outputs))

    set_if_true(
        dto,
        "additional_scheme_targets",
        additional_scheme_target_ids,
    )

    return dto

def _inputs_to_dto(inputs):
    """Generates a target DTO value for inputs.

    Args:
        inputs: A value returned from `input_files.to_xcode_target_inputs`.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
        *   `pch`: An optional `FilePath` for `pch`.
        *   `resources`: A `list` of `FilePath`s for `resources`.
        *   `entitlements`: An optional `FilePath` for `entitlements`.
        *   `exported_symbols_lists`: A `list` of `FilePath`s for
            `exported_symbols_lists`.
    """
    ret = {}

    def _process_attr(attr):
        value = getattr(inputs, attr)
        if value:
            ret[attr] = [
                file_path_to_dto(file_path(file))
                for file in value.to_list()
            ]

    _process_attr("srcs")
    _process_attr("non_arc_srcs")
    _process_attr("hdrs")
    _process_attr("exported_symbols_lists")

    if inputs.pch:
        ret["pch"] = file_path_to_dto(file_path(inputs.pch))

    if inputs.entitlements:
        ret["entitlements"] = file_path_to_dto(file_path(inputs.entitlements))

    if inputs.resources:
        set_if_true(
            ret,
            "resources",
            [file_path_to_dto(fp) for fp in inputs.resources.to_list()],
        )

    return ret

def _linker_inputs_to_dto(linker_inputs):
    """Generates a target DTO for linker inputs.

    Args:
        linker_inputs: A value returned from `_to_xcode_target_linker_inputs`.

    Returns:
        A `dict` containing the following elements:

        *   `dynamic_frameworks`: A `list` of `FilePath`s for
            `dynamic_frameworks`.
        *   `static_frameworks`: A `list` of `FilePath`s for
            `static_frameworks`.
        *   `static_libraries`: A `list` of `FilePath`s for `static_libraries`.
        *   `linkopts`: A `list` of `string`s for linkopts.
    """
    if not linker_inputs:
        return {}

    ret = {}
    set_if_true(
        ret,
        "dynamic_frameworks",
        [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in linker_inputs.dynamic_frameworks
        ],
    )
    set_if_true(
        ret,
        "force_load",
        [
            file_path_to_dto(file_path(file))
            for file in linker_inputs.force_load_libraries
        ],
    )
    set_if_true(
        ret,
        "linkopts",
        linker_inputs.linkopts,
    )
    set_if_true(
        ret,
        "static_libraries",
        [
            file_path_to_dto(file_path(file))
            for file in linker_inputs.static_libraries
        ],
    )
    set_if_true(
        ret,
        "static_frameworks",
        [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in linker_inputs.static_frameworks
        ],
    )

    return ret

def _outputs_to_dto(outputs):
    dto = {}

    if outputs.product_file_path:
        dto["p"] = file_path_to_dto(outputs.product_file_path)

    if outputs.swift:
        dto["s"] = _swift_to_dto(outputs.swift)

    return dto

def _product_to_dto(product):
    additional_paths = [
        file_path_to_dto(normalized_file_path(file))
        for file in product.linker_files.to_list()
    ]

    return {
        "additional_paths": additional_paths,
        "executable_name": product.executable_name,
        "is_resource_bundle": product.is_resource_bundle,
        "name": product.name,
        "path": file_path_to_dto(product.file_path),
        "type": product.type,
    }

def _search_paths_to_dto(search_paths):
    compile_search_paths = search_paths
    if search_paths:
        compilation_providers = search_paths._compilation_providers
    else:
        compilation_providers = None

    if compilation_providers:
        cc_info = compilation_providers._cc_info
        objc = compilation_providers._objc
    else:
        cc_info = None
        objc = None

    dto = {}
    if cc_info:
        compilation_context = cc_info.compilation_context
        opts_search_paths = compile_search_paths._opts_search_paths

        if opts_search_paths:
            opts_includes = list(opts_search_paths.includes)
            opts_quote_includes = list(opts_search_paths.quote_includes)
            opts_system_includes = list(opts_search_paths.system_includes)
        else:
            opts_includes = []
            opts_quote_includes = []
            opts_system_includes = []

        quote_includes = depset(
            [".", compile_search_paths._bin_dir_path] + opts_quote_includes,
            transitive = [compilation_context.quote_includes],
        )

        set_if_true(
            dto,
            "quote_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in quote_includes.to_list()
            ],
        )
        set_if_true(
            dto,
            "includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.includes.to_list() +
                             opts_includes)
            ],
        )
        set_if_true(
            dto,
            "system_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.system_includes.to_list() +
                             opts_system_includes)
            ],
        )

    if objc:
        framework_paths = depset(
            transitive = [
                objc.static_framework_paths,
                objc.dynamic_framework_paths,
            ],
        )

        framework_file_paths = [
            parsed_file_path(path)
            for path in framework_paths.to_list()
        ]

        set_if_true(
            dto,
            "framework_includes",
            [
                file_path_to_dto(fp)
                for fp in framework_file_paths
            ],
        )

    return dto

def _swift_to_dto(swift):
    module = swift.module
    dto = {
        "m": file_path_to_dto(file_path(module.swiftmodule)),
        "s": file_path_to_dto(file_path(module.swiftsourceinfo)),
        "d": file_path_to_dto(file_path(module.swiftdoc)),
    }

    if module.swiftinterface:
        dto["i"] = file_path_to_dto(file_path(module.swiftinterface))

    if swift.generated_header:
        dto["h"] = file_path_to_dto(file_path(swift.generated_header))

    return dto

def _get_top_level_static_libraries(xcode_target):
    """Returns the static libraries needed to link the target.

    Args:
        xcode_target: A value returned from `xcode_targets.make`.

    Returns:
        A `list` of `File`s that need to be linked for the target.
    """
    linker_inputs = xcode_target.linker_inputs
    if not linker_inputs:
        fail("Xcode target requires `ObjcProvider` or `CcInfo`")
    return linker_inputs.static_libraries + linker_inputs.force_load_libraries

xcode_targets = struct(
    get_top_level_static_libraries = _get_top_level_static_libraries,
    make = _make_xcode_target,
    to_dto = _xcode_target_to_dto,
)

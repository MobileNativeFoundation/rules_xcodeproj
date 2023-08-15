"""Module containing functions dealing with the `Target` DTO."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:structs.bzl", "structs")
load(":collections.bzl", "set_if_true", "uniq")
load(
    ":files.bzl",
    "FRAMEWORK_EXTENSIONS",
    "build_setting_path",
    "normalized_file_path",
)
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "EMPTY_TUPLE",
    "memory_efficient_depset",
)
load(":platforms.bzl", "platforms")

def _make_xcode_target(
        *,
        id,
        label,
        configuration,
        compile_target_swift = None,
        compile_target_non_swift = None,
        package_bin_dir,
        platform,
        product,
        test_host = None,
        build_settings,
        c_params = None,
        cxx_params = None,
        swift_params = None,
        c_has_fortify_source = False,
        cxx_has_fortify_source = False,
        modulemaps,
        swiftmodules,
        inputs,
        linker_inputs = None,
        watch_application = None,
        extensions = EMPTY_LIST,
        app_clips = EMPTY_LIST,
        dependencies,
        transitive_dependencies,
        outputs,
        lldb_context = None,
        should_create_xcode_target = True,
        xcode_required_targets = EMPTY_DEPSET):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        compile_target_swift: The Swift `xcode_target` that was merged into
            this target.
        compile_target_non_swift: The non-Swift `xcode_target` that was merged
            into this target.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: The value returned from `process_platform`.
        product: The value returned from `process_product`.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        c_params: A C compiler params `File`.
        cxx_params: A C++ compiler params `File`.
        swift_params: A Swift compiler params `File`.
        c_has_fortify_source: Whether the C compiler has fortify source enabled.
        cxx_has_fortify_source: Whether the C++ compiler has fortify source
            enabled.
        modulemaps: The value returned from `process_modulemaps`.
        swiftmodules: The value returned from `process_swiftmodules`.
        inputs: The value returned from `input_files.collect`.
        linker_inputs: A value returned from `linker_input_files.collect` or
            `None`.
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
        should_create_xcode_target: `True` if this `xcode_target` should be
            included in the generated Xcode project. This can be `False` for
            targets like header-only libraries.
        xcode_required_targets: A `depset` of values returned from
            `xcode_targets.make`, which represent targets that are required in
            BwX mode.

    Returns:
        A mostly opaque `struct` that can be passed to `xcode_targets.to_dto`.
    """

    compile_targets = []

    # Intentionally add the Swift compile target first since it's used later in
    # the setting of `COMPILE_TARGET_NAME` and is assumed to be first when there
    # are multiple values.
    if compile_target_swift:
        compile_targets.append(compile_target_swift)
    if compile_target_non_swift:
        compile_targets.append(compile_target_non_swift)

    product = (
        _to_xcode_target_product(product) if not compile_targets else product
    )

    return struct(
        _compile_targets = tuple(compile_targets),
        _package_bin_dir = package_bin_dir,
        _test_host = test_host,
        _build_settings = struct(**build_settings),
        _c_has_fortify_source = c_has_fortify_source,
        _cxx_has_fortify_source = cxx_has_fortify_source,
        _modulemaps = modulemaps,
        _swiftmodules = tuple(swiftmodules),
        _watch_application = watch_application,
        _extensions = tuple(extensions),
        _app_clips = tuple(app_clips),
        _dependencies = dependencies,
        id = id,
        label = label,
        configuration = configuration,
        c_params = c_params,
        cxx_params = cxx_params,
        platform = platform,
        product = product,
        linker_inputs = (
            _to_xcode_target_linker_inputs(linker_inputs) if not compile_targets else linker_inputs
        ),
        lldb_context = lldb_context,
        lldb_context_key = _lldb_context_key(
            platform = platform,
            product = product,
        ),
        inputs = (
            _to_xcode_target_inputs(inputs) if not compile_targets else inputs
        ),
        outputs = (
            _to_xcode_target_outputs(outputs) if not compile_targets else outputs
        ),
        should_create_xcode_target = should_create_xcode_target,
        swift_params = swift_params,
        transitive_dependencies = transitive_dependencies,
        xcode_required_targets = xcode_required_targets,
    )

_BUNDLE_TYPES = {
    "com.apple.product-type.application": None,
    "com.apple.product-type.application.on-demand-install-capable": None,
    "com.apple.product-type.application.watchapp": None,
    "com.apple.product-type.application.watchapp2": None,
    "com.apple.product-type.app-extension": None,
    "com.apple.product-type.app-extension.messages": None,
    "com.apple.product-type.bundle": None,
    "com.apple.product-type.bundle.ui-testing": None,
    "com.apple.product-type.bundle.unit-test": None,
    "com.apple.product-type.extensionkit-extension": None,
    "com.apple.product-type.framework": None,
    "com.apple.product-type.tv-app-extension": None,
    "com.apple.product-type.watchkit-extension": None,
    "com.apple.product-type.watchkit2-extension": None,
}

def _lldb_context_key(*, platform, product):
    fp = product.file_path
    if not fp:
        return None

    product_basename = paths.basename(fp)
    base_key = "{} {}".format(
        platforms.to_lldb_context_triple(platform),
        product_basename,
    )

    if not product.type in _BUNDLE_TYPES:
        return base_key

    executable_name = product.executable_name
    if not executable_name:
        executable_name = paths.split_extension(product_basename)[0]

    if platforms.is_platform_type(
        platform,
        apple_common.platform_type.macos,
    ):
        return "{}/Contents/MacOS/{}".format(base_key, executable_name)

    return "{}/{}".format(base_key, executable_name)

def _to_xcode_target_inputs(inputs):
    return struct(
        srcs = tuple(inputs.srcs),
        non_arc_srcs = tuple(inputs.non_arc_srcs),
        hdrs = tuple(inputs.hdrs),
        has_c_sources = bool(inputs.c_sources),
        has_cxx_sources = bool(inputs.cxx_sources),
        resources = inputs.resources,
        folder_resources = inputs.folder_resources,
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
        link_args = top_level_values.link_args,
        link_args_inputs = top_level_values.link_args_inputs,
        static_libraries = top_level_values.static_libraries,
    )

def _to_xcode_target_outputs(outputs):
    direct_outputs = outputs.direct_outputs

    swiftmodule = None
    swift_generated_header = None
    if direct_outputs:
        swift = direct_outputs.swift
        if swift:
            swiftmodule = swift.module.swiftmodule
            if swift.generated_header:
                swift_generated_header = swift.generated_header

    return struct(
        dsym_files = (
            direct_outputs.dsym_files if direct_outputs else None
        ),
        generated_output_group_name = outputs.generated_output_group_name,
        linking_output_group_name = outputs.linking_output_group_name,
        product_file = (
            direct_outputs.product if direct_outputs else None
        ),
        product_path = (
            direct_outputs.product_path if direct_outputs else None
        ),
        products_output_group_name = outputs.products_output_group_name,
        swiftmodule = swiftmodule,
        swift_generated_header = swift_generated_header,
        transitive_infoplists = outputs.transitive_infoplists,
    )

def _to_xcode_target_product(product):
    return struct(
        name = product.name,
        module_name_attribute = product.module_name_attribute,
        type = product.type,
        file = product.file,
        basename = product.basename,
        file_path = product.file_path,
        executable = product.executable,
        executable_name = product.executable_name,
        package_dir = product.package_dir,
        additional_product_files = EMPTY_TUPLE,
        framework_files = product.framework_files,
        is_resource_bundle = product.is_resource_bundle,
        _additional_files = product.framework_files,
    )

def _merge_xcode_target(*, src_swift, src_non_swift, dest):
    """Creates a new `xcode_target` by merging the values of `src` into `dest`.

    Args:
        src_swift: The `xcode_target` to merge into `dest` that `is_swift`.
        src_non_swift: The `xcode_target` to merge into `dest` that is not
            `is_swift`.
        dest: The `xcode_target` being merged into.

    Returns:
        A value as returned by `xcode_targets.make`.
    """

    build_settings = {}

    if src_swift:
        build_settings = dicts.add(
            structs.to_dict(src_swift._build_settings),
            build_settings,
        )
    if src_non_swift:
        build_settings = dicts.add(
            structs.to_dict(src_non_swift._build_settings),
            build_settings,
        )

    # This is intentionally last since it's the highest-level target that should
    # override some build settings from the other target(s).
    build_settings = dicts.add(
        structs.to_dict(dest._build_settings),
        build_settings,
    )

    srcs = []
    transitive_dependencies = [dest._dependencies]
    platform = None
    c_params = dest.c_params
    cxx_params = dest.cxx_params
    swift_params = dest.swift_params
    c_has_fortify_source = dest._c_has_fortify_source
    cxx_has_fortify_source = dest._cxx_has_fortify_source
    swiftmodules = []
    modulemaps = ()
    if src_swift:
        srcs.append(src_swift)
        transitive_dependencies.append(src_swift._dependencies)
        swift_params = src_swift.swift_params or dest.swift_params
        platform = src_swift.platform
        swiftmodules = src_swift._swiftmodules
        modulemaps = src_swift._modulemaps
    if src_non_swift:
        srcs.append(src_non_swift)
        transitive_dependencies.append(src_non_swift._dependencies)
        c_params = src_non_swift.c_params or c_params
        cxx_params = src_non_swift.cxx_params or cxx_params
        c_has_fortify_source = src_non_swift._c_has_fortify_source or c_has_fortify_source
        cxx_has_fortify_source = src_non_swift._cxx_has_fortify_source or cxx_has_fortify_source
        platform = src_non_swift.platform

    return _make_xcode_target(
        id = dest.id,
        label = dest.label,
        configuration = dest.configuration,
        compile_target_swift = src_swift,
        compile_target_non_swift = src_non_swift,
        package_bin_dir = dest._package_bin_dir,
        platform = platform,
        product = _merge_xcode_target_product(
            srcs = [src.product for src in srcs],
            dest = dest.product,
        ),
        test_host = dest._test_host,
        build_settings = build_settings,
        c_params = c_params,
        cxx_params = cxx_params,
        swift_params = swift_params,
        c_has_fortify_source = c_has_fortify_source,
        cxx_has_fortify_source = cxx_has_fortify_source,
        modulemaps = modulemaps,
        swiftmodules = swiftmodules,
        inputs = _merge_xcode_target_inputs(
            src_swift = src_swift.inputs if src_swift else None,
            src_non_swift = src_non_swift.inputs if src_non_swift else None,
            dest = dest.inputs,
        ),
        linker_inputs = dest.linker_inputs,
        watch_application = dest._watch_application,
        extensions = dest._extensions,
        app_clips = dest._app_clips,
        dependencies = memory_efficient_depset(
            transitive = transitive_dependencies,
        ),
        transitive_dependencies = dest.transitive_dependencies,
        outputs = _merge_xcode_target_outputs(
            src_swift = src_swift.outputs if src_swift else None,
            dest = dest.outputs,
        ),
        lldb_context = dest.lldb_context,
        xcode_required_targets = dest.xcode_required_targets,
    )

def _merge_xcode_target_inputs(*, src_swift, src_non_swift, dest):
    srcs = ()
    if src_swift:
        srcs = src_swift.srcs
    if src_non_swift:
        srcs = srcs + src_non_swift.srcs

    return struct(
        srcs = srcs,
        non_arc_srcs = src_non_swift.non_arc_srcs if src_non_swift else (),
        hdrs = dest.hdrs,
        has_c_sources = src_non_swift.has_c_sources if src_non_swift else None,
        has_cxx_sources = src_non_swift.has_cxx_sources if src_non_swift else None,
        resources = dest.resources,
        folder_resources = dest.folder_resources,
        resource_bundle_dependencies = dest.resource_bundle_dependencies,
        generated = dest.generated,
        indexstores = dest.indexstores,
        unfocused_generated_compiling = dest.unfocused_generated_compiling,
        unfocused_generated_indexstores = (
            dest.unfocused_generated_indexstores
        ),
        unfocused_generated_linking = dest.unfocused_generated_linking,
        compiling_output_group_name = dest.compiling_output_group_name,
        indexstores_output_group_name = dest.indexstores_output_group_name,
        linking_output_group_name = dest.linking_output_group_name,
    )

def _merge_xcode_target_outputs(*, src_swift, dest):
    return struct(
        dsym_files = dest.dsym_files,
        generated_output_group_name = dest.generated_output_group_name,
        linking_output_group_name = dest.linking_output_group_name,
        swiftmodule = src_swift.swiftmodule if src_swift else None,
        swift_generated_header = src_swift.swift_generated_header if src_swift else None,
        product_file = dest.product_file,
        product_path = dest.product_path,
        products_output_group_name = dest.products_output_group_name,
        transitive_infoplists = dest.transitive_infoplists,
    )

def _merge_xcode_target_product(*, srcs, dest):
    src_files = [src.file for src in srcs if src.file]
    src_framework_files = [src.framework_files for src in srcs]
    src_additional_files = [src._additional_files for src in srcs]

    return struct(
        name = dest.name,
        module_name_attribute = dest.module_name_attribute,
        type = dest.type,
        file = dest.file,
        basename = dest.basename,
        file_path = dest.file_path,
        executable = dest.executable,
        executable_name = dest.executable_name,
        package_dir = dest.package_dir,
        framework_files = memory_efficient_depset(
            transitive = [dest.framework_files] + src_framework_files,
        ),
        additional_product_files = tuple(src_files),
        is_resource_bundle = dest.is_resource_bundle,
        _additional_files = memory_efficient_depset(
            src_files,
            transitive = [dest._additional_files] + src_additional_files,
        ),
    )

def _set_bazel_outputs_product(
        *,
        build_mode,
        build_settings,
        xcode_target):
    if build_mode != "bazel":
        return

    product_path = xcode_target.outputs.product_path
    if product_path:
        build_settings["BAZEL_OUTPUTS_PRODUCT"] = product_path
        build_settings["BAZEL_OUTPUTS_PRODUCT_BASENAME"] = (
            xcode_target.product.basename
        )

    dsym_files = xcode_target.outputs.dsym_files
    if dsym_files:
        dsym_paths = []
        for file in dsym_files.to_list():
            file_path = file.path

            # dSYM files contain plist and DWARF.
            if not file_path.endswith("Info.plist"):
                # ../Product.dSYM/Contents/Resources/DWARF/Product
                dsym_path = "/".join(file_path.split("/")[:-4])
                dsym_paths.append("\"{}\"".format(dsym_path))
        if dsym_paths:
            build_settings["BAZEL_OUTPUTS_DSYM"] = dsym_paths

def _set_preview_framework_paths(
        *,
        build_mode,
        build_settings,
        linker_products_map,
        xcode_target):
    if (build_mode == "xcode" or
        xcode_target.product.type != "com.apple.product-type.framework"):
        return

    def _map_framework(file):
        path = build_setting_path(
            file = file,
            path = file.dirname,
        )
        return '"{}"'.format(linker_products_map.get(path, path))

    build_settings["PREVIEW_FRAMEWORK_PATHS"] = [
        _map_framework(file)
        for file in xcode_target.linker_inputs.dynamic_frameworks
    ]

_PREVIEWS_ENABLED_PRODUCT_TYPES = {
    "com.apple.product-type.application": None,
    "com.apple.product-type.application.on-demand-install-capable": None,
    "com.apple.product-type.application.watchapp": None,
    "com.apple.product-type.application.watchapp2": None,
    "com.apple.product-type.app-extension": None,
    "com.apple.product-type.app-extension.messages": None,
    "com.apple.product-type.bundle.unit-test": None,
    "com.apple.product-type.extensionkit-extension": None,
    "com.apple.product-type.framework": None,
    "com.apple.product-type.tv-app-extension": None,
    "com.apple.product-type.watchkit-extension": None,
    "com.apple.product-type.watchkit2-extension": None,
}

def _set_swift_include_paths(
        *,
        build_mode,
        build_settings,
        xcode_generated_paths,
        xcode_target):
    if not xcode_target.swift_params:
        return

    if build_mode == "xcode":
        def _handle_swiftmodule_path(file):
            path = file.path
            bs_path = xcode_generated_paths.get(path)
            if bs_path:
                include_path = paths.dirname(bs_path)
            else:
                include_path = file.dirname

            if include_path.find(" ") != -1:
                include_path = '"{}"'.format(include_path)

            return include_path

        includes = uniq([
            _handle_swiftmodule_path(file)
            for file in xcode_target._swiftmodules
        ])
    else:
        def _handle_swiftmodule_path(file):
            include_path = file.dirname

            if include_path.find(" ") != -1:
                include_path = '"{}"'.format(include_path)

            return include_path

        # BwB Swift include paths are set in
        # `swift_compiler_params_processor.py`
        includes = []

    swiftmodule = xcode_target.outputs.swiftmodule
    if (swiftmodule and
        xcode_target.product.type in _PREVIEWS_ENABLED_PRODUCT_TYPES):
        build_settings["PREVIEWS_SWIFT_INCLUDE__"] = ""
        build_settings["PREVIEWS_SWIFT_INCLUDE__NO"] = ""
        build_settings["PREVIEWS_SWIFT_INCLUDE__YES"] = (
            "-I {}".format(_handle_swiftmodule_path(swiftmodule))
        )

    set_if_true(build_settings, "SWIFT_INCLUDE_PATHS", " ".join(includes))

def _generated_framework_search_paths(
        *,
        build_mode,
        xcode_generated_paths,
        xcode_target):
    if build_mode != "xcode":
        return {}

    if xcode_target.linker_inputs:
        frameworks = xcode_target.linker_inputs.dynamic_frameworks
    else:
        frameworks = []

    framework_search_paths = {}
    for file in frameworks:
        framework_path = file.dirname
        search_path = paths.dirname(framework_path)
        xcode_generated_path = xcode_generated_paths.get(framework_path)
        if xcode_generated_path:
            framework_search_paths.setdefault(search_path, {})["x"] = (
                paths.dirname(xcode_generated_path)
            )
        else:
            framework_search_paths.setdefault(search_path, {})["b"] = (
                search_path
            )

    return framework_search_paths

def _xcode_target_to_dto(
        xcode_target,
        *,
        actions,
        additional_scheme_target_ids = None,
        build_mode,
        bwx_unfocused_dependencies,
        excluded_targets = {},
        focused_labels,
        label,
        link_params_processor,
        linker_products_map,
        params_index,
        rule_name,
        should_include_outputs,
        target_merges = {},
        unfocused_labels,
        xcode_configurations,
        xcode_generated_paths,
        xcode_generated_paths_file):
    inputs = xcode_target.inputs
    name = label.name
    is_unfocused_dependency = xcode_target.id in bwx_unfocused_dependencies

    dto = {
        "n": name,
        "l": str(label),
        "c": xcode_target.configuration,
        "1": xcode_target._package_bin_dir,
        "2": platforms.to_dto(xcode_target.platform),
        "p": _product_to_dto(xcode_target.product),
    }

    if xcode_configurations != ["Debug"]:
        dto["x"] = xcode_configurations

    if xcode_target._compile_targets:
        dto["3"] = [{
            "i": compile_target.id,
            "n": compile_target.label.name,
        } for compile_target in xcode_target._compile_targets]

    if is_unfocused_dependency:
        dto["u"] = True

    if xcode_target._test_host not in excluded_targets:
        set_if_true(dto, "h", xcode_target._test_host)

    if xcode_target._watch_application not in excluded_targets:
        set_if_true(dto, "w", xcode_target._watch_application)

    generated_framework_search_paths = _generated_framework_search_paths(
        build_mode = build_mode,
        xcode_generated_paths = xcode_generated_paths,
        xcode_target = xcode_target,
    )

    linker_inputs_dto, link_params = _linker_inputs_to_dto(
        xcode_target.linker_inputs,
        actions = actions,
        compile_targets = xcode_target._compile_targets,
        generated_framework_search_paths = generated_framework_search_paths,
        is_framework = (
            xcode_target.product.type == "com.apple.product-type.framework"
        ),
        link_params_processor = link_params_processor,
        name = name,
        params_index = params_index,
        platform = xcode_target.platform,
        product = xcode_target.product,
        rule_name = rule_name,
        xcode_generated_paths_file = xcode_generated_paths_file,
    )

    if xcode_target.c_params:
        dto["8"] = xcode_target.c_params.path
    if xcode_target.cxx_params:
        dto["9"] = xcode_target.cxx_params.path
    if xcode_target.swift_params:
        dto["0"] = xcode_target.swift_params.path

    set_if_true(
        dto,
        "f",
        xcode_target._c_has_fortify_source,
    )
    set_if_true(
        dto,
        "F",
        xcode_target._cxx_has_fortify_source,
    )

    set_if_true(
        dto,
        "b",
        _build_settings_to_dto(
            build_mode = build_mode,
            linker_products_map = linker_products_map,
            xcode_generated_paths = xcode_generated_paths,
            xcode_target = xcode_target,
        ),
    )

    set_if_true(
        dto,
        "m",
        bool(xcode_target._modulemaps),
    )
    set_if_true(
        dto,
        "r",
        [
            id
            for id in inputs.resource_bundle_dependencies.to_list()
            if id not in excluded_targets
        ],
    )
    set_if_true(
        dto,
        "i",
        _inputs_to_dto(
            inputs,
            focused_labels = focused_labels,
            unfocused_labels = unfocused_labels,
        ),
    )
    set_if_true(
        dto,
        "5",
        linker_inputs_dto,
    )

    if link_params:
        dto["6"] = link_params.path

    set_if_true(
        dto,
        "e",
        [
            id
            for id in xcode_target._extensions
            if id not in excluded_targets
        ],
    )
    set_if_true(
        dto,
        "a",
        [
            id
            for id in xcode_target._app_clips
            if id not in excluded_targets
        ],
    )

    if should_include_outputs:
        set_if_true(
            dto,
            "o",
            _outputs_to_dto(outputs = xcode_target.outputs),
        )

    set_if_true(
        dto,
        "7",
        additional_scheme_target_ids,
    )

    replaced_dependencies = []

    def _handle_dependency(id):
        merged_dependency = target_merges.get(id, None)
        if merged_dependency:
            dependency = merged_dependency[0]
            replaced_dependencies.append(dependency)
        else:
            dependency = id
        return dependency

    dependencies = [
        _handle_dependency(id)
        for id in xcode_target._dependencies.to_list()
        if (id not in excluded_targets and
            # TODO: Move dependency filtering here (out of the generator)
            # In BwX mode there can only be one merge destination
            target_merges.get(id, [id])[0] != xcode_target.id)
    ]

    set_if_true(
        dto,
        "d",
        [id for id in dependencies if id not in bwx_unfocused_dependencies],
    )

    return dto, replaced_dependencies, link_params

def _build_settings_to_dto(
        *,
        build_mode,
        linker_products_map,
        xcode_generated_paths,
        xcode_target):
    build_settings = structs.to_dict(xcode_target._build_settings)

    _set_bazel_outputs_product(
        build_mode = build_mode,
        build_settings = build_settings,
        xcode_target = xcode_target,
    )
    _set_preview_framework_paths(
        build_mode = build_mode,
        build_settings = build_settings,
        linker_products_map = linker_products_map,
        xcode_target = xcode_target,
    )
    _set_swift_include_paths(
        build_mode = build_mode,
        build_settings = build_settings,
        xcode_generated_paths = xcode_generated_paths,
        xcode_target = xcode_target,
    )

    return build_settings

def _inputs_to_dto(inputs, *, focused_labels, unfocused_labels):
    """Generates a target DTO value for inputs.

    Args:
        inputs: A value returned from `input_files.to_xcode_target_inputs`.
        focused_labels: Maps to `xcodeproj.focused_targets`.
        unfocused_labels: Maps to `xcodeproj.unfocused_targets`.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
        *   `resources`: A `list` of `FilePath`s for `resources`.
        *   `entitlements`: An optional `FilePath` for `entitlements`.
    """
    ret = {}

    def _process_attr(attr, key):
        value = getattr(inputs, attr)
        if value:
            ret[key] = [
                file.path
                for file in value
            ]

    _process_attr("srcs", "s")
    _process_attr("non_arc_srcs", "n")
    _process_attr("hdrs", "h")

    has_focused_labels = bool(focused_labels)

    if inputs.resources:
        # resources of unfocused targets should be excluded
        filtered_resources = depset(
            transitive = [
                resource
                for owner, resource in inputs.resources.to_list()
                if not owner or not (
                    owner in unfocused_labels or
                    (has_focused_labels and owner not in focused_labels)
                )
            ],
        ).to_list()

        set_if_true(
            ret,
            "r",
            filtered_resources,
        )

    if inputs.folder_resources:
        filtered_folder_resources = depset(
            transitive = [
                resource
                for owner, resource in inputs.folder_resources.to_list()
                if not owner or not (
                    owner in unfocused_labels or
                    (has_focused_labels and owner not in focused_labels)
                )
            ],
        ).to_list()

        set_if_true(
            ret,
            "f",
            filtered_folder_resources,
        )

    return ret

def _linker_inputs_to_dto(
        linker_inputs,
        *,
        actions,
        compile_targets,
        generated_framework_search_paths,
        is_framework,
        link_params_processor,
        name,
        params_index,
        platform,
        product,
        rule_name,
        xcode_generated_paths_file):
    if not linker_inputs:
        return ({}, None)

    if compile_targets:
        self_product_paths = [compile_target.product.file.path for compile_target in compile_targets if compile_target.product.file]
    else:
        # Handle `{cc,swift}_{binary,test}` with `srcs` case
        self_product_paths = [paths.join(
            product.package_dir,
            "lib{}.lo".format(name),
        )]

    generated_product_paths_file = actions.declare_file(
        "{}-params/{}.{}.generated_product_paths_file.json".format(
            rule_name,
            name,
            params_index,
        ),
    )
    actions.write(
        output = generated_product_paths_file,
        content = json.encode(self_product_paths),
    )

    ret = {}
    set_if_true(
        ret,
        "d",
        [file.dirname for file in linker_inputs.dynamic_frameworks],
    )

    if linker_inputs.link_args:
        generated_framework_search_paths_file = actions.declare_file(
            "{}-params/{}.{}.generated_framework_search_paths.json".format(
                rule_name,
                name,
                params_index,
            ),
        )
        actions.write(
            output = generated_framework_search_paths_file,
            content = json.encode(generated_framework_search_paths),
        )

        link_params = actions.declare_file(
            "{}-params/{}.{}.link.params".format(
                rule_name,
                name,
                params_index,
            ),
        )

        args = actions.args()
        args.add(xcode_generated_paths_file)
        args.add(generated_framework_search_paths_file)
        args.add("1" if is_framework else "0")
        args.add(generated_product_paths_file)
        args.add(platforms.to_swift_triple(platform))
        args.add(link_params)

        actions.run(
            executable = link_params_processor,
            arguments = [args] + linker_inputs.link_args,
            mnemonic = "ProcessLinkParams",
            progress_message = "Generating %{output}",
            inputs = (
                [
                    xcode_generated_paths_file,
                    generated_framework_search_paths_file,
                    generated_product_paths_file,
                ] + list(linker_inputs.link_args_inputs)
            ),
            outputs = [link_params],
        )
    else:
        link_params = None

    return (ret, link_params)

def _outputs_to_dto(*, outputs):
    dto = {}

    if outputs.swiftmodule:
        dto["s"] = _swift_to_dto(outputs)

    return dto

def _product_to_dto(product):
    dto = {
        "n": product.name,
        "t": product.type,
    }

    set_if_true(dto, "p", product.file_path)
    set_if_true(
        dto,
        "a",
        [
            normalized_file_path(
                file,
                folder_type_extensions = FRAMEWORK_EXTENSIONS,
            )
            for file in product._additional_files.to_list()
        ],
    )
    set_if_true(dto, "r", product.is_resource_bundle)
    set_if_true(dto, "m", product.module_name_attribute)
    set_if_true(dto, "e", product.executable_name)

    return dto

def _swift_to_dto(outputs):
    dto = {
        "m": outputs.swiftmodule.path,
    }

    if outputs.swift_generated_header:
        dto["h"] = outputs.swift_generated_header.path

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
        fail("""\
Target '{}' requires `ObjcProvider` or `CcInfo`\
""".format(xcode_target.label))
    return linker_inputs.static_libraries

xcode_targets = struct(
    get_top_level_static_libraries = _get_top_level_static_libraries,
    make = _make_xcode_target,
    merge = _merge_xcode_target,
    to_dto = _xcode_target_to_dto,
)

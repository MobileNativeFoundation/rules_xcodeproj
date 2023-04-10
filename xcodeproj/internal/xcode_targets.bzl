"""Module containing functions dealing with the `Target` DTO."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:structs.bzl", "structs")
load(":collections.bzl", "set_if_true", "uniq")
load(
    ":files.bzl",
    "FRAMEWORK_EXTENSIONS",
    "build_setting_path",
    "file_path",
    "file_path_to_dto",
    "normalized_file_path",
)
load(":platform.bzl", "platform_info")

def _make_xcode_target(
        *,
        id,
        label,
        configuration,
        compile_target = None,
        package_bin_dir,
        platform,
        product,
        is_swift,
        test_host = None,
        build_settings,
        conlyopts = [],
        cxxopts = [],
        swiftcopts = [],
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
        should_create_xcode_target = True,
        xcode_required_targets = depset()):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        compile_target: The `xcode_target` that was merged into this target.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: The value returned from `process_platform`.
        product: The value returned from `process_product`.
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: A value returned from `process_opts`, or `None`.
        conlyopts: A `list` of processed C compiler options.
        cxxopts: A `list` of processed C++ compiler options.
        swiftcopts: A `list` of processed Swift compiler options.
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
        should_create_xcode_target: `True` if this `xcode_target` should be
            included in the generated Xcode project. This can be `False` for
            targets like header-only libraries.
        xcode_required_targets: A `depset` of values returned from
            `xcode_targets.make`, which represent targets that are required in
            BwX mode.

    Returns:
        A mostly opaque `struct` that can be passed to `xcode_targets.to_dto`.
    """
    product = (
        _to_xcode_target_product(product) if not compile_target else product
    )

    return struct(
        _compile_target = compile_target,
        _package_bin_dir = package_bin_dir,
        _test_host = test_host,
        _build_settings = struct(**build_settings),
        _conlyopts = tuple(conlyopts),
        _cxxopts = tuple(cxxopts),
        _swiftcopts = tuple(swiftcopts),
        _search_paths = search_paths,
        _modulemaps = modulemaps,
        _swiftmodules = tuple(swiftmodules),
        _watch_application = watch_application,
        _extensions = tuple(extensions),
        _app_clips = tuple(app_clips),
        _dependencies = dependencies,
        id = id,
        label = label,
        configuration = configuration,
        platform = platform,
        product = product,
        linker_inputs = (
            _to_xcode_target_linker_inputs(linker_inputs) if not compile_target else linker_inputs
        ),
        lldb_context = lldb_context,
        lldb_context_key = _lldb_context_key(
            platform = platform,
            product = product,
        ),
        inputs = (
            _to_xcode_target_inputs(inputs) if not compile_target else inputs
        ),
        is_swift = is_swift,
        outputs = (
            _to_xcode_target_outputs(outputs) if not compile_target else outputs
        ),
        infoplist = infoplist,
        should_create_xcode_target = should_create_xcode_target,
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

    product_basename = paths.basename(fp.path)
    base_key = "{} {}".format(
        platform_info.to_lldb_context_triple(platform),
        product_basename,
    )

    if not product.type in _BUNDLE_TYPES:
        return base_key

    executable_name = product.executable_name
    if not executable_name:
        executable_name = paths.split_extension(product_basename)[0]

    if platform_info.is_platform_type(
        platform,
        apple_common.platform_type.macos,
    ):
        return "{}/Contents/MacOS/{}".format(base_key, executable_name)

    return "{}/{}".format(base_key, executable_name)

def _to_xcode_target_inputs(inputs):
    return struct(
        srcs = inputs.srcs,
        non_arc_srcs = inputs.non_arc_srcs,
        hdrs = inputs.hdrs,
        pch = inputs.pch,
        entitlements = inputs.entitlements,
        has_c_sources = inputs.has_c_sources,
        has_cxx_sources = inputs.has_cxx_sources,
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
        type = product.type,
        file = product.file,
        basename = product.basename,
        file_path = product.file_path,
        executable = product.executable,
        executable_name = product.executable_name,
        package_dir = product.package_dir,
        additional_product_files = tuple(),
        framework_files = product.framework_files,
        is_resource_bundle = product.is_resource_bundle,
        _additional_files = product.framework_files,
    )

def _merge_xcode_target(*, src, dest):
    """Creates a new `xcode_target` by merging the values of `src` into `dest`.

    Args:
        src: The `xcode_target` to merge into `dest`.
        dest: The `xcode_target` being merged into.

    Returns:
        A value as returned by `xcode_targets.make`.
    """

    build_settings = dict(structs.to_dict(src._build_settings))
    build_settings = dicts.add(
        structs.to_dict(dest._build_settings),
        build_settings,
    )

    return _make_xcode_target(
        id = dest.id,
        label = dest.label,
        configuration = dest.configuration,
        compile_target = src,
        package_bin_dir = dest._package_bin_dir,
        platform = src.platform,
        product = _merge_xcode_target_product(
            src = src.product,
            dest = dest.product,
        ),
        is_swift = src.is_swift,
        test_host = dest._test_host,
        build_settings = build_settings,
        conlyopts = src._conlyopts or dest._conlyopts,
        cxxopts = src._cxxopts or dest._cxxopts,
        swiftcopts = src._swiftcopts or dest._swiftcopts,
        search_paths = dest._search_paths,
        modulemaps = src._modulemaps,
        swiftmodules = src._swiftmodules,
        inputs = _merge_xcode_target_inputs(
            src = src.inputs,
            dest = dest.inputs,
        ),
        linker_inputs = dest.linker_inputs,
        infoplist = dest.infoplist,
        watch_application = dest._watch_application,
        extensions = dest._extensions,
        app_clips = dest._app_clips,
        dependencies = depset(
            transitive = [dest._dependencies, src._dependencies],
        ),
        transitive_dependencies = dest.transitive_dependencies,
        outputs = _merge_xcode_target_outputs(
            src = src.outputs,
            dest = dest.outputs,
        ),
        lldb_context = dest.lldb_context,
        xcode_required_targets = dest.xcode_required_targets,
    )

def _merge_xcode_target_inputs(*, src, dest):
    return struct(
        srcs = src.srcs,
        non_arc_srcs = src.non_arc_srcs,
        hdrs = dest.hdrs,
        pch = src.pch,
        entitlements = dest.entitlements,
        has_c_sources = src.has_c_sources,
        has_cxx_sources = src.has_cxx_sources,
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

def _merge_xcode_target_outputs(*, src, dest):
    return struct(
        dsym_files = dest.dsym_files,
        linking_output_group_name = dest.linking_output_group_name,
        swiftmodule = src.swiftmodule,
        swift_generated_header = src.swift_generated_header,
        product_file = dest.product_file,
        product_path = dest.product_path,
        products_output_group_name = dest.products_output_group_name,
        transitive_infoplists = dest.transitive_infoplists,
    )

def _merge_xcode_target_product(*, src, dest):
    return struct(
        name = dest.name,
        type = dest.type,
        file = dest.file,
        basename = dest.basename,
        file_path = dest.file_path,
        executable = dest.executable,
        executable_name = dest.executable_name,
        package_dir = dest.package_dir,
        framework_files = depset(
            transitive = [dest.framework_files, src.framework_files],
        ),
        additional_product_files = tuple([src.file]),
        is_resource_bundle = dest.is_resource_bundle,
        _additional_files = depset(
            [src.file],
            transitive = [dest._additional_files, src._additional_files],
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
    "com.apple.product-type.app-extension": None,
    "com.apple.product-type.app-extension.messages": None,
    "com.apple.product-type.extensionkit-extension": None,
    "com.apple.product-type.framework": None,
    "com.apple.product-type.bundle.ui-testing": None,
    "com.apple.product-type.bundle.unit-test": None,
    "com.apple.product-type.tv-app-extension": None,
    "com.apple.product-type.application.watchapp": None,
    "com.apple.product-type.application.watchapp2": None,
    "com.apple.product-type.watchkit-extension": None,
    "com.apple.product-type.watchkit2-extension": None,
}

def _set_swift_include_paths(
        *,
        build_settings,
        xcode_generated_paths,
        xcode_target):
    if not xcode_target.is_swift:
        return

    def _handle_swiftmodule_path(file):
        path = file.path
        bs_path = xcode_generated_paths.get(path)
        if not bs_path:
            bs_path = path
        include_path = paths.dirname(bs_path)

        if include_path.find(" ") != -1:
            include_path = '"{}"'.format(include_path)

        return include_path

    includes = uniq([
        _handle_swiftmodule_path(file)
        for file in xcode_target._swiftmodules
    ])

    swiftmodule = xcode_target.outputs.swiftmodule
    if (swiftmodule and
        xcode_target.product.type in _PREVIEWS_ENABLED_PRODUCT_TYPES):
        build_settings["PREVIEWS_SWIFT_INCLUDE_PATH__"] = ""
        build_settings["PREVIEWS_SWIFT_INCLUDE_PATH__NO"] = ""
        build_settings["PREVIEWS_SWIFT_INCLUDE_PATH__YES"] = (
            _handle_swiftmodule_path(swiftmodule)
        )
        includes.insert(
            0,
            "$(PREVIEWS_SWIFT_INCLUDE_PATH__$(ENABLE_PREVIEWS))",
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
        additional_scheme_target_ids = None,
        build_mode,
        ctx,
        is_fixture,
        label,
        link_params_processor,
        linker_products_map,
        params_index,
        should_include_outputs,
        excluded_targets = {},
        target_merges = {},
        unfocused_dependencies,
        xcode_configurations,
        xcode_generated_paths,
        xcode_generated_paths_file):
    inputs = xcode_target.inputs
    name = label.name
    is_unfocused_dependency = xcode_target.id in unfocused_dependencies

    dto = {
        "n": name,
        "l": str(label),
        "c": xcode_target.configuration,
        "1": xcode_target._package_bin_dir,
        "2": platform_info.to_dto(xcode_target.platform),
        "p": _product_to_dto(xcode_target.product),
    }

    if xcode_configurations != ["Debug"]:
        dto["x"] = xcode_configurations

    if xcode_target._compile_target:
        dto["3"] = {
            "i": xcode_target._compile_target.id,
            "n": xcode_target._compile_target.label.name,
        }

    if not xcode_target.is_swift:
        dto["s"] = False

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
        ctx = ctx,
        compile_target = xcode_target._compile_target,
        generated_framework_search_paths = generated_framework_search_paths,
        is_framework = (
            xcode_target.product.type == "com.apple.product-type.framework"
        ),
        link_params_processor = link_params_processor,
        linker_inputs = xcode_target.linker_inputs,
        name = name,
        params_index = params_index,
        platform = xcode_target.platform,
        product = xcode_target.product,
        xcode_generated_paths_file = xcode_generated_paths_file,
    )

    set_if_true(
        dto,
        "b",
        _build_settings_to_dto(
            build_mode = build_mode,
            link_params = link_params,
            linker_products_map = linker_products_map,
            xcode_generated_paths = xcode_generated_paths,
            xcode_target = xcode_target,
        ),
    )

    conlyopts = xcode_target._conlyopts
    cxxopts = xcode_target._cxxopts
    if is_fixture:
        # Until we no longer support Bazel 5, we need to remove the
        # `BAZEL_CURRENT_REPOSITORY` define so Bazel 5 and 6 have the same
        # fixture
        new_conlyopts = []
        new_cxxopts = []
        for opt in conlyopts:
            if opt.startswith("-DBAZEL_CURRENT_REPOSITORY="):
                continue
            new_conlyopts.append(opt)
        for opt in cxxopts:
            if opt.startswith("-DBAZEL_CURRENT_REPOSITORY="):
                continue
            new_cxxopts.append(opt)
        conlyopts = new_conlyopts
        cxxopts = new_cxxopts

    set_if_true(dto, "8", conlyopts)
    set_if_true(dto, "9", cxxopts)
    set_if_true(dto, "0", xcode_target._swiftcopts)

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
    set_if_true(dto, "i", _inputs_to_dto(inputs))
    set_if_true(
        dto,
        "5",
        linker_inputs_dto,
    )
    set_if_true(
        dto,
        "6",
        file_path_to_dto(file_path(link_params)),
    )
    set_if_true(
        dto,
        "4",
        file_path_to_dto(file_path(xcode_target.infoplist)),
    )
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
            _outputs_to_dto(
                outputs = xcode_target.outputs,
                product = xcode_target.product,
            ),
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
        [id for id in dependencies if id not in unfocused_dependencies],
    )

    return dto, replaced_dependencies, link_params

def _build_settings_to_dto(
        *,
        build_mode,
        link_params,
        linker_products_map,
        xcode_generated_paths,
        xcode_target):
    build_settings = structs.to_dict(xcode_target._build_settings)

    if link_params:
        build_settings["LINK_PARAMS_FILE"] = build_setting_path(
            path = link_params.path,
        )

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
        build_settings = build_settings,
        xcode_generated_paths = xcode_generated_paths,
        xcode_target = xcode_target,
    )

    return build_settings

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
    """
    ret = {}

    def _process_attr(attr, key):
        value = getattr(inputs, attr)
        if value:
            ret[key] = [
                file_path_to_dto(file_path(file))
                for file in value.to_list()
            ]

    _process_attr("srcs", "s")
    _process_attr("non_arc_srcs", "n")
    _process_attr("hdrs", "h")

    if inputs.pch:
        ret["p"] = file_path_to_dto(file_path(inputs.pch))

    if inputs.entitlements:
        ret["e"] = file_path_to_dto(file_path(inputs.entitlements))

    if inputs.resources:
        set_if_true(
            ret,
            "r",
            [file_path_to_dto(fp) for fp in inputs.resources.to_list()],
        )

    if inputs.folder_resources:
        set_if_true(
            ret,
            "f",
            [file_path_to_dto(fp) for fp in inputs.folder_resources.to_list()],
        )

    return ret

def _linker_inputs_to_dto(
        linker_inputs,
        *,
        ctx,
        compile_target,
        generated_framework_search_paths,
        is_framework,
        link_params_processor,
        name,
        params_index,
        platform,
        product,
        xcode_generated_paths_file):
    if not linker_inputs:
        return ({}, None)

    if compile_target:
        self_product_path = compile_target.product.file.path
    else:
        # Handle `{cc,swift}_{binary,test}` with `srcs` case
        self_product_path = paths.join(
            product.package_dir,
            "lib{}.lo".format(name),
        )

    ret = {}
    set_if_true(
        ret,
        "d",
        [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in linker_inputs.dynamic_frameworks
        ],
    )

    if linker_inputs.link_args:
        generated_framework_search_paths_file = ctx.actions.declare_file(
            "{}-params/{}.{}.generated_framework_search_paths.json".format(
                ctx.attr.name,
                name,
                params_index,
            ),
        )
        ctx.actions.write(
            output = generated_framework_search_paths_file,
            content = json.encode(generated_framework_search_paths),
        )

        def _create_link_sub_params(idx, link_args):
            output = ctx.actions.declare_file(
                "{}-params/{}.{}.link.sub-{}.params".format(
                    ctx.attr.name,
                    name,
                    params_index,
                    idx,
                ),
            )
            ctx.actions.write(
                output = output,
                content = link_args,
            )
            return output

        link_sub_params = [
            _create_link_sub_params(idx, link_args)
            for idx, link_args in enumerate(linker_inputs.link_args)
        ]

        link_params = ctx.actions.declare_file(
            "{}-params/{}.{}.link.params".format(
                ctx.attr.name,
                name,
                params_index,
            ),
        )

        args = ctx.actions.args()
        args.add(xcode_generated_paths_file)
        args.add(generated_framework_search_paths_file)
        args.add("1" if is_framework else "0")
        args.add(self_product_path)
        args.add(platform_info.to_swift_triple(platform))
        args.add(link_params)
        args.add_all(link_sub_params)

        ctx.actions.run(
            executable = link_params_processor,
            arguments = [args],
            mnemonic = "ProcessLinkParams",
            progress_message = "Generating %{output}",
            inputs = (
                [
                    xcode_generated_paths_file,
                    generated_framework_search_paths_file,
                ] + link_sub_params + list(linker_inputs.link_args_inputs)
            ),
            outputs = [link_params],
        )
    else:
        link_params = None

    return (ret, link_params)

def _outputs_to_dto(*, outputs, product):
    dto = {}

    if outputs.product_file and product.basename:
        dto["p"] = product.basename

    if outputs.swiftmodule:
        dto["s"] = _swift_to_dto(outputs)

    return dto

def _product_to_dto(product):
    dto = {
        "n": product.name,
        "t": product.type,
    }

    set_if_true(dto, "p", file_path_to_dto(product.file_path))
    set_if_true(
        dto,
        "a",
        [
            file_path_to_dto(
                normalized_file_path(
                    file,
                    folder_type_extensions = FRAMEWORK_EXTENSIONS,
                ),
            )
            for file in product._additional_files.to_list()
        ],
    )
    set_if_true(dto, "r", product.is_resource_bundle)
    set_if_true(dto, "e", product.executable_name)

    return dto

def _swift_to_dto(outputs):
    dto = {
        "m": file_path_to_dto(file_path(outputs.swiftmodule)),
    }

    if outputs.swift_generated_header:
        dto["h"] = file_path_to_dto(file_path(outputs.swift_generated_header))

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

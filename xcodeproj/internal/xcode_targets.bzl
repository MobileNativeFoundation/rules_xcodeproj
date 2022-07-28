"""Module containing functions dealing with the `Target` DTO."""

load(":collections.bzl", "set_if_true")
load(":files.bzl", "file_path", "file_path_to_dto")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(":product.bzl", "product_to_dto")
load(":target_search_paths.bzl", "target_search_paths")

def _make(
        *,
        id,
        name,
        label,
        configuration,
        package_bin_dir,
        platform,
        product,
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
        outputs):
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
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: A value returned from `target_search_paths.make`, or
            `None`.
        modulemaps: The value returned from `_process_modulemaps`.
        swiftmodules: The value returned from `_process_swiftmodules`.
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

    Returns:
        A mostly opaque `struct` that can be passed to `xcode_targets.to_dto`.
    """
    return struct(
        _name = name,
        _configuration = configuration,
        _package_bin_dir = package_bin_dir,
        _platform = platform,
        _is_swift = is_swift,
        _test_host = test_host,
        _build_settings = struct(**build_settings),
        _search_paths = search_paths,
        _modulemaps = modulemaps,
        _swiftmodules = tuple(swiftmodules),
        _linker_inputs = linker_inputs,
        _infoplist = infoplist,
        _watch_application = watch_application,
        _extensions = tuple(extensions),
        _app_clips = tuple(app_clips),
        _dependencies = dependencies,
        _outputs = outputs,
        id = id,
        label = label,
        product = product,
        inputs = inputs,
        transitive_dependencies = transitive_dependencies,
    )

def _to_dto(
        xcode_target,
        *,
        is_unfocused_dependency = False,
        unfocused_targets = {}):
    inputs = xcode_target.inputs

    dto = {
        "name": xcode_target._name,
        "label": str(xcode_target.label),
        "configuration": xcode_target._configuration,
        "package_bin_dir": xcode_target._package_bin_dir,
        "platform": platform_info.to_dto(xcode_target._platform),
        "product": product_to_dto(xcode_target.product),
    }

    if not xcode_target._is_swift:
        dto["is_swift"] = False

    if is_unfocused_dependency:
        dto["is_unfocused_dependency"] = True

    if xcode_target._test_host not in unfocused_targets:
        set_if_true(dto, "test_host", xcode_target._test_host)

    if xcode_target._watch_application not in unfocused_targets:
        set_if_true(dto, "watch_application", xcode_target._watch_application)

    set_if_true(dto, "build_settings", xcode_target._build_settings)
    set_if_true(
        dto,
        "search_paths",
        target_search_paths.to_dto(xcode_target._search_paths),
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
    set_if_true(dto, "inputs", input_files.to_dto(inputs))
    set_if_true(
        dto,
        "linker_inputs",
        linker_input_files.to_dto(xcode_target._linker_inputs),
    )
    set_if_true(
        dto,
        "info_plist",
        file_path_to_dto(file_path(xcode_target._infoplist)),
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
    set_if_true(dto, "outputs", output_files.to_dto(xcode_target._outputs))

    return dto

xcode_targets = struct(
    make = _make,
    to_dto = _to_dto,
)

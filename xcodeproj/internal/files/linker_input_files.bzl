"""Module containing functions dealing with target linker input files."""

load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_DEPSET", "EMPTY_TUPLE")

_SKIP_INPUT_EXTENSIONS = {
    "a": None,
    "app": None,
    "appex": None,
    "bundle": None,
    "dylib": None,
    "framework": None,
    "lo": None,
    "objlist": None,
    "swiftmodule": None,
    "xctest": None,
}

def _collect_linker_inputs(
        *,
        automatic_target_info,
        target,
        compilation_providers,
        is_top_level = False):
    """Collects linker input files for a target.

    Args:
        automatic_target_info:  The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        compilation_providers: A value returned by
            `compilation_providers.collect`.
        is_top_level: Whether `target` is the top-level target.
        target: The `Target`.

    Returns:
        An opaque `struct` containing the linker input files for a target. The
        `struct` should be passed to functions on `linker_input_files` to
        retrieve its contents.
    """
    objc_libraries, cc_linker_inputs = _extract_libraries(
        compilation_providers = compilation_providers,
    )

    if is_top_level:
        primary_static_library = None
        top_level_values = _extract_top_level_values(
            target = target,
            automatic_target_info = automatic_target_info,
            compilation_providers = compilation_providers,
            objc_libraries = objc_libraries,
            cc_linker_inputs = cc_linker_inputs,
        )
    else:
        primary_static_library = _compute_primary_static_library(
            objc_libraries = objc_libraries,
            cc_linker_inputs = cc_linker_inputs,
        )
        top_level_values = None

    return struct(
        _cc_linker_inputs = tuple(cc_linker_inputs),
        _compilation_providers = compilation_providers,
        _objc_libraries = tuple(objc_libraries),
        _primary_static_library = primary_static_library,
        _top_level_values = top_level_values,
    )

def _merge_linker_inputs(*, compilation_providers):
    return _collect_linker_inputs(
        target = None,
        compilation_providers = compilation_providers,
    )

def _compute_primary_static_library(
        *,
        objc_libraries,
        cc_linker_inputs):
    # Ideally we would only return the static library that is owned by this
    # target, but sometimes another rule creates the output and this rule
    # outputs it. So far the first library has always been the correct one.
    if objc_libraries:
        generated_libraries = [f for f in objc_libraries if not f.is_source]
        ignore_swift_protobuf = len(generated_libraries) > 1
        for library in generated_libraries:
            if (ignore_swift_protobuf and
                library.basename == "libSwiftProtobuf.a"):
                # rules_swift sometimes places SwiftProtobuf before the actual
                # library, so we need to ignore it. When parsing
                # `cc_linker_inputs`, we correctly get the "newest" library
                # first.
                continue
            return library
    elif cc_linker_inputs:
        for input in cc_linker_inputs:
            for library in input.libraries:
                # TODO: Account for all of the different linking strategies
                # here: https://github.com/bazelbuild/bazel/blob/986ef7b68d61b1573d9c2bb1200585d07ad24691/src/main/java/com/google/devtools/build/lib/rules/cpp/CcLinkingHelper.java#L951-L1009
                static_library = (library.static_library or
                                  library.pic_static_library)
                if not static_library:
                    continue
                if static_library.is_source:
                    continue
                return static_library
    return None

def _extract_libraries(compilation_providers):
    if compilation_providers.objc:
        objc = compilation_providers.objc
        objc_libraries = [
            file
            for file in depset(
                transitive = [
                    objc.library,
                    objc.imported_library,
                ],
                order = "topological",
            ).to_list()
        ]
        cc_linker_inputs = []
    elif compilation_providers.cc_info:
        cc_info = compilation_providers.cc_info
        cc_linker_inputs = cc_info.linking_context.linker_inputs.to_list()
        objc_libraries = []
    else:
        cc_linker_inputs = []
        objc_libraries = []

    return (objc_libraries, cc_linker_inputs)

def _extract_top_level_values(
        *,
        target,
        automatic_target_info,
        compilation_providers,
        objc_libraries,
        cc_linker_inputs):
    link_args = None
    link_args_inputs = None
    preview_link_input_files = EMPTY_TUPLE
    if target:
        for action in target.actions:
            if action.mnemonic in automatic_target_info.link_mnemonics:
                link_args = action.args
                action_inputs = action.inputs.to_list()
                link_args_inputs = tuple([
                    f
                    for f in action_inputs
                    # TODO: Generalize this or add to
                    # `XcodeProjAutomaticTargetProcessingInfo` somehow?
                    if f.path.endswith("-linker.objlist")
                ])

                # The native link response retains the actual dynamic-library
                # paths, including Bazel's solib symlinks. Preparing only their
                # resolved framework products does not create those paths.
                # Keep these out of ProcessLinkParams inputs so generation
                # does not build dependencies before a Preview requests bl.
                dynamic_libraries = {
                    library.dynamic_library: None
                    for input in cc_linker_inputs
                    for library in input.libraries
                    if library.dynamic_library
                }
                dynamic_libraries.update({
                    file: None
                    for file in getattr(compilation_providers, "preview_dynamic_library_files", EMPTY_DEPSET).to_list()
                })
                if compilation_providers.objc:
                    dynamic_libraries.update({
                        file: None
                        for file in compilation_providers.objc.dynamic_framework_file.to_list()
                    })
                preview_link_input_files = tuple([
                    file
                    for file in action_inputs
                    if file in dynamic_libraries
                ])
                break

    if compilation_providers.objc:
        objc = compilation_providers.objc
        static_frameworks = [
            file
            for file in objc.static_framework_file.to_list()
            if file.is_source
        ]
        static_libraries = [
            file
            for file in objc_libraries
        ]

        dynamic_frameworks = objc.dynamic_framework_file.to_list()
        additional_input_files = _process_additional_inputs(
            objc.link_inputs.to_list(),
        )
    elif compilation_providers.cc_info:
        dynamic_frameworks = []
        static_frameworks = []

        static_libraries = []
        additional_input_files = []
        for input in cc_linker_inputs:
            additional_input_files.extend(_process_additional_inputs(
                input.additional_inputs,
            ))
            for library in input.libraries:
                if library.dynamic_library:
                    if library.dynamic_library.dirname.endswith(".framework"):
                        dynamic_frameworks.append(
                            library.resolved_symlink_dynamic_library or
                            library.dynamic_library,
                        )
                        continue

                if library.static_library:
                    if library.static_library.dirname.endswith(".framework"):
                        static_frameworks.append(library.static_library)
                        continue

                # TODO: Account for all of the different linking strategies
                # here: https://github.com/bazelbuild/bazel/blob/986ef7b68d61b1573d9c2bb1200585d07ad24691/src/main/java/com/google/devtools/build/lib/rules/cpp/CcLinkingHelper.java#L951-L1009
                static_library = (library.static_library or
                                  library.pic_static_library)
                if not static_library:
                    continue
                static_libraries.append(static_library)

        # Dynamic frameworks from `AppleDynamicFrameworkInfo`
        dynamic_frameworks.extend(
            compilation_providers.framework_files.to_list(),
        )
    else:
        return struct(
            _additional_input_files = EMPTY_TUPLE,
            _static_frameworks = EMPTY_TUPLE,
            dynamic_frameworks = EMPTY_TUPLE,
            link_args = link_args,
            link_args_inputs = link_args_inputs,
            preview_link_input_files = preview_link_input_files,
            static_libraries = EMPTY_TUPLE,
        )

    return struct(
        _additional_input_files = tuple(additional_input_files),
        _static_frameworks = tuple(static_frameworks),
        dynamic_frameworks = tuple(dynamic_frameworks),
        link_args = link_args,
        link_args_inputs = link_args_inputs,
        preview_link_input_files = preview_link_input_files,
        static_libraries = tuple(static_libraries),
    )

def _process_additional_inputs(files):
    return [
        file
        for file in files
        if not file.is_source and file.extension not in _SKIP_INPUT_EXTENSIONS
    ]

def _collect_libraries(
        *,
        objc_libraries,
        cc_linker_inputs,
        include_source_libraries = False):
    libraries = []
    if objc_libraries:
        for library in objc_libraries:
            if library.is_source and not include_source_libraries:
                continue
            libraries.append(library)
    elif cc_linker_inputs:
        for input in cc_linker_inputs:
            for library in input.libraries:
                # TODO: Account for all of the different linking strategies
                # here: https://github.com/bazelbuild/bazel/blob/986ef7b68d61b1573d9c2bb1200585d07ad24691/src/main/java/com/google/devtools/build/lib/rules/cpp/CcLinkingHelper.java#L951-L1009
                static_library = (library.static_library or
                                  library.pic_static_library)
                if not static_library:
                    continue
                if (static_library.is_source and
                    not include_source_libraries):
                    continue
                libraries.append(static_library)
    return libraries

def _get_transitive_static_libraries_for_bwx(linker_inputs):
    return _collect_libraries(
        objc_libraries = linker_inputs._objc_libraries,
        cc_linker_inputs = linker_inputs._cc_linker_inputs,
    )

def _get_static_library_preview_libraries(linker_inputs):
    primary_static_library = linker_inputs._primary_static_library
    seen = {}
    libraries = []
    for library in _collect_libraries(
        objc_libraries = linker_inputs._objc_libraries,
        cc_linker_inputs = linker_inputs._cc_linker_inputs,
        # Source artifacts are prebuilt link inputs (for example, `cc_import`
        # archives), not Xcode-built products. They still belong in the
        # Preview link closure. Primary-product selection continues to ignore
        # source artifacts, and the selected generated product is filtered
        # immediately below.
        include_source_libraries = True,
    ):
        if library == primary_static_library or library in seen:
            continue
        seen[library] = None
        libraries.append(library)
    return libraries

def _get_static_library_preview_force_load_libraries(
        *,
        libraries,
        linker_inputs):
    """Returns Preview libraries whose Bazel link semantics require force-load."""
    compilation_providers = linker_inputs._compilation_providers

    if compilation_providers.objc:
        candidates = getattr(
            compilation_providers.objc,
            "force_load_library",
            depset(),
        ).to_list()
    else:
        candidates = []
        for input in linker_inputs._cc_linker_inputs:
            for library in input.libraries:
                if not library.alwayslink:
                    continue
                static_library = (library.static_library or
                                  library.pic_static_library)
                if static_library:
                    candidates.append(static_library)

    force_load_set = {file: None for file in candidates}
    return [file for file in libraries if file in force_load_set]

def _dynamic_framework_name(file):
    framework_dir = file.dirname
    if not framework_dir.endswith(".framework"):
        return None

    framework_name = framework_dir.rsplit("/", 1)[-1][:-len(".framework")]
    if file.basename != framework_name:
        return None
    return framework_name

def _get_static_library_preview_dynamic_frameworks(linker_inputs):
    """Returns transitive dynamic framework executables in linker order."""
    compilation_providers = linker_inputs._compilation_providers

    if compilation_providers.objc:
        candidates = compilation_providers.objc.dynamic_framework_file.to_list()
        fallback_candidates = []
    else:
        candidates = []
        for input in linker_inputs._cc_linker_inputs:
            for library in input.libraries:
                if not library.dynamic_library:
                    continue
                candidates.append(
                    library.resolved_symlink_dynamic_library or
                    library.dynamic_library,
                )

        # This is a fallback for dynamic frameworks propagated through
        # `AppleDynamicFrameworkInfo` without a corresponding `LibraryToLink`.
        fallback_candidates = compilation_providers.framework_files.to_list()

    seen_files = {}
    seen_names = {}
    dynamic_frameworks = []
    for file in candidates:
        framework_name = _dynamic_framework_name(file)
        if not framework_name or file in seen_files:
            continue

        # Diagnose basename collisions only when staging the selected Preview,
        # not while generating an opt-out project's otherwise valid targets.
        seen_files[file] = None
        seen_names[framework_name] = None
        dynamic_frameworks.append(file)

    # `framework_files` can contain every file in a bundle. Only the canonical
    # executable (`Name.framework/Name`) is a valid fallback; accepting a
    # plist, module map, or header could materialize a partial framework that
    # passes the directory check but fails at Preview launch.
    for file in fallback_candidates:
        framework_name = _dynamic_framework_name(file)
        if (not framework_name or
            file in seen_files or
            framework_name in seen_names):
            continue
        seen_files[file] = None
        seen_names[framework_name] = None
        dynamic_frameworks.append(file)

    return dynamic_frameworks

def _map_static_library_preview_dynamic_frameworks(
        *,
        dynamic_frameworks,
        framework_product_mappings):
    """Maps linker executables to complete framework products when possible."""
    framework_product_map = {
        linker_file: product_file
        for linker_file, product_file in framework_product_mappings
    }

    previews_dynamic_frameworks = []
    for linker_file in dynamic_frameworks:
        product_file = framework_product_map.get(linker_file)
        if product_file:
            previews_dynamic_frameworks.append((product_file, True))
        else:
            previews_dynamic_frameworks.append((linker_file, False))
    return previews_dynamic_frameworks

def _preview_execution_root_path(file):
    path = file.path
    if path.startswith("/"):
        return path
    return "$(PROJECT_DIR)/{}".format(path)

def _quote_preview_link_arg(arg):
    # Xcode's response parser accepts whole-argument quotes, not shell-style
    # concatenation. Build setting values can contain spaces after expansion.
    if not any([
        character in arg
        for character in [" ", "\t", "\n", "\r", "'", "\"", "\\", "$("]
    ]):
        return arg
    return "\"{}\"".format(arg.replace("\\", "\\\\").replace("\"", "\\\""))

def _get_static_library_preview_dynamic_libraries(linker_inputs):
    """Returns standalone CcInfo dylibs using their exact linker artifacts."""
    seen = {}
    libraries = []
    for input in linker_inputs._cc_linker_inputs:
        for library in input.libraries:
            # Keep the existing static/PIC preference when both variants exist.
            if library.static_library or library.pic_static_library:
                continue
            if not library.dynamic_library:
                continue
            file = (
                library.resolved_symlink_dynamic_library or
                library.dynamic_library
            )
            if (file.extension != "dylib" or
                ".framework/" in file.path or file in seen):
                continue
            seen[file] = None
            libraries.append(file)
    return libraries

def _create_static_library_preview_link_params(
        *,
        actions,
        name,
        linker_inputs):
    """Creates Libtool inputs for a static library's Xcode Preview closure.

    Xcode 26 derives Preview static library inputs from the target's Libtool
    task. Bazel static library actions only archive the target's own objects,
    so their transitive static libraries, standalone dylibs, and frameworks aren't
    otherwise visible to that Preview-info path. Xcode accepts canonical
    `-F`, `-framework`, `-rpath`, `-ObjC`, and `-force_load` arguments in the
    Libtool response. `-ObjC` is required for Objective-C categories whose
    selectors are reached dynamically at runtime and therefore don't create
    undefined symbols that would otherwise pull their archive members into
    XOJIT. Per-library `alwayslink` semantics still require `-force_load`,
    including for symbols outside Objective-C category metadata. The generated
    Libtool facade intentionally ignores these link-only arguments for the
    ordinary archive while Xcode records them for the synthetic XOJIT image.

    Args:
        actions: The `ctx.actions` object.
        linker_inputs: A value returned by `linker_input_files.collect`.
        name: The target name, used to name the generated params file.

    Returns:
        A `struct` with `dynamic_frameworks`, `file`, `libraries`, and
        `link_input_files` fields, or `None` if the target has no transitive
        link inputs besides its own product.
    """
    libraries = _get_static_library_preview_libraries(linker_inputs)
    force_load_libraries = _get_static_library_preview_force_load_libraries(
        libraries = libraries,
        linker_inputs = linker_inputs,
    )
    dynamic_frameworks = _get_static_library_preview_dynamic_frameworks(
        linker_inputs,
    )
    dynamic_libraries = _get_static_library_preview_dynamic_libraries(
        linker_inputs,
    )

    if not libraries and not dynamic_frameworks and not dynamic_libraries:
        return None

    args = []
    if dynamic_frameworks:
        args.append("-F$(TARGET_BUILD_DIR)")
        for dynamic_framework in dynamic_frameworks:
            args.extend([
                "-framework",
                _dynamic_framework_name(dynamic_framework),
            ])
        args.extend([
            "-rpath",
            "$(TARGET_BUILD_DIR)",
        ])
    if libraries:
        args.append("-ObjC")
    force_load_set = {file: None for file in force_load_libraries}
    for library in libraries:
        path = _preview_execution_root_path(library)
        if library in force_load_set:
            args.extend(["-force_load", path])
        else:
            args.append(path)
    args.extend([
        _preview_execution_root_path(library)
        for library in dynamic_libraries
    ])

    params = actions.declare_file(
        "{}.rules_xcodeproj.preview.link.params".format(name),
    )
    actions.write(
        output = params,
        content = "{}\n".format("\n".join([
            _quote_preview_link_arg(arg)
            for arg in args
        ])),
    )

    return struct(
        dynamic_frameworks = tuple(dynamic_frameworks),
        file = params,
        link_input_files = tuple(libraries + dynamic_libraries),
        libraries = tuple(libraries),
    )

def _get_library_static_libraries_for_bwx(
        linker_inputs,
        *,
        dep_compilation_providers):
    dep_objc_libraries, dep_cc_linker_inputs = _extract_libraries(
        compilation_providers = dep_compilation_providers,
    )

    transitive = _collect_libraries(
        objc_libraries = linker_inputs._objc_libraries,
        cc_linker_inputs = linker_inputs._cc_linker_inputs,
    )

    non_direct_libraries = {
        file: None
        for file in _collect_libraries(
            objc_libraries = dep_objc_libraries,
            cc_linker_inputs = dep_cc_linker_inputs,
        )
    }
    direct = [
        file
        for file in transitive
        if file not in non_direct_libraries
    ]

    return (direct, transitive)

def _to_input_files(linker_inputs):
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return []

    return list(
        top_level_values._additional_input_files +
        top_level_values.dynamic_frameworks +
        top_level_values._static_frameworks,
    ) + [
        file
        for file in top_level_values.static_libraries
        if file.is_source
    ]

def _get_primary_static_library(linker_inputs):
    """Returns the "primary" static library for this target.

    Args:
        linker_inputs: A value from `linker_input_files.collect`.

    Returns:
        The `File` of the primary static library, or `None`.
    """
    return linker_inputs._primary_static_library

linker_input_files = struct(
    collect = _collect_linker_inputs,
    create_static_library_preview_link_params = (
        _create_static_library_preview_link_params
    ),
    merge = _merge_linker_inputs,
    get_library_static_libraries_for_bwx = (
        _get_library_static_libraries_for_bwx
    ),
    get_primary_static_library = _get_primary_static_library,
    get_static_library_preview_dynamic_frameworks = (
        _get_static_library_preview_dynamic_frameworks
    ),
    get_static_library_preview_libraries = (
        _get_static_library_preview_libraries
    ),
    get_transitive_static_libraries_for_bwx = (
        _get_transitive_static_libraries_for_bwx
    ),
    map_static_library_preview_dynamic_frameworks = (
        _map_static_library_preview_dynamic_frameworks
    ),
    to_input_files = _to_input_files,
)

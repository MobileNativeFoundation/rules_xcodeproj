"""Module containing functions dealing with target linker input files."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":collections.bzl", "flatten", "uniq")

_SKIP_INPUT_EXTENSIONS = {
    "a": None,
    "app": None,
    "appex": None,
    "dylib": None,
    "bundle": None,
    "framework": None,
    "lo": None,
    "swiftmodule": None,
    "xctest": None,
}

def _collect_linker_inputs(
        *,
        target,
        compilation_providers,
        avoid_compilation_providers = None):
    """Collects linker input files for a target.

    Args:
        target: The `Target`.
        compilation_providers: A value returned by
            `compilation_providers.collect`.
        avoid_compilation_providers: A value returned from
            `compilation_providers.collect`. The linker inputs from these
            providers will be excluded from the return list.

    Returns:
        An opaque `struct` containing the linker input files for a target. The
        `struct` should be passed to functions on `linker_input_files` to
        retrieve its contents.
    """
    objc_libraries, cc_linker_inputs = _extract_libraries(
        compilation_providers = compilation_providers,
    )

    if compilation_providers._is_top_level:
        primary_static_library = None
        top_level_values = _extract_top_level_values(
            target = target,
            compilation_providers = compilation_providers,
            avoid_compilation_providers = avoid_compilation_providers,
            objc_libraries = objc_libraries,
            cc_linker_inputs = cc_linker_inputs,
        )
    elif compilation_providers._is_xcode_library_target:
        primary_static_library = _compute_primary_static_library(
            compilation_providers = compilation_providers,
            objc_libraries = objc_libraries,
            cc_linker_inputs = cc_linker_inputs,
        )
        top_level_values = None
    else:
        primary_static_library = None
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
        compilation_providers,
        objc_libraries,
        cc_linker_inputs):
    # Ideally we would only return the static library that is owned by this
    # target, but sometimes another rule creates the output and this rule
    # outputs it. So far the first library has always been the correct one.
    if compilation_providers._objc:
        for library in objc_libraries:
            if library.is_source:
                continue
            return library
    elif compilation_providers._cc_info:
        for input in cc_linker_inputs:
            for library in input.libraries:
                if library.static_library.is_source:
                    continue
                return library.static_library
    return None

def _extract_libraries(compilation_providers):
    if compilation_providers._objc:
        objc = compilation_providers._objc
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
    elif compilation_providers._cc_info:
        cc_info = compilation_providers._cc_info
        objc_libraries = []
        cc_linker_inputs = cc_info.linking_context.linker_inputs.to_list()
    else:
        objc_libraries = []
        cc_linker_inputs = []
    return (objc_libraries, cc_linker_inputs)

def _extract_top_level_values(
        *,
        target,
        compilation_providers,
        avoid_compilation_providers,
        objc_libraries,
        cc_linker_inputs):
    if compilation_providers._objc:
        objc = compilation_providers._objc
        if avoid_compilation_providers:
            avoid_objc = avoid_compilation_providers._objc
            if not avoid_objc:
                fail("""\
`avoid_compilation_providers` doesn't have `ObjcProvider`, but \
`compilation_providers` does
""")
            avoid_static_framework_files = sets.make(
                avoid_objc.static_framework_file.to_list(),
            )
            avoid_static_libraries = sets.make(
                depset(transitive = [
                    avoid_objc.library,
                    avoid_objc.imported_library,
                ]).to_list(),
            )
        else:
            avoid_static_framework_files = sets.make()
            avoid_static_libraries = sets.make()

        dynamic_frameworks = objc.dynamic_framework_file.to_list()
        static_frameworks = [
            file
            for file in objc.static_framework_file.to_list()
            if (file.is_source and
                not sets.contains(avoid_static_framework_files, file))
        ]
        static_libraries = [
            file
            for file in objc_libraries
            if not sets.contains(avoid_static_libraries, file)
        ]

        additional_input_files = _process_additional_inputs(
            objc.link_inputs.to_list(),
        )
    elif compilation_providers._cc_info:
        if avoid_compilation_providers:
            avoid_cc_info = avoid_compilation_providers._cc_info
            if not avoid_cc_info:
                fail("""\
`avoid_compilation_providers` doesn't have `CcInfo`, but \
`compilation_providers` does
""")
            avoid_linking_context = avoid_cc_info.linking_context
            avoid_libraries = sets.make(flatten([
                input.libraries
                for input in avoid_linking_context.linker_inputs.to_list()
            ]))
        else:
            avoid_libraries = sets.make()

        dynamic_frameworks = []
        static_frameworks = []

        static_libraries = []
        additional_input_files = []
        for input in cc_linker_inputs:
            additional_input_files.extend(_process_additional_inputs(
                input.additional_inputs,
            ))
            for library in input.libraries:
                if sets.contains(avoid_libraries, library):
                    continue
                static_libraries.append(library.static_library)

        # Dedup libraries
        static_libraries = uniq(static_libraries)
    else:
        return None

    link_args = None
    link_args_inputs = None
    if target:
        # TODO: Make this configurable with `XcodeProjAutomaticTargetProcessingInfo`
        for action in target.actions:
            if action.mnemonic in ("ObjcLink", "CppLink"):
                link_args = action.args
                link_args_inputs = tuple([
                    f
                    for f in action.inputs.to_list()
                    if f.path.endswith("-linker.objlist")
                ])
                break

    return struct(
        additional_input_files = tuple(additional_input_files),
        dynamic_frameworks = tuple(dynamic_frameworks),
        link_args = link_args,
        link_args_inputs = link_args_inputs,
        static_frameworks = tuple(static_frameworks),
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
        compilation_providers,
        objc_libraries,
        cc_linker_inputs):
    libraries = []
    if compilation_providers._objc:
        for library in objc_libraries:
            if library.is_source:
                continue
            libraries.append(library)
    elif compilation_providers._cc_info:
        for input in cc_linker_inputs:
            for library in input.libraries:
                if library.static_library.is_source:
                    continue
                libraries.append(library.static_library)
    return libraries

def _get_transitive_static_libraries(linker_inputs):
    return _collect_libraries(
        compilation_providers = linker_inputs._compilation_providers,
        objc_libraries = linker_inputs._objc_libraries,
        cc_linker_inputs = linker_inputs._cc_linker_inputs,
    )

def _get_library_static_libraries(linker_inputs, *, dep_compilation_providers):
    dep_objc_libraries, dep_cc_linker_inputs = _extract_libraries(
        compilation_providers = dep_compilation_providers,
    )
    non_direct_libraries = sets.make(_collect_libraries(
        compilation_providers = dep_compilation_providers,
        objc_libraries = dep_objc_libraries,
        cc_linker_inputs = dep_cc_linker_inputs,
    ))

    transitive = _collect_libraries(
        compilation_providers = linker_inputs._compilation_providers,
        objc_libraries = linker_inputs._objc_libraries,
        cc_linker_inputs = linker_inputs._cc_linker_inputs,
    )
    libraries = sets.make(transitive)

    direct = sets.to_list(
        sets.difference(libraries, non_direct_libraries),
    )

    return (direct, transitive)

def _to_input_files(linker_inputs):
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return []

    return list(
        top_level_values.additional_input_files +
        top_level_values.dynamic_frameworks +
        top_level_values.static_frameworks,
    ) + [
        file
        for file in top_level_values.static_libraries
        if file.is_source
    ]

def _get_primary_static_library(linker_inputs):
    """Returns the "primary" static library for this target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        The `File` of the primary static library, or `None`.
    """
    return linker_inputs._primary_static_library

linker_input_files = struct(
    collect = _collect_linker_inputs,
    merge = _merge_linker_inputs,
    get_library_static_libraries = _get_library_static_libraries,
    get_primary_static_library = _get_primary_static_library,
    get_transitive_static_libraries = _get_transitive_static_libraries,
    to_input_files = _to_input_files,
)

"""Module containing functions dealing with target linker input files."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":collections.bzl", "flatten", "set_if_true")
load(":files.bzl", "file_path", "file_path_to_dto")
load(":providers.bzl", "XcodeProjInfo")

def _collect_for_non_top_level(*, cc_info, objc, is_xcode_target):
    """Collects linker input files for a non top level target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.
        is_xcode_target: Whether the target is an Xcode target.

    Returns:
        An mostly-opaque `struct` containing the linker input files for a
        target. The `struct` should be passed to functions on
        `linker_input_files` to retrieve its contents. It also exposes the
        following public attributes:

        *   `xcode_library_targets`: A list of targets `structs` that are
            Xcode library targets.
    """
    if cc_info:
        cc_linker_inputs = cc_info.linking_context.linker_inputs
    else:
        cc_linker_inputs = depset()

    if objc:
        dynamic_framework_files = objc.dynamic_framework_file
        imported_libraries = objc.imported_library
        static_framework_files = objc.static_framework_file
    else:
        dynamic_framework_files = depset()
        imported_libraries = depset()
        static_framework_files = depset()

    return struct(
        _avoid_linker_inputs = None,
        _cc_linker_inputs = cc_linker_inputs,
        _dynamic_framework_files = dynamic_framework_files,
        _imported_libraries = imported_libraries,
        _static_framework_files = static_framework_files,
        _is_xcode_library_target = cc_info and is_xcode_target,
        xcode_library_targets = [],
    )

def _collect_for_top_level(*, deps, avoid_linker_inputs):
    """Collects linker input files for a top level library target.

    Args:
        deps: `ctx.attr.deps` of the target.
        avoid_linker_inputs: A value returned from
            `linker_input_files.collect_for_top_level`. These inputs will be
            excluded from the return list.

    Returns:
        A value similar to the one returned from
        `linker_input_files.collect_for_non_top_level`.
    """
    return _merge(deps = deps, avoid_linker_inputs = avoid_linker_inputs)

def _merge(*, deps, avoid_linker_inputs = None):
    """Merges linker input files from the deps of a target.

    This should only be used by targets that are being skipped.

    Args:
        deps: `ctx.attr.deps` of the target.
        avoid_linker_inputs: A value returned from
            `linker_input_files.collect_for_top_level`. These inputs will be
            excluded from the return list.

    Returns:
        A value similar to the one returned from
        `linker_input_files.collect_for_top_level`.
    """
    cc_linker_inputs = depset(
        order = "topological",
        transitive = [
            dep[XcodeProjInfo].linker_inputs._cc_linker_inputs
            for dep in deps
        ],
    )

    dynamic_framework_files = depset(
        order = "topological",
        transitive = [
            dep[XcodeProjInfo].linker_inputs._dynamic_framework_files
            for dep in deps
        ],
    )

    imported_libraries = depset(
        order = "topological",
        transitive = [
            dep[XcodeProjInfo].linker_inputs._imported_libraries
            for dep in deps
        ],
    )

    static_framework_files = depset(
        order = "topological",
        transitive = [
            dep[XcodeProjInfo].linker_inputs._static_framework_files
            for dep in deps
        ],
    )

    xcode_library_targets = [
        dep[XcodeProjInfo].target
        for dep in deps
        if dep[XcodeProjInfo].linker_inputs._is_xcode_library_target
    ]

    return struct(
        _avoid_linker_inputs = avoid_linker_inputs,
        _cc_linker_inputs = cc_linker_inputs,
        _dynamic_framework_files = dynamic_framework_files,
        _imported_libraries = imported_libraries,
        _static_framework_files = static_framework_files,
        _is_xcode_library_target = False,
        xcode_library_targets = xcode_library_targets,
    )

def _get_static_libraries(linker_inputs):
    """Returns the static libraries needed to link the target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        A `list` of `File`s that need to be linked for the target.
    """
    avoid_linker_inputs = linker_inputs._avoid_linker_inputs
    if avoid_linker_inputs:
        avoid_libraries = sets.make(flatten([
            input.libraries
            for input in avoid_linker_inputs._cc_linker_inputs.to_list()
        ]))
    else:
        avoid_libraries = sets.make()

    static_libraries = [
        library.static_library
        for library in flatten([
            input.libraries
            for input in linker_inputs._cc_linker_inputs.to_list()
        ])
        if not sets.contains(avoid_libraries, library)
    ]

    return static_libraries

def _to_dto(linker_inputs):
    """Generates a target DTO for linker inputs.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        A `dict` containing the following elements:

        *   `dynamic_frameworks`: A `list` of `FilePath`s for
            `dynamic_frameworks`.
        *   `static_frameworks`: A `list` of `FilePath`s for
            `static_frameworks`.
        *   `static_libraries`: A `list` of `FilePath`s for `static_libraries`.
    """
    if linker_inputs._is_xcode_library_target:
        # We only want to return linker inputs for top level targets
        return {}

    ret = {}

    avoid_linker_inputs = linker_inputs._avoid_linker_inputs
    if avoid_linker_inputs:
        avoid_dynamc_framework_files = sets.make(
            avoid_linker_inputs._dynamic_framework_files.to_list(),
        )
        avoid_imported_libraries = sets.make(
            avoid_linker_inputs._imported_libraries.to_list(),
        )
        avoid_static_framework_files = sets.make(
            avoid_linker_inputs._static_framework_files.to_list(),
        )
        avoid_libraries = sets.make(flatten([
            input.libraries
            for input in avoid_linker_inputs._cc_linker_inputs.to_list()
        ]))
    else:
        avoid_dynamc_framework_files = sets.make()
        avoid_imported_libraries = sets.make()
        avoid_static_framework_files = sets.make()
        avoid_libraries = sets.make()

    dynamic_frameworks = [
        file_path_to_dto(file_path(file, path = file.dirname))
        for file in linker_inputs._dynamic_framework_files.to_list()
        if not sets.contains(avoid_dynamc_framework_files, file)
    ]

    imported_libraries = [
        file_path_to_dto(file_path(file))
        for file in linker_inputs._imported_libraries.to_list()
        if not sets.contains(avoid_imported_libraries, file)
    ]

    static_frameworks = [
        file_path_to_dto(file_path(file, path = file.dirname))
        for file in linker_inputs._static_framework_files.to_list()
        if not sets.contains(avoid_static_framework_files, file)
    ]

    static_libraries = [
        file_path_to_dto(file_path(library.static_library))
        for library in flatten([
            input.libraries
            for input in linker_inputs._cc_linker_inputs.to_list()
        ])
        if not sets.contains(avoid_libraries, library)
    ]

    set_if_true(ret, "dynamic_frameworks", dynamic_frameworks)
    set_if_true(ret, "static_frameworks", static_frameworks)
    set_if_true(ret, "static_libraries", static_libraries + imported_libraries)

    return ret

def _get_primary_static_library(linker_inputs):
    """Returns the "primary" static library for this target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        The `file_path` of the primary static library, or `None`.
    """
    for input in linker_inputs._cc_linker_inputs.to_list():
        # Ideally we would only return the static library that is owned by this
        # target, but sometimes another rule creates the output and this rule
        # outputs it. So far the first library has always been the correct one.
        return file_path(input.libraries[0].static_library)
    return None

linker_input_files = struct(
    collect_for_non_top_level = _collect_for_non_top_level,
    collect_for_top_level = _collect_for_top_level,
    get_primary_static_library = _get_primary_static_library,
    get_static_libraries = _get_static_libraries,
    merge = _merge,
    to_dto = _to_dto,
)

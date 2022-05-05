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
    return struct(
        _avoid_linker_inputs = None,
        _cc_info = cc_info,
        _objc = objc,
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

    # Ideally we could use `merge_linking_contexts`, but it's private API
    cc_info = cc_common.merge_cc_infos(
        cc_infos = [
            dep[XcodeProjInfo].linker_inputs._cc_info
            for dep in deps
            if dep[XcodeProjInfo].linker_inputs._cc_info
        ],
    )

    objc_providers = [
        dep[XcodeProjInfo].linker_inputs._objc
        for dep in deps
        if dep[XcodeProjInfo].linker_inputs._objc
    ]
    if objc_providers:
        objc = apple_common.new_objc_provider(providers = objc_providers)
    else:
        objc = None

    xcode_library_targets = [
        dep[XcodeProjInfo].target
        for dep in deps
        if dep[XcodeProjInfo].linker_inputs._is_xcode_library_target
    ]

    return struct(
        _avoid_linker_inputs = avoid_linker_inputs,
        _cc_info = cc_info,
        _objc = objc,
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
    cc_info = linker_inputs._cc_info
    objc = linker_inputs._objc
    avoid_linker_inputs = linker_inputs._avoid_linker_inputs

    if objc:
        if avoid_linker_inputs:
            if not avoid_linker_inputs._objc:
                fail("""\
`avoid_linker_inputs` doesn't have `ObjcProvider`, but `linker_inputs` does
""")
            avoid_libraries = sets.make(
                avoid_linker_inputs._objc.library.to_list(),
            )
        else:
            avoid_libraries = sets.make()

        return [
            file
            for file in objc.library.to_list()
            if not sets.contains(avoid_libraries, file)
        ]
    elif cc_info:
        if avoid_linker_inputs:
            if not avoid_linker_inputs._cc_info:
                fail("""\
`avoid_linker_inputs` doesn't have `CcInfo`, but `linker_inputs` does
""")
            avoid_linking_context = avoid_linker_inputs._cc_info.linking_context
            avoid_libraries = sets.make(flatten([
                input.libraries
                for input in avoid_linking_context.linker_inputs.to_list()
            ]))
        else:
            avoid_libraries = sets.make()

        return [
            library.static_library
            for library in flatten([
                input.libraries
                for input in cc_info.linking_context.linker_inputs.to_list()
            ])
            if not sets.contains(avoid_libraries, library)
        ]
    else:
        fail("Xcode target requires `ObjcProvider` or `CcInfo`")

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

    cc_info = linker_inputs._cc_info
    objc = linker_inputs._objc
    avoid_linker_inputs = linker_inputs._avoid_linker_inputs

    if objc:
        if avoid_linker_inputs:
            if not avoid_linker_inputs._objc:
                fail("""\
`avoid_linker_inputs` doesn't have `ObjcProvider`, but `linker_inputs` does
""")
            avoid_dynamic_framework_files = sets.make(
                avoid_linker_inputs._objc.dynamic_framework_file.to_list(),
            )
            avoid_static_framework_files = sets.make(
                avoid_linker_inputs._objc.static_framework_file.to_list(),
            )
            avoid_libraries = sets.make(
                avoid_linker_inputs._objc.library.to_list(),
            )
            avoid_imported_libraries = sets.make(
                avoid_linker_inputs._objc.imported_library.to_list(),
            )
        else:
            avoid_dynamic_framework_files = sets.make()
            avoid_static_framework_files = sets.make()
            avoid_libraries = sets.make()
            avoid_imported_libraries = sets.make()

        dynamic_frameworks = [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in objc.dynamic_framework_file.to_list()
            if not sets.contains(avoid_dynamic_framework_files, file)
        ]
        static_frameworks = [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in objc.static_framework_file.to_list()
            if not sets.contains(avoid_static_framework_files, file)
        ]
        libraries = [
            file_path_to_dto(file_path(file))
            for file in objc.library.to_list()
            if not sets.contains(avoid_libraries, file)
        ]
        imported_libraries = [
            file_path_to_dto(file_path(file))
            for file in objc.imported_library.to_list()
            if not sets.contains(avoid_imported_libraries, file)
        ]
        static_libraries = libraries + imported_libraries
    elif cc_info:
        if avoid_linker_inputs:
            if not avoid_linker_inputs._cc_info:
                fail("""\
`avoid_linker_inputs` doesn't have `CcInfo`, but `linker_inputs` does
""")
            avoid_linking_context = avoid_linker_inputs._cc_info.linking_context
            avoid_libraries = sets.make(flatten([
                input.libraries
                for input in avoid_linking_context.linker_inputs.to_list()
            ]))
        else:
            avoid_libraries = sets.make()

        dynamic_frameworks = []
        static_frameworks = []
        static_libraries = [
            file_path_to_dto(file_path(library.static_library))
            for library in flatten([
                input.libraries
                for input in cc_info.linking_context.linker_inputs.to_list()
            ])
            if not sets.contains(avoid_libraries, library)
        ]
    else:
        return {}

    ret = {}
    set_if_true(ret, "dynamic_frameworks", dynamic_frameworks)
    set_if_true(ret, "static_frameworks", static_frameworks)
    set_if_true(ret, "static_libraries", static_libraries)

    return ret

def _get_primary_static_library(linker_inputs):
    """Returns the "primary" static library for this target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        The `file_path` of the primary static library, or `None`.
    """

    # Ideally we would only return the static library that is owned by this
    # target, but sometimes another rule creates the output and this rule
    # outputs it. So far the first library has always been the correct one.
    if linker_inputs._objc:
        for library in linker_inputs._objc.library.to_list():
            return file_path(library)
    elif linker_inputs._cc_info:
        linker_inputs = linker_inputs._cc_info.linking_context.linker_inputs
        for input in linker_inputs.to_list():
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

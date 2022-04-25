"""Module containing functions dealing with target linker input files."""

load(":collections.bzl", "flatten")
load(":files.bzl", "file_path")
load(":providers.bzl", "XcodeProjInfo")

def _collect(*, cc_info, objc, is_xcode_target):
    """Collects linker input files for a library target.

    Args:
        cc_info: The `CcInfo` of the target.
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
    cc_linker_inputs = cc_info.linking_context.linker_inputs

    if objc:
        static_framework_files = objc.static_framework_file
    else:
        static_framework_files = depset()

    return struct(
        _cc_linker_inputs = cc_linker_inputs,
        _static_framework_files = static_framework_files,
        _is_xcode_library_target = is_xcode_target,
        xcode_library_targets = [],
    )

def _merge(*, deps):
    """Merges linker input files from the deps of a target.

    This should only be used by top level targets (which don't have access to
    their own linker input files), or targets that are being skipped.

    Args:
        deps: `ctx.attr.deps` of the target.

    Returns:
        A value similar to the one returned from `linker_input_files.collect`.
    """
    transitive_linker_inputs = [
        (dep[XcodeProjInfo].target, dep[XcodeProjInfo].linker_inputs)
        for dep in deps
        if dep[XcodeProjInfo].linker_inputs
    ]

    cc_linker_inputs = depset(
        transitive = [
            linker_inputs._cc_linker_inputs
            for _, linker_inputs in transitive_linker_inputs
        ],
    )

    static_framework_files = depset(
        transitive = [
            linker_inputs._static_framework_files
            for _, linker_inputs in transitive_linker_inputs
        ],
    )

    xcode_library_targets = [
        target
        for target, linker_inputs in transitive_linker_inputs
        if linker_inputs._is_xcode_library_target
    ]

    return struct(
        _cc_linker_inputs = cc_linker_inputs,
        _static_framework_files = static_framework_files,
        _is_xcode_library_target = False,
        xcode_library_targets = xcode_library_targets,
    )

def _get_files_to_link(linker_inputs):
    """Returns the files to link for a target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        A list of `File`s that need to be linked for this target.
    """
    static_libraries = [
        library.static_library
        for library in flatten([
            input.libraries
            for input in linker_inputs._cc_linker_inputs.to_list()
        ])
    ]
    return static_libraries + linker_inputs._static_framework_files.to_list()

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
    collect = _collect,
    get_files_to_link = _get_files_to_link,
    get_primary_static_library = _get_primary_static_library,
    merge = _merge,
)

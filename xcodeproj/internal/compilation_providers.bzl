"""Module for propagating compilation providers."""

def _collect(*, cc_info, objc, swift_info, is_xcode_target):
    """Collects compilation providers for a non top-level target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.
        swift_info: The `SwiftInfo` of the target, or `None`.
        is_xcode_target: Whether the target is an Xcode target.

    Returns:
        An opaque `struct` containing the linker input files for a target. The
        `struct` should be passed to functions in the `collect_providers` module
        to retrieve its contents.
    """
    is_xcode_library_target = cc_info and is_xcode_target

    return struct(
        _cc_info = cc_info,
        _is_swift = swift_info != None,
        _is_top_level = False,
        _is_xcode_library_target = is_xcode_library_target,
        _objc = objc,
        _transitive_compilation_providers = (),
    )

def _merge(
        *,
        cc_info = None,
        objc = None,
        swift_info = None,
        transitive_compilation_providers):
    """Merges compilation providers from the deps of a target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.
        swift_info: The `SwiftInfo` of the target, or `None`.
        transitive_compilation_providers: A `list` of
            `(xcode_target, XcodeProjInfo)` tuples of transitive dependencies that
            should have compilation providers merged.

    Returns:
        A value similar to the one returned from
        `compilation_providers.collect`.
    """
    cc_info = cc_common.merge_cc_infos(
        direct_cc_infos = [cc_info] if cc_info else [],
        cc_infos = [
            providers._cc_info
            for _, providers in transitive_compilation_providers
            if providers._cc_info
        ],
    )

    if not objc:
        maybe_objc_providers = [
            providers._objc if providers._objc else _to_objc(providers._cc_info)
            for _, providers in transitive_compilation_providers
        ]
        objc_providers = [objc for objc in maybe_objc_providers if objc]
        if objc_providers:
            objc = apple_common.new_objc_provider(providers = objc_providers)

    return struct(
        _cc_info = cc_info,
        _is_swift = swift_info != None,
        _is_top_level = True,
        _is_xcode_library_target = False,
        _objc = objc,
        _transitive_compilation_providers = tuple(
            transitive_compilation_providers,
        ),
    )

def _to_objc(cc_info):
    if not cc_info:
        return None

    libraries = []
    force_load_libraries = []
    link_inputs = []
    linkopts = []
    for input in cc_info.linking_context.linker_inputs.to_list():
        for library in input.libraries:
            libraries.append(library.static_library)
            link_inputs.extend(input.additional_inputs)
            linkopts.extend(input.user_link_flags)
            if library.alwayslink:
                force_load_libraries.append(library.static_library)

    return apple_common.new_objc_provider(
        force_load_library = depset(
            force_load_libraries,
            order = "topological",
        ),
        library = depset(
            libraries,
            order = "topological",
        ),
        link_inputs = depset(link_inputs),
        linkopt = depset(linkopts),
    )

def _get_xcode_library_targets(*, compilation_providers):
    """Returns the Xcode library target dependencies for this target.

    Args:
        compilation_providers: A value returned from
            `compilation_providers.merge`.

    Returns:
        A list of targets `struct`s that are Xcode library targets.
    """
    return [
        target
        for target, providers in (
            compilation_providers._transitive_compilation_providers
        )
        if providers._is_xcode_library_target
    ]

compilation_providers = struct(
    collect = _collect,
    get_xcode_library_targets = _get_xcode_library_targets,
    merge = _merge,
)

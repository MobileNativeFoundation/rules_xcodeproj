"""Module for propagating compilation providers."""

load("@bazel_features//:features.bzl", "bazel_features")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "memory_efficient_depset",
)

_objc_has_linking_info = not bazel_features.cc.objc_linking_info_migrated

def _collect_compilation_providers(*, cc_info, objc):
    """Collects compilation providers for a non top-level target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.

    Returns:
        An opaque `struct` containing the linker input files for a target. The
        `struct` should be passed to functions in the `collect_providers` module
        to retrieve its contents.
    """
    if not _objc_has_linking_info:
        objc = None

    return struct(
        _framework_files = EMPTY_DEPSET,
        _propagated_framework_files = EMPTY_DEPSET,
        _propagated_objc = objc,
        cc_info = cc_info,
        objc = objc,
    )

def _merge_compilation_providers(
        *,
        apple_dynamic_framework_info = None,
        cc_info = None,
        transitive_compilation_providers):
    """Merges compilation providers from the deps of a target.

    Args:
        apple_dynamic_framework_info: The
            `apple_common.AppleDynamicFrameworkInfo` of the target, or `None`.
        cc_info: The `CcInfo` of the target, or `None`.
        transitive_compilation_providers: A `list` of
            `(xcode_target, XcodeProjInfo)` tuples of transitive dependencies
            that should have compilation providers merged.

    Returns:
        A value similar to the one returned from
        `compilation_providers.collect`.
    """
    framework_files = memory_efficient_depset(
        transitive = [
            providers._propagated_framework_files
            for _, providers in transitive_compilation_providers
        ],
        order = "topological",
    )

    if apple_dynamic_framework_info:
        propagated_framework_files = memory_efficient_depset(
            transitive = [
                apple_dynamic_framework_info.framework_files,
                framework_files,
            ],
            order = "topological",
        )

        # Works around an issue with `*_dynamic_framework`
        cc_info = None
    else:
        propagated_framework_files = framework_files

    merged_cc_info = cc_common.merge_cc_infos(
        direct_cc_infos = [cc_info] if cc_info else [],
        cc_infos = [
            providers.cc_info
            for _, providers in transitive_compilation_providers
            if providers.cc_info
        ],
    )

    objc = None
    if _objc_has_linking_info:
        maybe_objc_providers = [
            _to_objc(providers._propagated_objc, providers.cc_info)
            for _, providers in transitive_compilation_providers
        ]
        objc_providers = [objc for objc in maybe_objc_providers if objc]
        if objc_providers:
            objc = apple_common.new_objc_provider(providers = objc_providers)
        if apple_dynamic_framework_info:
            propagated_objc = apple_dynamic_framework_info.objc
        else:
            propagated_objc = objc
    else:
        propagated_objc = None

    return struct(
        _framework_files = framework_files,
        _propagated_framework_files = propagated_framework_files,
        _propagated_objc = propagated_objc,
        cc_info = merged_cc_info,
        objc = objc,
    )

def _to_objc(objc, cc_info):
    if objc:
        return objc
    if not cc_info:
        return None

    libraries = []
    force_load_libraries = []
    link_inputs = []
    linkopts = []
    for input in cc_info.linking_context.linker_inputs.to_list():
        for library in input.libraries:
            link_inputs.extend(input.additional_inputs)
            linkopts.extend(input.user_link_flags)

            # TODO: Account for all of the different linking strategies
            # here: https://github.com/bazelbuild/bazel/blob/986ef7b68d61b1573d9c2bb1200585d07ad24691/src/main/java/com/google/devtools/build/lib/rules/cpp/CcLinkingHelper.java#L951-L1009
            static_library = (library.static_library or
                              library.pic_static_library)
            if static_library:
                libraries.append(static_library)
                if library.alwayslink:
                    force_load_libraries.append(static_library)

    return apple_common.new_objc_provider(
        force_load_library = depset(
            force_load_libraries,
            order = "topological",
        ),
        library = depset(
            libraries,
            order = "topological",
        ),
        link_inputs = depset(
            link_inputs,
            order = "topological",
        ),
        linkopt = depset(
            linkopts,
            order = "topological",
        ),
    )

compilation_providers = struct(
    collect = _collect_compilation_providers,
    merge = _merge_compilation_providers,
)

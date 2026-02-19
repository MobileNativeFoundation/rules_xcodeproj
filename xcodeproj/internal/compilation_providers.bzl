"""Module for propagating compilation providers."""

load("@bazel_features//:features.bzl", "bazel_features")
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "memory_efficient_depset",
)

_PROPAGATE_PROVIDERS_PRODUCT_TYPES = {
    "F": None,  # com.apple.product-type.framework.static
    "f": None,  # com.apple.product-type.framework
}

_objc_has_linking_info = not bazel_features.cc.objc_linking_info_migrated

def _legacy_merge_cc_compilation_context(
        *,
        direct_compilation_context,
        compilation_contexts):
    if not direct_compilation_context:
        return None

    if not compilation_contexts:
        return direct_compilation_context

    compilation_context = cc_common.create_compilation_context(
        # TODO: This comment should be updated to not reference opts.bzl
        # Maybe not correct, but we don't use this value in `opts.bzl`, so not
        # worth the computation to merge it
        headers = direct_compilation_context.headers,
        system_includes = depset(
            transitive = [direct_compilation_context.system_includes] + [
                compilation_context.system_includes
                for compilation_context in compilation_contexts
            ],
        ),
        includes = depset(
            transitive = [direct_compilation_context.includes] + [
                compilation_context.includes
                for compilation_context in compilation_contexts
            ],
        ),
        quote_includes = depset(
            transitive = [direct_compilation_context.quote_includes] + [
                compilation_context.quote_includes
                for compilation_context in compilation_contexts
            ],
        ),
        framework_includes = depset(
            transitive = [direct_compilation_context.framework_includes] + [
                compilation_context.framework_includes
                for compilation_context in compilation_contexts
            ],
        ),
        defines = depset(
            transitive = [direct_compilation_context.defines] + [
                compilation_context.defines
                for compilation_context in compilation_contexts
            ],
        ),
        local_defines = direct_compilation_context.local_defines,
    )

    return compilation_context

def _modern_merge_cc_compilation_context(
        *,
        direct_compilation_context,
        # buildifier: disable=unused-variable
        compilation_contexts):
    if not direct_compilation_context:
        return None

    return direct_compilation_context

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

_merge_cc_compilation_context = (
    # Bazel 6 check
    _modern_merge_cc_compilation_context if hasattr(apple_common, "link_multi_arch_static_library") else _legacy_merge_cc_compilation_context
)

# API

def _collect_compilation_providers(*, cc_info, objc):
    """Collects compilation providers for a non top-level target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.

    Returns:
        A `tuple` containing two values:

        *   A `struct` containing information to be consumed by the
            `linker_input_files` module.
        *   An opaque `struct` to be set in
            `XcodeProjInfo.compilation_providers`.
    """
    if not _objc_has_linking_info:
        objc = None

    return (
        struct(
            cc_info = cc_info,
            framework_files = EMPTY_DEPSET,
            objc = objc,
        ),
        struct(
            _cc_info = cc_info,
            _propagated_framework_files = EMPTY_DEPSET,
            _propagated_objc = objc,
        ),
    )

def _collect_implementation_compilation_context(
        *,
        cc_info,
        transitive_implementation_providers):
    """Collects the implementation deps aware `CcCompilationContext`.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        transitive_implementation_providers: A `list` of
            `XcodeProjInfo`s of transitive implementation deps that should have
            compilation providers merged.
    """
    return _merge_cc_compilation_context(
        direct_compilation_context = (
            cc_info.compilation_context if cc_info else None
        ),
        compilation_contexts = [
            providers._cc_info.compilation_context
            for providers in transitive_implementation_providers
            if providers._cc_info
        ],
    )

def _merge_compilation_providers(
        *,
        apple_dynamic_framework_info = None,
        cc_info = None,
        propagate_providers,
        transitive_compilation_providers):
    """Merges compilation providers from the deps of a target.

    Args:
        apple_dynamic_framework_info: The `AppleDynamicFrameworkInfo` of the
            target, or `None`.
        cc_info: The `CcInfo` of the target, or `None`.
        propagate_providers: A `bool` indicating whether providers should be
            propagated to downstream targets.
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

    transitive_cc_infos = [
        providers._cc_info
        for _, providers in transitive_compilation_providers
        if providers._cc_info
    ]

    if len(transitive_cc_infos) > 1 or (cc_info and transitive_cc_infos):
        merged_cc_info = cc_common.merge_cc_infos(
            direct_cc_infos = [cc_info] if cc_info else [],
            cc_infos = transitive_cc_infos,
        )
    elif transitive_cc_infos:
        merged_cc_info = transitive_cc_infos[0]
    else:
        merged_cc_info = cc_info

    objc = None
    if _objc_has_linking_info:
        maybe_objc_providers = [
            _to_objc(providers._propagated_objc, providers._cc_info)
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

    return (
        struct(
            cc_info = merged_cc_info,
            framework_files = framework_files,
            objc = objc,
        ),
        struct(
            _cc_info = merged_cc_info if propagate_providers else None,
            _propagated_framework_files = propagated_framework_files,
            _propagated_objc = propagated_objc if propagate_providers else None,
        ),
    )

def _should_propagate_providers(*, product_type):
    return product_type in _PROPAGATE_PROVIDERS_PRODUCT_TYPES

compilation_providers = struct(
    collect = _collect_compilation_providers,
    collect_implementation_compilation_context = (
        _collect_implementation_compilation_context
    ),
    merge = _merge_compilation_providers,
    should_propagate_providers = _should_propagate_providers,
)

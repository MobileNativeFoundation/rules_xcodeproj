"""Module containing functions dealing with target linker input files."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":collections.bzl", "flatten", "set_if_true")
load(":files.bzl", "file_path", "file_path_to_dto")

# linker flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_LD_SKIP_OPTS = {
    "-isysroot": 2,
    "-fobjc-link-runtime": 1,
    "-target": 2,
}

_TARGET_TRIPLE_OS = {
    apple_common.platform.ios_device: "ios",
    apple_common.platform.ios_simulator: "ios-simulator",
    apple_common.platform.macos: "macos",
    apple_common.platform.tvos_device: "tvos",
    apple_common.platform.tvos_simulator: "tvos-simulator",
    apple_common.platform.watchos_device: "watchos",
    apple_common.platform.watchos_simulator: "watchos-simulator",
}

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
    is_xcode_library_target = cc_info and is_xcode_target
    if is_xcode_library_target:
        primary_static_library = _compute_primary_static_library(
            cc_info = cc_info,
            objc = objc,
        )
    else:
        primary_static_library = None

    return struct(
        _cc_info = cc_info,
        _objc = objc,
        _primary_static_library = primary_static_library,
        _top_level_values = None,
        _is_xcode_library_target = is_xcode_library_target,
        xcode_library_targets = [],
    )

def _compute_primary_static_library(cc_info, objc):
    # Ideally we would only return the static library that is owned by this
    # target, but sometimes another rule creates the output and this rule
    # outputs it. So far the first library has always been the correct one.
    if objc:
        for library in objc.library.to_list():
            return library
    elif cc_info:
        linker_inputs = cc_info.linking_context.linker_inputs
        for input in linker_inputs.to_list():
            return input.libraries[0].static_library
    return None

def _collect_for_top_level(
        *,
        ctx,
        transitive_linker_inputs,
        avoid_linker_inputs):
    """Collects linker input files for a top level library target.

    Args:
        ctx: The aspect context.
        transitive_linker_inputs: A `list` of `(target(), XcodeProjInfo)` tuples
            of transitive dependencies that should have their linker inputs
            merged.
        avoid_linker_inputs: A value returned from
            `linker_input_files.collect_for_top_level`. These inputs will be
            excluded from the return list.

    Returns:
        A value similar to the one returned from
        `linker_input_files.collect_for_non_top_level`.
    """
    return _merge(
        ctx = ctx,
        transitive_linker_inputs = transitive_linker_inputs,
        avoid_linker_inputs = avoid_linker_inputs,
    )

def _merge(*, ctx = None, transitive_linker_inputs, avoid_linker_inputs = None):
    """Merges linker input files from the deps of a target.

    This should only be used by targets that are being skipped.

    Args:
        ctx: The aspect context.
        transitive_linker_inputs: A `list` of `(target(), XcodeProjInfo)` tuples
            of transitive dependencies that should have their linker inputs
            merged.
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
            linker_inputs._cc_info
            for _, linker_inputs in transitive_linker_inputs
            if linker_inputs._cc_info
        ],
    )

    objc_providers = [
        linker_inputs._objc
        for _, linker_inputs in transitive_linker_inputs
        if linker_inputs._objc
    ]
    if objc_providers:
        objc = apple_common.new_objc_provider(providers = objc_providers)
    else:
        objc = None

    xcode_library_targets = [
        target
        for target, linker_inputs in transitive_linker_inputs
        if linker_inputs._is_xcode_library_target
    ]

    if cc_info or objc:
        top_level_values = _extract_top_level_values(
            ctx = ctx,
            cc_info = cc_info,
            objc = objc,
            avoid_linker_inputs = avoid_linker_inputs,
        )
    else:
        top_level_values = None

    return struct(
        _cc_info = cc_info,
        _objc = objc,
        _primary_static_library = None,
        _top_level_values = top_level_values,
        _is_xcode_library_target = False,
        xcode_library_targets = xcode_library_targets,
    )

def _extract_top_level_values(*, ctx, cc_info, objc, avoid_linker_inputs):
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
            avoid_force_load_libraries = sets.make(
                avoid_linker_inputs._objc.force_load_library.to_list(),
            )
        else:
            avoid_dynamic_framework_files = sets.make()
            avoid_static_framework_files = sets.make()
            avoid_libraries = sets.make()
            avoid_imported_libraries = sets.make()
            avoid_force_load_libraries = sets.make()

        dynamic_frameworks = [
            file
            for file in objc.dynamic_framework_file.to_list()
            if not sets.contains(avoid_dynamic_framework_files, file)
        ]
        static_frameworks = [
            file
            for file in objc.static_framework_file.to_list()
            if not sets.contains(avoid_static_framework_files, file)
        ]
        libraries = [
            file
            for file in objc.library.to_list()
            if not sets.contains(avoid_libraries, file)
        ]
        imported_libraries = [
            file
            for file in objc.imported_library.to_list()
            if not sets.contains(avoid_imported_libraries, file)
        ]
        force_load_libraries = [
            file
            for file in objc.force_load_library.to_list()
            if not sets.contains(avoid_force_load_libraries, file)
        ]

        user_linkopts = []
        raw_linkopts = objc.linkopt.to_list()
        raw_linkopts.extend(collections.before_each(
            "-framework",
            objc.sdk_framework.to_list(),
        ))
        raw_linkopts.extend(collections.before_each(
            "-weak_framework",
            objc.weak_sdk_framework.to_list(),
        ))
        raw_linkopts.extend([
            "-l" + dylib
            for dylib in objc.sdk_dylib.to_list()
        ])
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
        imported_libraries = []
        static_frameworks = []

        force_load_libraries = []
        libraries = []
        raw_linkopts = []
        user_linkopts = []
        for input in cc_info.linking_context.linker_inputs.to_list():
            user_linkopts.extend(input.user_link_flags)
            for library in input.libraries:
                if sets.contains(avoid_libraries, library):
                    continue
                if library.alwayslink:
                    force_load_libraries.append(library.static_library)
                else:
                    libraries.append(library.static_library)
    else:
        fail("cc_info or objc must be non-`None`")

    if ctx:
        cc_toolchain = find_cpp_toolchain(ctx)

        feature_configuration = cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            requested_features = ctx.features,
            unsupported_features = ctx.disabled_features,
        )
        variables = cc_common.create_link_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            user_link_flags = user_linkopts,
        )

        is_objc = objc != None
        cc_linkopts = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = (
                "objc-executable" if is_objc else "c++-link-executable"
            ),
            variables = variables,
        )
        raw_linkopts.extend(cc_linkopts)

        apple_fragment = ctx.fragments.apple
        triple = "{}-apple-{}".format(
            apple_fragment.single_arch_cpu,
            _TARGET_TRIPLE_OS[apple_fragment.single_arch_platform],
        )
        linkopts = _process_linkopts(raw_linkopts, triple = triple)
    else:
        linkopts = None

    return struct(
        dynamic_frameworks = dynamic_frameworks,
        force_load_libraries = force_load_libraries,
        imported_libraries = imported_libraries,
        libraries = libraries,
        linkopts = linkopts,
        static_frameworks = static_frameworks,
    )

def _get_static_libraries(linker_inputs):
    """Returns the static libraries needed to link the target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        A `list` of `File`s that need to be linked for the target.
    """
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        fail("Xcode target requires `ObjcProvider` or `CcInfo`")
    return top_level_values.libraries

def _process_linkopts(linkopts, *, triple):
    ret = []
    skip_next = 0
    for linkopt in linkopts:
        if skip_next:
            skip_next -= 1
            continue
        skip_next = _LD_SKIP_OPTS.get(linkopt, 0)
        if skip_next:
            skip_next -= 1
            continue

        linkopt = _process_linkopt(linkopt, triple = triple)
        if linkopt:
            ret.append(linkopt)

    return ret

def _process_linkopt(linkopt, *, triple):
    if linkopt == "OSO_PREFIX_MAP_PWD":
        return None
    if linkopt == "-Wl,-objc_abi_version,2":
        return None
    if linkopt.startswith("-F__BAZEL_"):
        return None
    if linkopt.startswith("-Wl,-sectcreate,__TEXT,__info_plist,"):
        return None

    opts = []
    for opt in linkopt.split(","):
        # Process paths in the --flag=value format, if any.
        flag, sep, value = opt.partition("=")
        if opt.startswith("bazel-out/"):
            opt = "$(BUILD_DIR)/" + opt
        elif value and value.startswith("bazel-out/"):
            opt = flag + sep + "$(BUILD_DIR)/" + value
        elif opt.startswith("external/"):
            opt = "$(LINKS_DIR)/" + opt
        elif value and value.startswith("external/"):
            opt = flag + sep + "$(LINKS_DIR)/" + value
        else:
            # Use Xcode set `DEVELOPER_DIR`
            opt = opt.replace(
                "__BAZEL_XCODE_DEVELOPER_DIR__",
                "$(DEVELOPER_DIR)",
            )

        if opt.endswith(".swiftmodule"):
            opt = opt + "/{}.swiftmodule".format(triple)

        opts.append(opt)

    return ",".join(opts)

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
        *   `linkopts`: A `list` of `string`s for linkopts.
    """
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return {}

    ret = {}
    set_if_true(
        ret,
        "dynamic_frameworks",
        [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in top_level_values.dynamic_frameworks
        ],
    )
    set_if_true(
        ret,
        "force_load",
        [
            file_path_to_dto(file_path(file))
            for file in top_level_values.force_load_libraries
        ],
    )
    set_if_true(
        ret,
        "linkopts",
        top_level_values.linkopts,
    )
    set_if_true(
        ret,
        "static_libraries",
        [
            file_path_to_dto(file_path(file))
            for file in (
                top_level_values.libraries + top_level_values.imported_libraries
            )
        ],
    )
    set_if_true(
        ret,
        "static_frameworks",
        [
            file_path_to_dto(file_path(file, path = file.dirname))
            for file in top_level_values.static_frameworks
        ],
    )

    return ret

def _to_framework_files(linker_inputs):
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return []

    return (
        top_level_values.dynamic_frameworks +
        top_level_values.static_frameworks
    )

def _get_primary_static_library(linker_inputs):
    """Returns the "primary" static library for this target.

    Args:
        linker_inputs: A value returned from `linker_input_files.collect`.

    Returns:
        The `File` of the primary static library, or `None`.
    """
    return linker_inputs._primary_static_library

linker_input_files = struct(
    collect_for_non_top_level = _collect_for_non_top_level,
    collect_for_top_level = _collect_for_top_level,
    get_primary_static_library = _get_primary_static_library,
    get_static_libraries = _get_static_libraries,
    merge = _merge,
    to_dto = _to_dto,
    to_framework_files = _to_framework_files,
)

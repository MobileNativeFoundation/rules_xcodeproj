"""Module containing functions dealing with target linker input files."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":collections.bzl", "flatten", "set_if_true", "uniq")
load(":files.bzl", "file_path", "file_path_to_dto")

# linker flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_LD_SKIP_OPTS = {
    "-isysroot": 2,
    "-fobjc-link-runtime": 1,
    "-target": 2,
}

_CC_LD_SKIP_OPTS = {
    "-framework": 2,
}

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

def _collect(*, ctx, compilation_providers, avoid_compilation_providers = None):
    """Collects linker input files for a target.

    Args:
        ctx: The aspect context.
        compilation_providers: A value returned by
            `compilation_providers.collect`.
        avoid_compilation_providers: A value returned from
            `compilation_providers.collect`. The linker inputs from these
            providers will be excluded from the return list.

    Returns:
        A mostly-opaque `struct` containing the linker input files for a target.
        The `struct` should be passed to functions on `linker_input_files` to
        retrieve its contents.
    """
    if compilation_providers._is_top_level:
        primary_static_library = None
        top_level_values = _extract_top_level_values(
            ctx = ctx,
            compilation_providers = compilation_providers,
            avoid_compilation_providers = avoid_compilation_providers,
        )
    elif compilation_providers._is_xcode_library_target:
        primary_static_library = _compute_primary_static_library(
            compilation_providers = compilation_providers,
        )
        top_level_values = None
    else:
        primary_static_library = None
        top_level_values = None

    return struct(
        _compilation_providers = compilation_providers,
        _primary_static_library = primary_static_library,
        _top_level_values = top_level_values,
    )

def _merge(*, compilation_providers):
    return _collect(ctx = None, compilation_providers = compilation_providers)

def _compute_primary_static_library(*, compilation_providers):
    # Ideally we would only return the static library that is owned by this
    # target, but sometimes another rule creates the output and this rule
    # outputs it. So far the first library has always been the correct one.
    if compilation_providers._objc:
        for library in compilation_providers._objc.library.to_list():
            return library
    elif compilation_providers._cc_info:
        linker_inputs = (
            compilation_providers._cc_info.linking_context.linker_inputs
        )
        for input in linker_inputs.to_list():
            return input.libraries[0].static_library
    return None

def _extract_top_level_values(
        *,
        ctx,
        compilation_providers,
        avoid_compilation_providers):
    if compilation_providers._objc:
        objc = compilation_providers._objc
        if avoid_compilation_providers:
            avoid_objc = avoid_compilation_providers._objc
            if not avoid_objc:
                fail("""\
`avoid_compilation_providers` doesn't have `ObjcProvider`, but \
`compilation_providers` does
""")
            avoid_dynamic_framework_files = sets.make(
                avoid_objc.dynamic_framework_file.to_list(),
            )
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
            avoid_dynamic_framework_files = sets.make()
            avoid_static_framework_files = sets.make()
            avoid_static_libraries = sets.make()

        force_load_libraries = [
            file
            for file in objc.force_load_library.to_list()
            if not sets.contains(avoid_static_libraries, file)
        ]

        # We don't want to include force loaded libraries in `static_libraries`
        avoid_static_libraries = sets.union(
            avoid_static_libraries,
            sets.make(force_load_libraries),
        )

        dynamic_frameworks = [
            file
            for file in objc.dynamic_framework_file.to_list()
            if (file.is_source and
                not sets.contains(avoid_dynamic_framework_files, file))
        ]
        static_frameworks = [
            file
            for file in objc.static_framework_file.to_list()
            if (file.is_source and
                not sets.contains(avoid_static_framework_files, file))
        ]
        static_libraries = [
            file
            for file in depset(
                transitive = [
                    objc.library,
                    objc.imported_library,
                ],
                order = "topological",
            ).to_list()
            if not sets.contains(avoid_static_libraries, file)
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

        additional_input_files = _process_additional_inputs(
            objc.link_inputs.to_list(),
        )
    elif compilation_providers._cc_info:
        cc_info = compilation_providers._cc_info
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

        force_load_libraries = []
        static_libraries = []
        raw_linkopts = []
        user_linkopts = []
        additional_input_files = []
        for input in cc_info.linking_context.linker_inputs.to_list():
            additional_input_files.extend(_process_additional_inputs(
                input.additional_inputs,
            ))
            user_linkopts.extend(input.user_link_flags)
            for library in input.libraries:
                if sets.contains(avoid_libraries, library):
                    continue
                if library.alwayslink:
                    force_load_libraries.append(library.static_library)
                else:
                    static_libraries.append(library.static_library)

        # Dedup libraries
        force_load_libraries = uniq(force_load_libraries)
        static_libraries = uniq(static_libraries)
    else:
        return None

    if ctx:
        cc_toolchain = find_cpp_toolchain(ctx)

        feature_configuration = cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            requested_features = ctx.features,
            unsupported_features = ctx.disabled_features + ["link_libc++"],
        )
        variables = cc_common.create_link_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            user_link_flags = user_linkopts,
        )

        cc_linkopts = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            # TODO: Use "objc++-executable".
            # We currently can't because it breaks when `--apple_generate_dsym`
            # is used. This results in slightly different flags.
            action_name = "c++-link-executable",
            variables = variables,
        )
        raw_linkopts.extend(_process_cc_linkopts(cc_linkopts))

        linkopts = _process_linkopts(raw_linkopts)
    else:
        linkopts = None

    return struct(
        additional_input_files = additional_input_files,
        dynamic_frameworks = dynamic_frameworks,
        force_load_libraries = force_load_libraries,
        linkopts = linkopts,
        static_frameworks = static_frameworks,
        static_libraries = static_libraries,
    )

def _process_additional_inputs(files):
    return [
        file
        for file in files
        if not file.is_source and file.extension not in _SKIP_INPUT_EXTENSIONS
    ]

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
    return (top_level_values.static_libraries +
            top_level_values.force_load_libraries)

def _process_cc_linkopts(linkopts):
    ret = []
    skip_next = 0
    for linkopt in linkopts:
        if skip_next:
            skip_next -= 1
            continue
        skip_next = _CC_LD_SKIP_OPTS.get(linkopt, 0)
        if skip_next:
            skip_next -= 1
            continue

        ret.append(linkopt)

    return ret

def _process_linkopts(linkopts):
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

        linkopt = _process_linkopt(linkopt)
        if linkopt:
            ret.append(linkopt)

    return ret

def _process_linkopt(linkopt):
    if linkopt == "OSO_PREFIX_MAP_PWD":
        return None
    if linkopt == "-Wl,-objc_abi_version,2":
        return None
    if linkopt.startswith("-F__BAZEL_"):
        return None
    if linkopt.startswith("-Wl,-sectcreate,__TEXT,__info_plist,"):
        return None

    # Use Xcode set `DEVELOPER_DIR`
    linkopt = linkopt.replace(
        "__BAZEL_XCODE_DEVELOPER_DIR__",
        "$(DEVELOPER_DIR)",
    )

    return linkopt

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
    top_level_values = (
        linker_inputs._top_level_values if linker_inputs else None
    )
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
            for file in top_level_values.static_libraries
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

def _to_input_files(linker_inputs):
    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return []

    return (
        top_level_values.additional_input_files +
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
    collect = _collect,
    merge = _merge,
    get_primary_static_library = _get_primary_static_library,
    get_static_libraries = _get_static_libraries,
    to_dto = _to_dto,
    to_input_files = _to_input_files,
)

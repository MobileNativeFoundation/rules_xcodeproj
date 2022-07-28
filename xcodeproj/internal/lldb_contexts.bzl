"""Module containing functions dealing with the `LLDBContext` DTO."""

load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path_to_dto",
    "is_generated_file_path",
    "parsed_file_path",
)
load(":opts.bzl", "swift_pcm_copts")

def _collect(
        *,
        compilation_mode = None,
        objc_fragment = None,
        id,
        is_swift,
        search_paths,
        modulemaps = None,
        swiftmodules = None,
        transitive_infos):
    """Collects lldb context information for a target.

    Args:
        compilation_mode: The current compilation mode.
        objc_fragment: The `objc` configuration fragment.
        id: The unique identifier of the target.
        is_swift: Whether the target compiles Swift code.
        search_paths: A value returned from `target_search_paths.make`.
        modulemaps: The value returned from `process_modulemaps`.
        swiftmodules: The value returned from `process_swiftmodules`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be passed to `lldb_contexts.to_dto`.
    """
    framework_paths = []
    clang = []
    if id and is_swift and search_paths and search_paths._compilation_providers:
        clang_opts = " ".join(swift_pcm_copts(
            compilation_mode = compilation_mode,
            objc_fragment = objc_fragment,
            cc_info = search_paths._compilation_providers._cc_info,
        ))

        clang = [(
            id,
            struct(
                search_paths = search_paths,
                modulemaps = modulemaps,
                opts = clang_opts,
            ),
        )]

        objc = search_paths._compilation_providers._objc
        if objc:
            framework_paths = [depset(
                transitive = [
                    objc.static_framework_paths,
                    objc.dynamic_framework_paths,
                ],
            )]

    return struct(
        _clang = depset(
            clang,
            transitive = [
                info.lldb_context._clang
                for info in transitive_infos
            ],
            order = "topological",
        ),
        _framework_search_paths = depset(
            transitive = framework_paths + [
                info.lldb_context._framework_search_paths
                for info in transitive_infos
            ],
            order = "topological",
        ),
        _swiftmodules = depset(
            swiftmodules,
            transitive = [
                info.lldb_context._swiftmodules
                for info in transitive_infos
            ],
            order = "topological",
        ),
    )

def _to_dto(lldb_context):
    if not lldb_context:
        return {}

    dto = {}

    framework_file_paths = [
        parsed_file_path(path)
        for path in lldb_context._framework_search_paths.to_list()
    ]
    set_if_true(
        dto,
        "f",
        [
            file_path_to_dto(fp)
            for fp in framework_file_paths
            if not is_generated_file_path(fp)
        ],
    )

    set_if_true(
        dto,
        "s",
        [file_path_to_dto(fp) for fp in lldb_context._swiftmodules.to_list()],
    )

    clang_dtos = []
    for _, clang in lldb_context._clang.to_list():
        # TODO: DRY this up with `target_search_paths`
        search_paths = clang.search_paths
        cc_info = search_paths._compilation_providers._cc_info
        compilation_context = cc_info.compilation_context
        opts_search_paths = search_paths._opts_search_paths

        if opts_search_paths:
            opts_includes = list(opts_search_paths.includes)
            opts_quote_includes = list(opts_search_paths.quote_includes)
            opts_system_includes = list(opts_search_paths.system_includes)
        else:
            opts_includes = []
            opts_quote_includes = []
            opts_system_includes = []

        quote_includes = depset(
            [".", search_paths._bin_dir_path] + opts_quote_includes,
            transitive = [compilation_context.quote_includes],
        )

        clang_dto = {}

        set_if_true(
            clang_dto,
            "q",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in quote_includes.to_list()
            ],
        )
        set_if_true(
            clang_dto,
            "i",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.includes.to_list() +
                             opts_includes)
            ],
        )
        set_if_true(
            clang_dto,
            "s",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.system_includes.to_list() +
                             opts_system_includes)
            ],
        )

        modulemaps = clang.modulemaps
        if modulemaps:
            set_if_true(
                clang_dto,
                "m",
                [file_path_to_dto(fp) for fp in clang.modulemaps.file_paths],
            )

        set_if_true(clang_dto, "o", clang.opts)

        clang_dtos.append(clang_dto)

    set_if_true(dto, "c", clang_dtos)

    return dto

lldb_contexts = struct(
    collect = _collect,
    to_dto = _to_dto,
)

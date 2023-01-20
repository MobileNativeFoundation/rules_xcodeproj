"""Module containing functions dealing with the `LLDBContext` DTO."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true", "uniq")
load(
    ":files.bzl",
    "build_setting_path",
    "is_generated_path",
)

def _collect_lldb_context(
        *,
        id,
        is_swift,
        clang_opts,
        search_paths,
        modulemaps = None,
        swiftmodules = None,
        transitive_infos):
    """Collects lldb context information for a target.

    Args:
        id: The unique identifier of the target.
        is_swift: Whether the target compiles Swift code.
        clang_opts: A `list` of Swift PCM (clang) compiler options.
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
        clang = [(
            id,
            struct(
                search_paths = search_paths,
                modulemaps = modulemaps,
                opts = tuple(clang_opts),
            ),
        )]

        opts_search_paths = search_paths._opts_search_paths
        if opts_search_paths:
            framework_paths = opts_search_paths.framework_includes
        else:
            framework_paths = tuple()

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
            direct = framework_paths,
            transitive = [
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

def _lldb_context_to_dto(lldb_context, *, xcode_generated_paths):
    if not lldb_context:
        return {}

    dto = {}

    set_if_true(
        dto,
        "f",
        [
            build_setting_path(path = path)
            for path in lldb_context._framework_search_paths.to_list()
            if not is_generated_path(path)
        ],
    )

    def _handle_swiftmodule_path(file):
        path = file.path
        bs_path = xcode_generated_paths.get(path)
        if not bs_path:
            bs_path = build_setting_path(
                file = file,
                path = path,
            )
        return paths.dirname(bs_path)

    set_if_true(
        dto,
        "s",
        uniq([
            _handle_swiftmodule_path(file)
            for file in lldb_context._swiftmodules.to_list()
        ]),
    )

    clang_dtos = []
    for _, clang in lldb_context._clang.to_list():
        clang_dto = {}
        set_if_true(clang_dto, "o", clang.opts)
        clang_dtos.append(clang_dto)

    set_if_true(dto, "c", clang_dtos)

    return dto

lldb_contexts = struct(
    collect = _collect_lldb_context,
    to_dto = _lldb_context_to_dto,
)

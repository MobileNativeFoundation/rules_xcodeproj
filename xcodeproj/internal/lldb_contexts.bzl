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
        search_paths = None,
        swiftmodules = None,
        transitive_infos):
    """Collects lldb context information for a target.

    Args:
        id: The unique identifier of the target.
        is_swift: Whether the target compiles Swift code.
        clang_opts: A `list` of Swift PCM (clang) compiler options.
        search_paths: A value returned from `process_opts`.
        swiftmodules: The value returned from `process_swiftmodules`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be passed to `lldb_contexts.to_dto`.
    """
    framework_paths = []
    clang = []
    if id and is_swift and search_paths:
        clang = [(id, tuple(clang_opts))]

        if search_paths:
            framework_paths = search_paths.framework_includes
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

_ONCE_FLAGS = {
    "-D": None,
    "-F": None,
    "-I": None,
}

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

    once_flags = {}
    clang_opts = []
    for _, opts in lldb_context._clang.to_list():
        for opt in opts:
            if opt in once_flags:
                continue
            if (opt[0:2] in _ONCE_FLAGS) or opt.startswith("-fmodule-map-file="):
                # This can lead to correctness issues if the value of a define
                # is specified multiple times, and different on different
                # targets, but it's how lldb currently handles it. Ideally it
                # should use a dictionary for the key of the define and only
                # filter ones that have the same value as the last time the key
                # was used.
                once_flags[opt] = None
            clang_opts.append(opt)

    set_if_true(dto, "c", " ".join(clang_opts))

    return dto

lldb_contexts = struct(
    collect = _collect_lldb_context,
    to_dto = _lldb_context_to_dto,
)

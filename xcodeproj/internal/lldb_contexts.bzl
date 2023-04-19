"""Module containing functions dealing with the `LLDBContext` DTO."""

def _collect_lldb_context(
        *,
        id,
        is_swift,
        clang_opts,
        implementation_compilation_context = None,
        swiftmodules = None,
        transitive_infos):
    """Collects lldb context information for a target.

    Args:
        id: The unique identifier of the target.
        is_swift: Whether the target compiles Swift code.
        clang_opts: A `list` of Swift PCM (clang) compiler options.
        implementation_compilation_context: The implementation deps aware
            `CcCompilationContext` for the target.
        swiftmodules: The value returned from `process_swiftmodules`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be passed to `lldb_contexts.to_dto`.
    """
    framework_paths = []
    clang = None
    if id and is_swift and implementation_compilation_context:
        clang = [(id, tuple(clang_opts))]

        if implementation_compilation_context:
            framework_paths = [
                implementation_compilation_context.framework_includes,
            ]

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

lldb_contexts = struct(
    collect = _collect_lldb_context,
)

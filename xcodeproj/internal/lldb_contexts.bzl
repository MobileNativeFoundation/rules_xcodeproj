"""Module containing functions dealing with the `LLDBContext` DTO."""

load(":memory_efficiency.bzl", "memory_efficient_depset")

def _collect_lldb_context(
        *,
        id,
        is_swift,
        swift_sub_params = None,
        framework_includes = None,
        swiftmodules = None,
        transitive_infos):
    """Collects lldb context information for a target.

    Args:
        id: The unique identifier of the target.
        is_swift: Whether the target compiles Swift code.
        swift_sub_params: A `list` of `File`s of Swift compiler options.
        framework_includes: A `depset` of framework include paths.
        swiftmodules: The value returned from `process_swiftmodules`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be passed to `lldb_contexts.to_dto`.
    """
    framework_paths = []
    labelled_swift_sub_params = None
    if id and is_swift:
        if swift_sub_params:
            labelled_swift_sub_params = [(id, tuple(swift_sub_params))]

        if framework_includes:
            framework_paths = [framework_includes]

    return struct(
        _labelled_swift_sub_params = memory_efficient_depset(
            labelled_swift_sub_params,
            transitive = [
                info.lldb_context._labelled_swift_sub_params
                for info in transitive_infos
            ],
            order = "topological",
        ),
        _swift_sub_params = memory_efficient_depset(
            swift_sub_params,
            transitive = [
                info.lldb_context._swift_sub_params
                for info in transitive_infos
            ],
            order = "topological",
        ),
        _framework_search_paths = memory_efficient_depset(
            transitive = framework_paths + [
                info.lldb_context._framework_search_paths
                for info in transitive_infos
            ],
            order = "topological",
        ),
        _swiftmodules = memory_efficient_depset(
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

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
    framework_paths = None
    clang = None
    if id and is_swift and search_paths:
        clang = [(id, tuple(clang_opts))]

        if search_paths:
            framework_paths = search_paths.framework_includes

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

def  _labelless_clang_opts(clangopt_with_label):
    _, opts = clangopt_with_label
    return opts

def _non_generated_framework_build_setting_path(path):
    if is_generated_path(path):
        return None
    return build_setting_path(path = path)

def _lldb_context_to_json_file(
        lldb_context,
        *,
        actions,
        context_index,
        lldb_context_processor,
        rule_name,
        target_name,
        xcode_generated_paths_file):
    if not lldb_context:
        return None

    # framework_paths
    framework_paths_file = actions.declare_file(
        "{}-lldb_contexts/{}.{}.framework_paths".format(
            rule_name,
            target_name,
            context_index,
        ),
    )
    framework_paths_args = actions.args()
    framework_paths_args.set_param_file_format(format = "multiline")
    framework_paths_args.add_all(
        lldb_context._framework_search_paths,
        map_each = _non_generated_framework_build_setting_path,
    )
    actions.write(
        output = framework_paths_file,
        content = framework_paths_args,
    )

    # framework_paths
    swiftmodule_paths_file = actions.declare_file(
        "{}-lldb_contexts/{}.{}.swiftmodule_paths".format(
            rule_name,
            target_name,
            context_index,
        ),
    )
    swiftmodule_paths_args = actions.args()
    swiftmodule_paths_args.set_param_file_format(format = "multiline")
    swiftmodule_paths_args.add_all(lldb_context._swiftmodules)
    actions.write(
        output = swiftmodule_paths_file,
        content = swiftmodule_paths_args,
    )

    # clang_opts
    clang_opts_file = actions.declare_file(
        "{}-lldb_contexts/{}.{}.clang_opts".format(
            rule_name,
            target_name,
            context_index,
        ),
    )
    clang_opts_args = actions.args()
    clang_opts_args.set_param_file_format(format = "multiline")
    clang_opts_args.add_all(
        lldb_context._clang,
        map_each = _labelless_clang_opts,
    )
    actions.write(
        output = clang_opts_file,
        content = clang_opts_args,
    )

    # lldb_context.json
    output = actions.declare_file(
        "{}-lldb_contexts/{}.{}.lldb_context.json".format(
            rule_name,
            target_name,
            context_index,
        ),
    )
    args = actions.args()
    args.add(xcode_generated_paths_file)
    args.add(framework_paths_file)
    args.add(swiftmodule_paths_file)
    args.add(clang_opts_file)
    args.add(output)
    actions.run(
        executable = lldb_context_processor,
        arguments = [args],
        mnemonic = "ProcessLLDBContext",
        progress_message = "Generating %{output}",
        inputs = [
            framework_paths_file,
            clang_opts_file,
            swiftmodule_paths_file,
            xcode_generated_paths_file,
        ],
        outputs = [output],
    )
    return output

lldb_contexts = struct(
    collect = _collect_lldb_context,
    to_json_file = _lldb_context_to_json_file,
)

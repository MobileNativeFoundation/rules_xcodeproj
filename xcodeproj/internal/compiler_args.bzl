"""Module for collecting compiler args."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_LIST")

def _swift_preview_inputs(action, swift_info):
    """Collects cheap owned manifests separately from native import preparation."""
    inputs = {file.path: file for file in action.inputs.to_list()}
    outputs = {file.path: None for file in action.outputs.to_list()}
    manifests = []
    argv = action.argv
    for i in range(len(argv) - 3):
        if argv[i:i + 3] != ["-Xfrontend", "-explicit-swift-module-map-file", "-Xfrontend"]:
            continue
        file = inputs.get(argv[i + 3])
        if file and (file.basename.endswith(".swift-explicit-module-map.json") or
                     file.basename.endswith(".swift-system-explicit-module-map.json")):
            manifests.append(file)

    import_files = []
    import_paths = []
    if swift_info:
        # The direct context is the exact compile inventory; propagated
        # providers can also contain re-exports and the selected module itself.
        dependency_paths = {}
        for module in swift_info.direct_modules:
            context = getattr(module, "compilation_context", None)
            if context:
                import_files.extend([
                    file
                    for file in getattr(context, "direct_sources", ())
                    if not file.is_source
                ])
                for file in context.module_maps + context.swiftmodules:
                    if type(file) == "File":
                        dependency_paths[file.path] = None
        for module in swift_info.transitive_modules.to_list():
            if getattr(module, "is_system", False) or getattr(module, "is_framework", False):
                continue
            swift = getattr(module, "swift", None)
            swiftmodule = getattr(swift, "swiftmodule", None) if swift else None
            if type(swiftmodule) == "File" and swiftmodule.path in dependency_paths and swiftmodule.path not in outputs:
                import_files.append(swiftmodule)
                import_paths.append(swiftmodule.path)
            clang = getattr(module, "clang", None)
            module_map = getattr(clang, "module_map", None) if clang else None
            context = getattr(clang, "compilation_context", None) if clang else None
            if type(module_map) == "File" and module_map.path in dependency_paths and module_map.path not in outputs and context:
                headers = context.headers.to_list()

                # Never prepare the selected action's own generated header.
                if not any([header.path in outputs for header in headers]):
                    import_files.append(module_map)
                    import_files.extend(headers)
                    import_paths.append(module_map.path)
    return struct(
        manifests = tuple(manifests),
        files = depset(import_files),
        paths = tuple(depset(import_paths).to_list()),
    )

# Compiler option processing

_CC_COMPILE_ACTIONS = {
    "CppCompile": None,
    "ObjcCompile": None,
}

def _get_unprocessed_cc_compiler_opts(
        *,
        c_sources,
        cxx_sources,
        target):
    conly_args = EMPTY_LIST
    cxx_args = EMPTY_LIST

    if not c_sources and not cxx_sources:
        return (conly_args, cxx_args)

    for action in target.actions:
        if action.mnemonic not in _CC_COMPILE_ACTIONS:
            continue

        previous_arg = None
        for arg in action.argv:
            if previous_arg == "-c":
                if not conly_args and arg in c_sources:
                    conly_args = action.args
                elif not cxx_args and arg in cxx_sources:
                    cxx_args = action.args
                break
            previous_arg = arg

        if ((not c_sources or conly_args) and
            (not cxx_sources or cxx_args)):
            # We've found all the args we are looking for
            break

    return conly_args, cxx_args

def _cc_preview_inputs(actions, source_paths, compilation_context):
    # The selected Clang target's real inputs, not the mixed wrapper's public
    # headers (which include a symlink to its own Swift compiler output).
    generated_sources = {}
    for action in actions:
        if action.mnemonic not in _CC_COMPILE_ACTIONS:
            continue
        for file in action.inputs.to_list():
            if not file.is_source and file.path in source_paths:
                generated_sources[file] = None
    return depset(
        generated_sources.keys(),
        transitive = [compilation_context.headers] if compilation_context else [],
    )

# API

def _collect_compiler_args(
        *,
        c_sources,
        cxx_sources,
        target):
    """Collects the compiler args for a target.

    Args:
        c_sources: A `dict` of C source paths.
        cxx_sources: A `dict` of C++ source paths.
        target: The `Target` that the compiler and linker options will be
            retrieved from.

    Returns:
        A `struct` with the following fields:

        *   `conly`: A `list` of `Args` for the C compile action for this
            target.
        *   `cxx`: A `list` of `Args` for the C++ compile action for this
            target.
        *   `swift`: A `list` of `Args` for the `SwiftCompile` action for this
            target.
    """
    swift_args = EMPTY_LIST
    swift_preview_inputs = struct(manifests = (), files = depset(), paths = ())
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            swift_args = action.args
            swift_preview_inputs = _swift_preview_inputs(
                action,
                target[SwiftInfo] if SwiftInfo in target else None,
            )
            break

    conly_args, cxx_args = _get_unprocessed_cc_compiler_opts(
        c_sources = c_sources,
        cxx_sources = cxx_sources,
        target = target,
    )

    if conly_args or cxx_args:
        cc_info = target[CcInfo] if CcInfo in target else None
        source_paths = dict(c_sources)
        source_paths.update(cxx_sources)
        cc_inputs = _cc_preview_inputs(
            target.actions,
            source_paths,
            cc_info.compilation_context if cc_info else None,
        )
        swift_preview_inputs = struct(
            manifests = swift_preview_inputs.manifests,
            files = depset(transitive = [swift_preview_inputs.files, cc_inputs]),
            paths = swift_preview_inputs.paths,
        )

    return struct(
        conly = conly_args,
        cxx = cxx_args,
        swift = swift_args,
        swift_preview_inputs = swift_preview_inputs,
    )

compiler_args = struct(
    collect = _collect_compiler_args,
    cc_preview_inputs = _cc_preview_inputs,
    swift_preview_inputs = _swift_preview_inputs,
)

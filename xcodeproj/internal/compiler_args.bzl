"""Module for collecting compiler args."""

load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_LIST")

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
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            swift_args = action.args
            break

    conly_args, cxx_args = _get_unprocessed_cc_compiler_opts(
        c_sources = c_sources,
        cxx_sources = cxx_sources,
        target = target,
    )

    return struct(
        conly = conly_args,
        cxx = cxx_args,
        swift = swift_args,
    )

compiler_args = struct(
    collect = _collect_compiler_args,
)

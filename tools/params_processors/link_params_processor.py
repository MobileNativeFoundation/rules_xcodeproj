#!/usr/bin/python3

import json
import shlex
import sys
from typing import List


# linker flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_LD_SKIP_OPTS = {
    # Xcode sets the output path
    "-o": 2,

    # Xcode sets these, and no way to unset it
    "-bundle": 1,
    "-bundle_loader": 2,
    "-dynamiclib": 1,
    "-e": 2,
    "-isysroot": 2,
    "-static": 1,
    "-target": 2,

    # Xcode sets this, even if `CLANG_LINK_OBJC_RUNTIME = NO` is set
    "-fobjc-link-runtime": 1,

    # This is wrapped_clang specific, and we don't want to translate it for BwX
    "-Wl,-oso_prefix,__BAZEL_EXECUTION_ROOT__/": 1,
    "OSO_PREFIX_MAP_PWD": 1,
}

_WL_PATH_OPTS = {
    "-add_ast_path",
    "-alias_list",
    "-assert_weak_library",
    "-bundle_loader",
    "-delay_library",
    "-dirty_data_list",
    "-dtrace",
    "-exported_symbols_list",
    "-filelist",
    "-force_load",
    "-interposable_list",
    "-lazy_library",
    "-load_hidden",
    "-lto_library",
    "-merge_library",
    "-needed_library",
    "-non_global_symbols_no_strip_list",
    "-non_global_symbols_strip_list",
    "-order_file",
    "-reexport_library",
    "-reexported_symbols_list",
    "-unexported_symbols_list",
    "-upward_library",
    "-weak_library",
}

_WL_POSITIONAL_PATH_OPTS = {
    "-filelist": (1, 2),
    "-sectcreate": (3,),
    "-sectorder": (3,),
}

_SPLIT_PATH_OPTS = _WL_PATH_OPTS | {
    "-F",
    "-L",
    "-iframework",
    "-rpath",
}

_SPLIT_NON_PATH_OPTS = {
    "-allowable_client",
    "-compatibility_version",
    "-current_version",
    "-dylib_compatibility_version",
    "-dylib_current_version",
    "-framework",
    "-install_name",
    "-sub_umbrella",
    "-u",
    "-umbrella",
    "-undefined",
    "-weak_framework",
}

_DIRECT_INPUT_SUFFIXES = (
    ".a",
    ".dylib",
    ".tbd",
)

_LIBRARY_INPUT_OPTS = {
    "-assert_weak_library",
    "-delay_library",
    "-filelist",
    "-force_load",
    "-lazy_library",
    "-load_hidden",
    "-merge_library",
    "-needed_library",
    "-reexport_library",
    "-upward_library",
    "-weak_library",
}


_STATIC_OPTION_OPERANDS = {
    **{option: 1 for option in _SPLIT_PATH_OPTS | _SPLIT_NON_PATH_OPTS},
    "-sectcreate": 3, "-sectorder": 3, "-sectalign": 3,
    "-reexport_framework": 1, "-upward_framework": 1, "-needed_framework": 1,
    "-Xclang": 1, "-mllvm": 1, "-Xassembler": 1,
    "-o": 1, "-e": 1, "-target": 1, "-arch": 1, "-isysroot": 1,
    "-objc_abi_version": 1, "-object_path_lto": 1,
}


def _static_option_group_end(linkopts, index, *, driver_wrappers=False):
    opt = linkopts[index]
    forwarded = driver_wrappers and opt == "-Xlinker"
    if forwarded:
        index += 1
        if index == len(linkopts):
            raise ValueError("Malformed -Xlinker linker group")
        opt = linkopts[index]
    index += 1
    for _ in range(_STATIC_OPTION_OPERANDS.get(opt, 0)):
        if forwarded and index < len(linkopts) and linkopts[index] == "-Xlinker":
            index += 1
        if index == len(linkopts):
            raise ValueError("Malformed " + opt + " option group")
        index += 1
    return index


def _split_static_runtime_policy(linkopts):
    """Separates declared driver policy before converting to linker tokens.

    Provider values are raw argv, not shell text. Forwarded linker/compiler
    values and known option operands are not driver options. Opaque dependency
    response files remain linker inputs; do not build/read them for this query.
    """
    policy_options = {
        "-fprofile-generate", "-fno-profile-generate",
        "-fprofile-instr-generate", "-fno-profile-instr-generate",
        "-nostdlib", "-nodefaultlibs", "-nostartfiles", "-nostdlib++",
        "-fobjc-link-runtime", "-fno-objc-link-runtime",
    }
    policy_prefixes = (
        "-fprofile-generate=", "-fprofile-instr-generate=", "-rtlib=", "--rtlib=",
    )
    remaining, policy = [], []
    index = 0
    while index < len(linkopts):
        opt = linkopts[index]
        if opt in policy_options or any(opt.startswith(prefix) for prefix in policy_prefixes):
            policy.append(opt)
            index += 1
            continue
        start = index
        index = _static_option_group_end(linkopts, index, driver_wrappers=True)
        remaining.extend(linkopts[start:index])
    return remaining, policy


def _remove_generated_inputs(linkopts, generated_product_paths, *, driver_wrappers=True):
    """Removes exact native products together with their linker option group."""
    result = []
    index = 0
    while index < len(linkopts):
        opt = linkopts[index]
        if driver_wrappers and opt.startswith("-Wl,"):
            values = _remove_generated_inputs(
                opt[4:].split(","), generated_product_paths,
            )
            if values:
                result.append("-Wl," + ",".join(values))
            index += 1
            continue

        # Read a driver-forwarded linker token without leaving its -Xlinker
        # behind when the token or its complete library binding is removed.
        option_index = index + (driver_wrappers and opt == "-Xlinker")
        if option_index >= len(linkopts):
            result.append(opt)
            break
        option = linkopts[option_index]
        end = option_index + 1
        if option in _WL_POSITIONAL_PATH_OPTS and option != "-filelist":
            # Section arguments are metadata/content, not positional libraries.
            for _ in range(max(_WL_POSITIONAL_PATH_OPTS[option])):
                if driver_wrappers and end < len(linkopts) and linkopts[end] == "-Xlinker":
                    end += 1
                end = min(end + 1, len(linkopts))
        elif option in _SPLIT_PATH_OPTS | _SPLIT_NON_PATH_OPTS:
            value_index = end
            if driver_wrappers and value_index < len(linkopts) and linkopts[value_index] == "-Xlinker":
                value_index += 1
            if value_index < len(linkopts):
                end = value_index + 1
                if (option in _LIBRARY_INPUT_OPTS and
                    linkopts[value_index] in generated_product_paths):
                    index = end
                    continue
        elif option in generated_product_paths:
            index = end
            continue

        result.extend(linkopts[index:end])
        index = end
    return result


def _parse_args(args_files: List[str], *, expand_response_files: bool = True) -> List[str]:
    def _is_redirect(arg: str) -> bool:
        # dyld paths are linker values, not response files.
        return arg.startswith("@") and not any(
            arg == prefix or arg.startswith(prefix + "/")
            for prefix in ("@rpath", "@loader_path", "@executable_path")
        )

    raw_args = []
    for args_path in args_files:
        # Each argument is a path to a file containing the actual arguments
        with open(args_path, encoding = "utf-8") as fp:
            raw_args.extend(fp.read().splitlines())

    if not raw_args:
        raise ValueError("Link arguments do not contain a tool")

    def _expand_redirect(arg: str) -> List[str]:
        redirect_path = arg[1:]
        if not redirect_path:
            raise ValueError("Link arguments contain an empty redirect")
        with open(redirect_path, encoding = "utf-8") as fp:
            redirected_args = fp.read().splitlines()
        if not redirected_args:
            raise ValueError("Link arguments contain an empty redirect")
        if any(_is_redirect(arg) for arg in redirected_args):
            raise ValueError("Nested link argument redirects are unsupported")
        return redirected_args

    # Some actions put their complete tool-plus-arguments list behind one
    # redirect. Expand that first-level redirect before dropping the tool.
    if expand_response_files and _is_redirect(raw_args[0]):
        raw_args = _expand_redirect(raw_args[0]) + raw_args[1:]

    tool = raw_args[0]
    if not tool or tool.startswith("-") or tool.startswith("@"):
        raise ValueError("Link arguments do not contain a tool")

    if not expand_response_files:
        return raw_args[1:]

    # The first argument across all chunks is the tool name. Later chunks start
    # with real arguments and must not lose their first value.
    args = []
    for arg in raw_args[1:]:
        if _is_redirect(arg):
            args.extend(_expand_redirect(arg))
        else:
            args.append(arg)

    return args

def _quote_if_needed(opt: str) -> str:
    # This is a Clang response file, not a shell command. Quote the whole
    # argument and escape response syntax. Double quotes also allow apostrophes
    # introduced later by expansion of PROJECT_DIR or another build setting.
    if any(character in opt for character in " \t\n\r'\"\\") or "$(" in opt:
        return '"' + opt.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return opt


def _anchor_to_execution_root(
        opt: str, *, path_context: bool = False, response_files: bool = False,
        source_archive: bool = True,
    ) -> str:
    """Makes a relative linker input readable by Xcode's Preview analyzer.

    Relative inputs are relative to the Bazel execution root, which
    `-working-directory` covers for the real link. The Preview analyzer
    re-parses the rendered invocation without honoring that working directory,
    so path-like inputs must carry their execution-root anchor explicitly.
    Workspace source archives instead use SRCROOT so concurrent Bazel builds
    cannot interrupt their availability by replanting execution-root symlinks.

    This response is consumed by Clang, including the Preview analyzer's
    request for an expanded ld invocation. Quote the entire anchored argument:
    the build-setting expansion can itself contain spaces. Clang removes the
    response-file quoting before emitting the absolute paths for the analyzer.
    """
    def _anchor_path(
            path: str, *, allow_bare: bool = False, archive: bool = source_archive
        ) -> str:
        if (not path.startswith(("-", "@", "/", "$")) and
            (allow_bare or "/" in path or path.endswith(_DIRECT_INPUT_SUFFIXES))):
            # Canonical workspace archives are source files, not Bazel outputs.
            # Index builds can replant their execution-root symlinks while the
            # Preview analyzer is loading them after native preparation ends.
            if (archive and path.endswith(".a") and
                not path.startswith(("bazel-out/", "external/")) and
                not any(part in (".", "..") for part in path.split("/"))):
                return "$(SRCROOT)/" + path
            return "$(PROJECT_DIR)/" + path
        return path

    if response_files and opt.startswith("@") and not any(
        opt == prefix or opt.startswith(prefix + "/")
        for prefix in ("@rpath", "@loader_path", "@executable_path")
    ):
        return _quote_if_needed("@" + _anchor_path(opt[1:], allow_bare=True, archive=False))

    anchored = _anchor_path(opt, allow_bare=path_context)
    if anchored != opt:
        return _quote_if_needed(anchored)

    for prefix in ("-F", "-L"):
        if opt.startswith(prefix) and len(opt) > len(prefix):
            path = opt[len(prefix):]
            anchored_path = _anchor_path(path, allow_bare=True, archive=False)
            if anchored_path != path:
                return _quote_if_needed(prefix + anchored_path)

    if opt.startswith("-Wl,"):
        values = opt.split(",")
        for index, value in enumerate(values[:-1]):
            if value in _WL_PATH_OPTS:
                values[index + 1] = _anchor_path(
                    values[index + 1],
                    allow_bare=True,
                    archive=value in _LIBRARY_INPUT_OPTS and value != "-filelist",
                )
            for offset in _WL_POSITIONAL_PATH_OPTS.get(value, ()):
                path_index = index + offset
                if path_index < len(values):
                    values[path_index] = _anchor_path(
                        values[path_index],
                        allow_bare=True,
                        archive=False,
                    )
        anchored = ",".join(values)
        if anchored != opt:
            return _quote_if_needed(anchored)

    return _quote_if_needed(opt)


def _static_library_linkopts(linkopts):
    """Unwraps driver flags for Xcode's Libtool Preview-info consumer."""
    result = []
    index = 0
    while index < len(linkopts):
        opt = linkopts[index]
        end = _static_option_group_end(linkopts, index, driver_wrappers=True)
        if opt == "-Xlinker":
            result.append(linkopts[index + 1])
            index += 2
            while index < end:
                if linkopts[index] == "-Xlinker":
                    index += 1
                result.append(linkopts[index])
                index += 1
        else:
            result.extend(opt[4:].split(",") if opt.startswith("-Wl,") else linkopts[index:end])
        index = end

    # These describe Bazel's debug outputs, not runtime dependencies. Xcode
    # produces its own equivalents; do not compile the selected target in Bazel
    # just to populate a Preview metadata response.
    debug_options = {"-add_ast_path", "-object_path_lto", "-objc_abi_version"}
    filtered = []
    index = 0
    while index < len(result):
        end = _static_option_group_end(result, index)
        if result[index] in debug_options:
            if index + 1 == len(result) or result[index + 1].startswith("-"):
                raise ValueError("Malformed " + result[index] + " linker group")
        else:
            filtered.extend(result[index:end])
        index = end
    return filtered


def _process_linkopts(
        linkopts: List[str],
        is_framework: bool,
        generated_product_paths: List[str],
        *, is_static_library: bool = False,
    ) -> List[str]:
    # Bazel action arguments may have shell quoting. Static provider arguments
    # are already individual values: their quote characters are literal data.
    if not is_static_library:
        linkopts = [
            shlex.split(opt)[0] if opt.startswith("'") and opt.endswith("'") else opt
            for opt in linkopts
        ]
    excluded = set(generated_product_paths)
    if is_static_library:
        linkopts = _static_library_linkopts(linkopts)
        excluded.update("@" + path for path in generated_product_paths)
    linkopts = _remove_generated_inputs(
        linkopts, excluded, driver_wrappers=not is_static_library,
    )
    static_operands = set()
    if is_static_library:
        index = 0
        while index < len(linkopts):
            end = _static_option_group_end(linkopts, index)
            static_operands.update(range(index + 1, end))
            index = end

    def _process_filelist(filelist_path: str) -> List[str]:
        with open(filelist_path, encoding = "utf-8") as fp:
            paths = fp.read().splitlines()

        return [
            _anchor_to_execution_root(path)
            for path in paths
            if not path in generated_product_paths and not path.endswith(".o")
        ]

    for index, linkopt in enumerate(linkopts):
        if index in static_operands:
            continue
        if linkopt == "-objc_abi_version":
            if (index < 1 or
                index + 2 >= len(linkopts) or
                linkopts[index - 1] != "-Xlinker" or
                linkopts[index + 1] != "-Xlinker" or
                not linkopts[index + 2] or
                linkopts[index + 2].startswith("-")):
                raise ValueError("Malformed -objc_abi_version linker group")
        if linkopt == "-object_path_lto":
            if (index < 1 or
                index + 2 >= len(linkopts) or
                linkopts[index - 1] != "-Xlinker" or
                linkopts[index + 1] != "-Xlinker" or
                not linkopts[index + 2] or
                not linkopts[index + 2].endswith(".lto.o")):
                raise ValueError("Malformed -object_path_lto linker group")

    processed_linkopts = []
    last_opt = None
    def _process_linkopt(opt, index):
        if not is_static_library and opt == "-filelist":
            return
        if not is_static_library and last_opt == "-filelist":
            # `_process_filelist` anchors and quotes each entry as needed.
            processed_linkopts.extend(_process_filelist(opt))
            return

        # Xcode sets entitlements
        if opt.startswith((
            "-Wl,-sectcreate,__TEXT,__entitlements,",
            "-Wl,-sectcreate,__TEXT,__ents_der,",
        )):
            return

        # Xcode sets Info.plist
        if opt.startswith("-Wl,-sectcreate,__TEXT,__info_plist,"):
            return

        # Xcode adds object files
        if not is_static_library and opt.endswith(".o"):
            return

        # We don't want the BwB swizzle fix for BwX mode
        if opt.endswith((
            "/libswizzle_absolute_xcttestsourcelocation.a",
            "/libswizzle_absolute_xcttestsourcelocation.lo",
        )):
            if last_opt == "-force_load":
                processed_linkopts.pop()
            return

        # These flags are for wrapped_clang only
        if (opt.startswith("DSYM_HINT_DSYM_PATH=") or
            opt.startswith("DSYM_HINT_LINKED_BINARY=") or
            opt.startswith("LINKED_BINARY=")):
            return

        # Use Xcode set `DEVELOPER_DIR`
        opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

        # Use Xcode set `SDKROOT`
        opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

        previous_option = None
        previous_index = index - 1
        if (not is_static_library and previous_index >= 0 and
            linkopts[previous_index] == "-Xlinker"):
            previous_index -= 1
        if (previous_index >= 0 and
            previous_index not in static_operands and
            linkopts[previous_index].startswith("-") and
            linkopts[previous_index] != "-Xlinker"):
            previous_option = linkopts[previous_index]

        if previous_option in _SPLIT_NON_PATH_OPTS:
            processed_linkopts.append(_quote_if_needed(opt))
        else:
            processed_linkopts.append(_anchor_to_execution_root(
                opt,
                path_context=(previous_option in _SPLIT_PATH_OPTS or
                              (is_static_library and opt.endswith(".o"))),
                response_files=is_static_library,
                source_archive=(previous_option not in _SPLIT_PATH_OPTS or
                                previous_option in _LIBRARY_INPUT_OPTS - {"-filelist"}),
            ))

    skip_next = 0
    for index, linkopt in enumerate(linkopts):
        if skip_next:
            skip_next -= 1
            continue
        if index in static_operands:
            _process_linkopt(linkopt, index)
            last_opt = linkopt
            continue

        # Xcode provides its own LTO object path. Remove the complete Bazel
        # driver group so the leading `-Xlinker` can't become orphaned and
        # consume the next option as the value of `-object_path_lto`.
        if (linkopt == "-Xlinker" and
            index + 1 < len(linkopts) and
            linkopts[index + 1] == "-object_path_lto"):
            skip_next = 3
            continue

        skip_next = _LD_SKIP_OPTS.get(linkopt, 0)
        if skip_next:
            skip_next -= 1
            continue

        _process_linkopt(linkopt, index)
        last_opt = linkopt

    return processed_linkopts


def _main(
        output_path: str,
        generated_product_paths_file: str,
        is_framework: bool,
        args_files: List[str],
        *, is_static_library: bool = False,
    ) -> None:
    with open(generated_product_paths_file, encoding = "utf-8") as fp:
        generated_product_paths = json.load(fp)

    linkopts = _parse_args(args_files, expand_response_files=not is_static_library)
    if is_static_library:
        linkopts, runtime_policy = _split_static_runtime_policy(linkopts)
    linkopts = _process_linkopts(
        linkopts = linkopts,
        is_framework = is_framework,
        generated_product_paths = generated_product_paths,
        is_static_library = is_static_library,
    )

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(linkopts)
        fp.write(f'{result}\n')
    if is_static_library:
        with open(output_path + ".runtime.json", encoding = "utf-8", mode = "w") as fp:
            json.dump(runtime_policy, fp, separators=(",", ":"))
            fp.write("\n")


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print(
            f"""
Usage: {sys.argv[0]} <output> <self_linked_outputs_file> <is_framework|static> \
<args_files...>\
""",
            file = sys.stderr,
        )
        exit(1)

    _main(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3] == "1",
        sys.argv[4:],
        is_static_library = sys.argv[3] == "static",
    )

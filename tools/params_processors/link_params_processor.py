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


def _parse_args(args_files: List[str]) -> List[str]:
    raw_args = []
    for args_path in args_files:
        # Each argument is a path to a file containing the actual arguments
        with open(args_path, encoding = "utf-8") as fp:
            raw_args.extend(fp.read().splitlines())

    if not raw_args:
        raise ValueError("Link arguments do not contain a tool")

    def _is_redirect(arg: str) -> bool:
        # dyld paths are linker values, not response files.
        return arg.startswith("@") and not any(
            arg == prefix or arg.startswith(prefix + "/")
            for prefix in ("@rpath", "@loader_path", "@executable_path")
        )

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
    if _is_redirect(raw_args[0]):
        raw_args = _expand_redirect(raw_args[0]) + raw_args[1:]

    tool = raw_args[0]
    if not tool or tool.startswith("-") or tool.startswith("@"):
        raise ValueError("Link arguments do not contain a tool")

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


def _process_linkopts(
        linkopts: List[str],
        is_framework: bool,
        generated_product_paths: List[str]
    ) -> List[str]:
    # Decode Bazel shell quoting before matching complete library bindings.
    linkopts = [
        shlex.split(opt)[0] if opt.startswith("'") and opt.endswith("'") else opt
        for opt in linkopts
    ]
    linkopts = _remove_generated_inputs(linkopts, set(generated_product_paths))

    def _process_filelist(filelist_path: str) -> List[str]:
        with open(filelist_path, encoding = "utf-8") as fp:
            paths = fp.read().splitlines()

        return [
            _quote_if_needed(path)
            for path in paths
            if not path in generated_product_paths and not path.endswith(".o")
        ]

    processed_linkopts = []
    def _quote_and_append_processed_linkopt(opt):
        processed_linkopts.append(_quote_if_needed(opt))

    last_opt = None
    def _process_linkopt(opt):
        if opt == "-filelist":
            return
        if last_opt == "-filelist":
            # Not calling `_quote_and_append_processed_linkopt`, because
            # `_process_filelist` applies quoting if needed
            processed_linkopts.extend(_process_filelist(opt))
            return

        # Xcode sets entitlements
        if opt.startswith("-Wl,-sectcreate,__TEXT,__entitlements,"):
            return

        # Xcode sets Info.plist
        if opt.startswith("-Wl,-sectcreate,__TEXT,__info_plist,"):
            return

        # Xcode adds object files
        if opt.endswith(".o"):
            return

        # We don't want the BwB swizzle fix for BwX mode
        if opt.endswith("/libswizzle_absolute_xcttestsourcelocation.a"):
            if last_opt == "-force_load":
                processed_linkopts.pop()
            return

        # These flags are for wrapped_clang only
        if (opt.startswith("DSYM_HINT_DSYM_PATH=") or
            opt.startswith("DSYM_HINT_LINKED_BINARY=")):
            return

        # Use Xcode set `DEVELOPER_DIR`
        opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

        # Use Xcode set `SDKROOT`
        opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

        _quote_and_append_processed_linkopt(opt)

    skip_next = 0
    for linkopt in linkopts:
        if skip_next:
            skip_next -= 1
            continue

        skip_next = _LD_SKIP_OPTS.get(linkopt, 0)
        if skip_next:
            skip_next -= 1
            continue

        _process_linkopt(linkopt)
        last_opt = linkopt

    return processed_linkopts


def _main(
        output_path: str,
        generated_product_paths_file: str,
        is_framework: bool,
        args_files: List[str]
    ) -> None:
    with open(generated_product_paths_file, encoding = "utf-8") as fp:
        generated_product_paths = json.load(fp)

    linkopts = _process_linkopts(
        linkopts = _parse_args(args_files),
        is_framework = is_framework,
        generated_product_paths = generated_product_paths,
    )

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(linkopts)
        fp.write(f'{result}\n')


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print(
            f"""
Usage: {sys.argv[0]} <output> <self_linked_outputs_file> <is_framework> \
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
    )

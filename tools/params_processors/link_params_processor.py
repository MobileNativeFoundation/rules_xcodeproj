#!/usr/bin/python3

import json
import sys
from typing import List


# linker flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_LD_SKIP_OPTS = {
    # Xcode sets the output path
    "-o": 2,

    # Xcode sets these, and no way to unset it
    "-bundle": 2,
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


def _parse_args(args_files: List[str]) -> List[str]:
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
        if any(redirected_arg.startswith("@")
               for redirected_arg in redirected_args):
            raise ValueError("Nested link argument redirects are unsupported")
        return redirected_args

    # Some actions put their complete tool-plus-arguments list behind one
    # redirect. Expand that first-level redirect before dropping the tool.
    if raw_args[0].startswith("@"):
        raw_args = _expand_redirect(raw_args[0]) + raw_args[1:]

    tool = raw_args[0]
    if not tool or tool.startswith("-") or tool.startswith("@"):
        raise ValueError("Link arguments do not contain a tool")

    # The first argument across all chunks is the tool name. Later chunks start
    # with real arguments and must not lose their first value.
    args = []
    for arg in raw_args[1:]:
        if arg.startswith("@"):
            args.extend(_expand_redirect(arg))
        else:
            args.append(arg)

    return args

def _quote_if_needed(opt: str) -> str:
    if " " in opt or ("$(" in opt and ")" in opt):
        return f"'{opt}'"
    return opt


def _process_linkopts(
        linkopts: List[str],
        is_framework: bool,
        generated_product_paths: List[str]
    ) -> List[str]:
    def _process_filelist(filelist_path: str) -> List[str]:
        with open(filelist_path, encoding = "utf-8") as fp:
            paths = fp.read().splitlines()

        return [
            _quote_if_needed(path)
            for path in paths
            if not path in generated_product_paths and not path.endswith(".o")
        ]

    for index, linkopt in enumerate(linkopts):
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

        opt_generated_path_matches = [
            path
            for path in generated_product_paths
            if opt.endswith(path)
        ]
        if opt_generated_path_matches:
            if last_opt == "-force_load":
                processed_linkopts.pop()
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
            opt.startswith("DSYM_HINT_LINKED_BINARY=") or
            opt.startswith("LINKED_BINARY=")):
            return

        # Use Xcode set `DEVELOPER_DIR`
        opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

        # Use Xcode set `SDKROOT`
        opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

        _quote_and_append_processed_linkopt(opt)

    skip_next = 0
    for index, linkopt in enumerate(linkopts):
        if skip_next:
            skip_next -= 1
            continue

        # Xcode provides its own LTO object path. Remove the complete Bazel
        # driver group so the leading `-Xlinker` can't become orphaned and
        # consume the next option as the value of `-object_path_lto`.
        if (linkopt == "-Xlinker" and
            index + 1 < len(linkopts) and
            linkopts[index + 1] == "-object_path_lto"):
            skip_next = 3
            continue

        # Change "link.params" from `shell` to `multiline` format
        # https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
        if linkopt.startswith("'") and linkopt.endswith("'"):
            linkopt = linkopt[1:-1]

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

#!/usr/bin/python3

import json
import os
import sys
from typing import Dict, List


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
    "OSO_PREFIX_MAP_PWD": 1,
}


def _parse_args(args: List[str]) -> List[str]:
    expanded_args = []
    # Drop first argument since it's the linker executable
    for line in args[1:]:
        if line.startswith("@"):
            # Sometimes arguments might be a params file
            with open(line[1:], encoding = "utf-8") as f:
                expanded_args.extend(f.read().splitlines())
        else:
            expanded_args.append(line)

    return expanded_args


def _quote_if_needed(opt: str) -> str:
    if " " in opt or ("$(" in opt and ")" in opt):
        return f"'{opt}'"
    return opt


def _process_linkopts(
        linkopts: List[str],
        xcode_generated_paths: Dict[str, str],
        generated_framework_search_paths: Dict[str, Dict[str, str]],
        is_framework: bool,
        generated_product_paths: List[str],
        swift_triple: str
    ) -> List[str]:
    def _process_filelist(filelist_path: str) -> List[str]:
        with open(filelist_path, encoding = "utf-8") as fp:
            paths = fp.read().splitlines()

        return [
            _quote_if_needed(xcode_generated_paths.get(path, path))
            for path in paths
            if not path in generated_product_paths and not path.endswith(".o")
        ]

    def _process_linkopt_value(value: str):
        xcode_path = xcode_generated_paths.get(value)
        if not xcode_path:
            return value
        if os.path.splitext(xcode_path)[1] != ".swiftmodule":
            return xcode_path
        return "{}/{}.swiftmodule".format(xcode_path, swift_triple)

    def _process_linkopt_component(component):
        prefix, sep, suffix = component.partition("=")
        if not sep:
            return _process_linkopt_value(component)
        return "{}={}".format(prefix, _process_linkopt_value(suffix))

    processed_linkopts = []
    def _quote_and_append_processed_linkopt(opt):
        processed_linkopts.append(_quote_if_needed(opt))

    swiftui_previews_linkopts = []
    def _quote_and_append_swiftui_previews_linkopt(opt):
        swiftui_previews_linkopts.append(_quote_if_needed(opt))

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

        if opt == "-Wl,-rpath,@loader_path/SwiftUIPreviewsFrameworks":
            if is_framework:
                # Not calling `_quote_and_append_processed_linkopt`, because
                # every element of `swiftui_previews_linkopts` is already quoted
                # if needed
                processed_linkopts.extend(swiftui_previews_linkopts)
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

        if opt.startswith("-F"):
            path = opt[2:]
            search_paths = generated_framework_search_paths.get(path)
            if search_paths:
                xcode_path = search_paths.get("x")
                if xcode_path:
                    _quote_and_append_processed_linkopt("-F" + xcode_path)
                    _quote_and_append_swiftui_previews_linkopt(
                        "-Wl,-rpath," + xcode_path,
                    )
                bazel_path = search_paths.get("b")
                if bazel_path:
                    _quote_and_append_processed_linkopt("-F" + bazel_path)
                    if bazel_path.startswith("/"):
                        _quote_and_append_swiftui_previews_linkopt(
                            "-Wl,-rpath," + bazel_path,
                        )
                    else:
                        # Not calling
                        # `_quote_and_append_swiftui_previews_linkopt`, because
                        # we already know it needs to be quoted, and we do so
                        # manually here
                        swiftui_previews_linkopts.append(
                            f"'-Wl,-rpath,$(PROJECT_DIR)/{bazel_path}'",
                        )
            else:
                _quote_and_append_processed_linkopt(opt)
                prefix = path[0]
                if prefix != "/" and prefix != "$":
                    swiftui_previews_linkopts.append(
                        f"'-Wl,-rpath,$(PROJECT_DIR)/{path}'",
                    )
            return

        _quote_and_append_processed_linkopt(",".join([
            _process_linkopt_component(component)
            for component in opt.split(",")
        ]))

    skip_next = 0
    for linkopt in linkopts:
        if skip_next:
            skip_next -= 1
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
        xcode_generated_paths_path: str,
        generated_framework_search_paths_path: str,
        is_framework: bool,
        generated_product_paths_file: str,
        swift_triple: str,
        output_path: str,
        args: List[str]
    ) -> None:
    with open(xcode_generated_paths_path, encoding = "utf-8") as fp:
        xcode_generated_paths = json.load(fp)

    with open(generated_framework_search_paths_path, encoding = "utf-8") as fp:
        generated_framework_search_paths = json.load(fp)

    with open(generated_product_paths_file, encoding = "utf-8") as fp:
        generated_product_paths = json.load(fp)

    linkopts = _process_linkopts(
        linkopts = _parse_args(args),
        xcode_generated_paths = xcode_generated_paths,
        generated_framework_search_paths = generated_framework_search_paths,
        is_framework = is_framework,
        generated_product_paths = generated_product_paths,
        swift_triple = swift_triple
    )

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(linkopts)
        fp.write(f'{result}\n')


if __name__ == "__main__":
    if len(sys.argv) < 8:
        print(
            f"""
Usage: {sys.argv[0]} <xcode_generated_paths.json> \
<generated_framework_search_paths.json> <is_framework> <self_linked_output> \
<swift_triple> <output> <args>\
""",
            file = sys.stderr,
        )
        exit(1)

    _main(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3] == "1",
        sys.argv[4],
        sys.argv[5],
        sys.argv[6],
        sys.argv[7:],
    )

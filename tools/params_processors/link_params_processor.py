#/usr/bin/python3

import json
import os
import sys
from typing import Dict, List


def _main(
        xcode_generated_paths_path: str,
        self_linked_path: str,
        swift_triple: str,
        output_path: str,
        args: List[str]
    ) -> None:
    with open(xcode_generated_paths_path, encoding = "utf-8") as fp:
        xcode_generated_paths = json.load(fp)

    linkopts = _process_linkopts(
        # First argument is the tool name
        linkopts = _parse_args(args)[1:],
        xcode_generated_paths = xcode_generated_paths,
        self_linked_path = self_linked_path,
        swift_triple = swift_triple
    )

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(linkopts)
        fp.write(f'{result}\n')


def _parse_args(args: List[str]) -> List[str]:
    if args[0].startswith("@"):
        with open(args[0][1:], encoding = "utf-8") as fp:
            return fp.read().splitlines()
    return args


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

    # We let Xcode set this currently, until we pass through compiler flags
    "-fapplication-extension": 1,

    # This is wrapped_clang specific, and we don't want to translate it for BwX
    "OSO_PREFIX_MAP_PWD": 1,
}


def _process_linkopts(
        linkopts: List[str],
        xcode_generated_paths: Dict[str, str],
        self_linked_path: str,
        swift_triple: str
    ) -> List[str]:
    def _process_filelist(filelist_path: str) -> List[str]:
        with open(filelist_path, encoding = "utf-8") as fp:
            paths = fp.read().splitlines()

        return [
            xcode_generated_paths.get(path, path)
            for path in paths
            if path != self_linked_path and not path.endswith(".o")
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
    last_opt = None
    def _process_linkopt(opt):
        if opt == "-filelist":
            return None
        if last_opt == "-filelist":
            processed_linkopts.extend(_process_filelist(opt))
            return None
        if self_linked_path and opt.endswith(self_linked_path):
            if last_opt == "-force_load":
                processed_linkopts.pop()
            return None

        # Xcode sets entitlements
        if opt.startswith("-Wl,-sectcreate,__TEXT,__entitlements,"):
            return None

        # Xcode sets Info.plist
        if opt.startswith("-Wl,-sectcreate,__TEXT,__info_plist,"):
            return None

        # Xcode adds object files
        if opt.endswith(".o"):
            return None

        # Xcode adds system library search paths
        if opt.startswith("-L__BAZEL_XCODE_"):
            return None

        # TODO: Remove these filter once we move path logic out of the generator
        if opt.startswith("-F"):
            return None

        # Use Xcode set `DEVELOPER_DIR`
        opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

        # Use Xcode set `SDKROOT`
        opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

        return ",".join([
            _process_linkopt_component(component)
            for component in opt.split(",")
        ])

    skip_next = 0
    for linkopt in linkopts:
        if skip_next:
            skip_next -= 1
            continue
        skip_next = _LD_SKIP_OPTS.get(linkopt, 0)
        if skip_next:
            skip_next -= 1
            continue

        new_linkopt = _process_linkopt(linkopt)
        last_opt = linkopt
        if new_linkopt:
            processed_linkopts.append(new_linkopt)

    return processed_linkopts


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print(
            f"""
Usage: {sys.argv[0]} <xcode_generated_paths.json> <self_linked_output> \
<swift_triple> <output> <args...>\
""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:])

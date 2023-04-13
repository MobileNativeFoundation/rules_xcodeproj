#/usr/bin/python3

import json
import os
import sys
from typing import Dict


def _build_setting_path(path):
    if path.startswith("bazel-out/"):
        return f'$(BAZEL_OUT)/{path[10:]}'
    if path.startswith("external/"):
        return f'$(BAZEL_EXTERNAL)/{path[9:]}'
    return path


def _handle_swiftmodule_path(
        path: str,
        xcode_generated_paths: Dict[str, str]
    ) -> str:
    bs_path = xcode_generated_paths.get(path)
    if not bs_path:
        bs_path = _build_setting_path(path)
    return os.path.dirname(bs_path)


_ONCE_FLAGS = {
    "-D": None,
    "-F": None,
    "-I": None,
}


def _main(
        xcode_generated_paths_path: str,
        framework_paths_path: str,
        swiftmodule_paths_path: str,
        clang_opts_path: str,
        output_path: str
    ) -> None:
    with open(xcode_generated_paths_path, encoding = "utf-8") as fp:
        xcode_generated_paths = json.load(fp)

    with open(framework_paths_path, encoding = "utf-8") as fp:
        framework_paths = fp.read().splitlines()

    with open(swiftmodule_paths_path, encoding = "utf-8") as fp:
        swiftmodule_paths = {
            _handle_swiftmodule_path(path, xcode_generated_paths): None
            for path in fp.read().splitlines()
        }

    with open(clang_opts_path, encoding = "utf-8") as fp:
        once_flags = {}
        clang_opts = []
        for opt in fp.read().splitlines():
            if opt in once_flags:
                continue
            if ((opt[0:2] in _ONCE_FLAGS) or
                opt.startswith("-fmodule-map-file=")):
                # This can lead to correctness issues if the value of a define
                # is specified multiple times, and different on different
                # targets, but it's how lldb currently handles it. Ideally it
                # should use a dictionary for the key of the define and only
                # filter ones that have the same value as the last time the key
                # was used.
                once_flags[opt] = None
            clang_opts.append(opt)

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        dto = {}

        if clang_opts:
            dto["c"] = " ".join(clang_opts)
        if framework_paths:
            dto["f"] = framework_paths
        if swiftmodule_paths:
            dto["s"] = list(swiftmodule_paths.keys())

        json.dump(dto, fp, indent = 2, sort_keys = True)


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print(
            f"""
Usage: {sys.argv[0]} <xcode_generated_paths.json> <framework_paths_file> \
<clang_opts_file> <output>
""",
            file = sys.stderr,
        )
        exit(1)

    _main(
        # xcode_generated_paths_path
        sys.argv[1],
        # framework_paths_path
        sys.argv[2],
        # swiftmodule_paths_path
        sys.argv[3],
        # clang_opts_path
        sys.argv[4],
        # output_path
        sys.argv[5],
    )

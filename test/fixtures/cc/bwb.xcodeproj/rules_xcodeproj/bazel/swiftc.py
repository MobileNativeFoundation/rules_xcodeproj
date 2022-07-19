#!/usr/bin/python3

import json
import os
import re
import subprocess
import sys
from typing import List

DEVELOPER_DIR_PATTERN = r'(.*?/Contents/Developer)/.*'

def _main() -> None:
    args = sys.argv

    if args[1:] == ["-v"]:
        os.system("swiftc -v")
        return

    # Pass through for SwiftUI Preview thunk compilation
    if (any(arg.endswith(".preview-thunk.swift") for arg in args) and
        "-output-file-map" not in args):
        flag = args.index("-sdk")
        sdk_path = args[flag + 1]
        match = re.fullmatch(DEVELOPER_DIR_PATTERN, sdk_path)
        if not match:
            raise RuntimeError("Failed to parse DEVELOPER_DIR from -sdk")

        # TODO: Make this work with custom toolchains
        # We could produce this file at the start of the build?
        developer_dir = match.group(1)
        swiftc = f"{developer_dir}/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"

        exit(subprocess.run([swiftc] + args[1:], check=False).returncode)

    _touch_deps_files(args)
    _touch_swiftmodule_artifacts(args)


def _touch_deps_files(args: List[str]) -> None:
    "Touch the Xcode-required .d files"
    flag = args.index("-output-file-map")
    output_file_map_path = args[flag + 1]

    with open(output_file_map_path) as f:
        output_file_map = json.load(f)

    d_files = [
        entry["dependencies"]
        for entry in output_file_map.values()
        if "dependencies" in entry
    ]

    for d_file in d_files:
        _touch(d_file)


def _touch_swiftmodule_artifacts(args: List[str]) -> None:
    "Touch the Xcode-required .swift{module,doc,sourceinfo} files"
    flag = args.index("-emit-module-path")
    swiftmodule_path = args[flag + 1]
    swiftdoc_path = _replace_ext(swiftmodule_path, "swiftdoc")
    swiftsourceinfo_path = _replace_ext(swiftmodule_path, "swiftsourceinfo")
    swiftinterface_path = _replace_ext(swiftmodule_path, "swiftinterface")

    _touch(swiftmodule_path)
    _touch(swiftdoc_path)
    _touch(swiftsourceinfo_path)
    _touch(swiftinterface_path)

    try:
        flag = args.index("-emit-objc-header-path")
        generated_header_path = args[flag + 1]
        _touch(generated_header_path)
    except ValueError:
        pass


def _touch(path: str) -> None:
    # Don't open with "w" mode, that truncates the file if it exists.
    open(path, "a")


def _replace_ext(path: str, extension: str) -> str:
    name, _ = os.path.splitext(path)
    return ".".join((name, extension))


if __name__ == "__main__":
    _main()

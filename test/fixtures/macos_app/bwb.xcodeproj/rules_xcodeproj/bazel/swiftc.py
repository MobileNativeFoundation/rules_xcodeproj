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
        developer_dir = match.group(1)
        swiftc = f"{developer_dir}/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"

        exit(subprocess.run([swiftc] + args[1:], check=False).returncode)

    _touch_deps_files(args)


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


def _touch(path: str) -> None:
    # Don't open with "w" mode, that truncates the file if it exists.
    open(path, "a")


if __name__ == "__main__":
    _main()

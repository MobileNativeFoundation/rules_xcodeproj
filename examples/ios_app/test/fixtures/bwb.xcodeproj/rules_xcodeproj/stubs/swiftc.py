#!/usr/bin/python3

import json
import os
import sys
from typing import List

def _main() -> None:
    if sys.argv[1:] == ["-v"]:
        os.system("swiftc -v")
        return

    _touch_deps_files(sys.argv)


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

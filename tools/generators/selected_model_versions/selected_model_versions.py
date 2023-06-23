#!/usr/bin/python3

import os
import plistlib
import sys


def _main(output_path: str, xcurrentversions_file_list: str) -> None:
    with open(xcurrentversions_file_list, encoding = "utf-8") as fp:
        paths = fp.read().splitlines()

    results = []
    for path in paths:
        with open(path, 'rb') as fp:
            plist = plistlib.load(fp)

        version = plist.get("_XCCurrentVersionName")
        if not version:
            print(
                f"WARNING: `_XCCurrentVersionName` key not found in {path}",
                file = sys.stderr,
            )
            continue

        container = os.path.dirname(path)

        results.append(f'"{container}"')
        results.append(f'"{version}"')

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        fp.write(f'[{",".join(results)}]\n')


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            f"""\
Usage: {sys.argv[0]} <output_file> <path/to/xcurrentversions_file_list>
""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2])

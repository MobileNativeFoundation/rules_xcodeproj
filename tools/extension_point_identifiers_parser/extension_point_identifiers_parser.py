#!/usr/bin/python3

import plistlib
import sys

_EXTENSION_POINT_IDENTIFIER_KEYS = [
    ("NSExtension", "NSExtensionPointIdentifier"),
    ("EXAppExtensionAttributes", "EXExtensionPointIdentifier")
]

def _main(
        output_path: str,
        targetids_path: str,
        infoplist_file_list: str) -> None:
    with open(targetids_path, encoding = "utf-8") as fp:
        targetids = fp.read().splitlines()
    with open(infoplist_file_list, encoding = "utf-8") as fp:
        paths = fp.read().splitlines()

    if len(targetids) != len(paths):
        print(
            """\
ERROR: number of target IDs doesn't match the number of Info.plist files""",
            file = sys.stderr,
        )
        sys.exit(1)

    results = []
    for targetid, path in zip(targetids, paths):
        with open(path, 'rb') as fp:
            plist = plistlib.load(fp)

        extension_point_identifier = None
        for extensionTypeKey, extensionPointIdentiferKey in _EXTENSION_POINT_IDENTIFIER_KEYS:
            extension_point_identifier = (
                plist.get(extensionTypeKey, {}).get(extensionPointIdentiferKey)
            )
            if extension_point_identifier:
                break

        if not extension_point_identifier:
            continue

        results.append(f'"{targetid}"')
        results.append(f'"{extension_point_identifier}"')

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        fp.write(f'[{",".join(results)}]\n')


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(
            f"""\
Usage: {sys.argv[0]} <output_file> <path/to/targetids> \
<path/to/infoplist_file_list>
""",
            file = sys.stderr,
        )
        sys.exit(1)

    _main(sys.argv[1], sys.argv[2], sys.argv[3])

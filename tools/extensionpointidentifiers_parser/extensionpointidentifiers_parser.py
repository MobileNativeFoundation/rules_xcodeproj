#!/usr/bin/python3

from collections import OrderedDict
import plistlib
import sys

def _main(
        targetids_path: str,
        infoplist_file_list: str,
        output_path) -> None:
    with open(targetids_path, encoding = "utf-8") as fp:
        targetids = fp.read().splitlines()
    with open(infoplist_file_list, encoding = "utf-8") as fp:
        paths = fp.read().splitlines()

    if len(targetids) != len(paths):
        print(
            """\
ERROR: number of target ids doesn't match the number of Info.plist files""",
            file = sys.stderr,
        )
        sys.exit(1)

    results = OrderedDict()
    for targetid, path in zip(targetids, paths):
        with open(path, 'rb') as fp:
            plist = plistlib.load(fp)

        extension_point_identifier = (
            plist.get("NSExtension", {}).get("NSExtensionPointIdentifier")
        )
        if not extension_point_identifier:
            continue

        results[targetid] = extension_point_identifier

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        results_json = [
            f'"{targetid}","{extension_point_identifier}"'
            for targetid, extension_point_identifier in results.items()
        ]
        fp.write(f'[{",".join(results_json)}]\n')


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(
            f"""\
Usage: {sys.argv[0]} <path/to/targetids> <path/to/infoplist_file_list> \
<output_file>
""",
            file = sys.stderr,
        )
        sys.exit(1)

    _main(sys.argv[1], sys.argv[2], sys.argv[3])

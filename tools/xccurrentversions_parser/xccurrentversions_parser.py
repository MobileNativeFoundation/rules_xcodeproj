#/usr/bin/python3

import plistlib
import sys

def _main(
        containers_path: str,
        xcurrentversions_file_list: str,
        output_path) -> None:
    with open(containers_path, encoding = "utf-8") as fp:
        file_paths = fp.read().splitlines()
    with open(xcurrentversions_file_list, encoding = "utf-8") as fp:
        paths = fp.read().splitlines()

    if len(file_paths) != len(paths):
        print(
            """\
ERROR: number of container file paths doesn't match the number of \
xccurrentversion files""",
            file = sys.stderr,
        )
        exit(1)

    results = []
    for file_path, path in zip(file_paths, paths):
        with open(path, 'rb') as fp:
            plist = plistlib.load(fp)

        version = plist.get("_XCCurrentVersionName")
        if not version:
            print(
                f"WARNING: `_XCCurrentVersionName` key not found in {path}",
                file = sys.stderr,
            )
            continue

        results.append(f'{{"c":{file_path},"v":"{version}"}}')

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        fp.write(f'[{",".join(results)}]\n')


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(
            f"""\
Usage: {sys.argv[0]} <path/to/container_file_paths> \
<path/to/xcurrentversions_file_list> <output_file>
""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2], sys.argv[3])

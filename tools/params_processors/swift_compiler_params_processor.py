#!/usr/bin/python3

import sys
from typing import Iterator, List, Optional


# Swift compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_SWIFTC_SKIP_OPTS = {
    # Xcode sets output paths
    "-emit-module-path": 2,
    "-emit-object": 1,
    "-output-file-map": 2,

    # Xcode sets these, and no way to unset them
    "-enable-bare-slash-regex": 1,
    "-module-name": 2,
    "-num-threads": 2,
    "-parse-as-library": 1,
    "-sdk": 2,
    "-target": 2,

    # We want to use Xcode's normal PCM handling
    "-module-cache-path": 2,

    # We want Xcode's normal debug handling
    "-debug-prefix-map": 2,
    "-file-prefix-map": 2,
    "-gline-tables-only": 1,

    # We want to use Xcode's normal indexing handling
    "-index-ignore-system-modules": 1,
    "-index-store-path": 2,

    # We set Xcode build settings to control these
    "-enable-batch-mode": 1,

    # We don't want to translate this for BwX
    "-emit-symbol-graph-dir": 2,

    # These are handled in `opts.bzl`
    "-emit-objc-header-path": 2,
    "-explicit-swift-module-map-file": 2,
    "-g": 1,
    "-incremental": 1,
    "-no-whole-module-optimization": 1,
    "-swift-version": 2,
    "-vfsoverlay": 2,
    "-whole-module-optimization": 1,
    "-wmo": 1,
    "-Xcc": 2,

    # We filter out `-Xfrontend`, then add it back only if the current opt
    # wasn't filtered out
    "-Xfrontend": 1,

    # This is rules_swift specific, and we don't want to translate it for BwX
    "-Xwrapped-swift": 1,
}

_SWIFTC_SKIP_COMPOUND_OPTS = {
    "-Xfrontend": {
        # We want Xcode to control coloring
        "-color-diagnostics": 1,

        # We want Xcode's normal debug handling
        "-no-clang-module-breadcrumbs": 1,
        "-no-serialize-debugging-options": 1,
        "-serialize-debugging-options": 1,

        # We don't want to translate this for BwX
        "-emit-symbol-graph": 1,

        # Handled in `opts.bzl` (skip 3 because of the extra `-Xfrontend` flag)
        "-explicit-swift-module-map-file": 3,
        "-load-plugin-executable": 3,
        "-load-plugin-library": 3,
        "-vfsoverlay": 3,
    },
}


def _inner_process_swiftcopts(*, opt: str, previous_opt: str) -> Optional[str]:
    if (previous_opt == "-I" or opt.startswith("-I") or
        previous_opt == "-F" or opt.startswith("-F")):
        # BwX Swift include paths are set in `xcode_targets.bzl`
        # `_set_swift_include_paths`, and BwB include paths are set in
        # `opts.bzl`
        return None

    if opt.startswith("-vfsoverlay"):
        # Handled in opts.bzl
        return None

    if opt[0] != "-" and opt.endswith(".swift"):
        # These are the files to compile, not options. They are seen here
        # because of the way we collect Swift compiler options. Ideally in
        # the future we could collect Swift compiler options similar to how
        # we collect C and C++ compiler options.
        return None

    return opt


def process_args(params_paths: List[str], parse_args) -> List[str]:
    # First two lines are "swift_worker" and "swiftc"
    skip_next = 2

    processed_opts = []
    next_previous_opt = None
    for params_path in params_paths:
        opts_iter = parse_args(params_path)

        next_opt = None
        while True:
            if next_opt:
                opt = next_opt
                next_opt = None
            else:
                opt = next(opts_iter, None)
                if opt == None:
                    break

                # Remove trailing newline
                opt = opt[:-1]

            previous_opt = next_previous_opt
            next_previous_opt = opt

            if skip_next:
                skip_next -= 1
                continue

            # Change "compile.params" from `shell` to `multiline` format
            # https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
            if opt.startswith("'") and opt.endswith("'"):
                opt = opt[1:-1]

            root_opt = opt.split("=")[0]

            compound_skip_next = _SWIFTC_SKIP_COMPOUND_OPTS.get(root_opt)
            if compound_skip_next:
                next_opt = next(opts_iter, None)
                if next_opt:
                    # Remove trailing newline
                    next_opt = next_opt[:-1]
                    skip_next = compound_skip_next.get(next_opt, 0)
                    if skip_next:
                        # No need to decrement 1, since we need to skip the
                        # first opt
                        continue

            skip_next = _SWIFTC_SKIP_OPTS.get(root_opt, 0)
            if skip_next:
                skip_next -= 1
                continue

            is_frontend_opt = previous_opt == "-Xfrontend"

            if is_frontend_opt and opt.startswith("-vfsoverlay"):
                # Handled in opts.bzl
                continue

            processed_opt = _inner_process_swiftcopts(
                opt = opt,
                previous_opt = previous_opt,
            )

            if processed_opt and is_frontend_opt:
                # We filter out `-Xfrontend`, then add it back only if the
                # current opt wasn't filtered out
                processed_opts.append(previous_opt)

            opt = processed_opt
            if not opt:
                continue

            # Use Xcode set `DEVELOPER_DIR`
            opt = opt.replace(
                "__BAZEL_XCODE_DEVELOPER_DIR__",
                "$(DEVELOPER_DIR)",
            )

            # Use Xcode set `SDKROOT`
            opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

            # Quote the option if it contains spaces or build setting variables
            if " " in opt or ("$(" in opt and ")" in opt):
                opt = f"'{opt}'"

            processed_opts.append(opt)

    return processed_opts


def _parse_args(params_path: str) -> Iterator[str]:
    return open(params_path, encoding = "utf-8")


def _main(output_path: str, params_paths: List[str]) -> None:
    processed_opts = process_args(params_paths, _parse_args)

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(processed_opts)
        fp.write(f'{result}\n')


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            f"""
Usage: {sys.argv[0]} output_path [params_file, ...]""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2:])

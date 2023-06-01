#!/usr/bin/python3

import sys
from typing import Iterator, List, Optional


# C and C++ compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_CC_SKIP_OPTS = {
    # Xcode sets these, and no way to unset them
    "-isysroot": 2,
    "-mios-simulator-version-min": 1,
    "-miphoneos-version-min": 1,
    "-mmacosx-version-min": 1,
    "-mtvos-simulator-version-min": 1,
    "-mtvos-version-min": 1,
    "-mwatchos-simulator-version-min": 1,
    "-mwatchos-version-min": 1,
    "-target": 2,

    # Xcode sets input and output paths
    "-c": 2,
    "-o": 2,

    # Debug info is handled in `opts.bzl`
    "-g": 1,

    # We set this in the generator
    "-fobjc-arc": 1,
    "-fno-objc-arc": 1,

    # We want to use Xcode's dependency file handling
    "-MD": 1,
    "-MF": 2,

    # We want to use Xcode's normal indexing handling
    "-index-ignore-system-symbols": 1,
    "-index-store-path": 2,

    # We want Xcode to control coloring
    "-fcolor-diagnostics": 1,

    # This is wrapped_clang specific, and we don't want to translate it for BwX
    "DEBUG_PREFIX_MAP_PWD": 1,
}

_NEEDS_PROJECT_DIR = {
    "-ivfsoverlay": None,
    "--config": None,
}


def _inner_process_cc_opts(opt: str, previous_opt: Optional[str]) -> str:
    # Short-circuit opts that are too short for our checks
    if len(opt) < 2:
        return opt

    # -ivfsoverlay and --config doesn't apply `-working_directory=`, so we
    # need to prefix it ourselves
    if previous_opt in _NEEDS_PROJECT_DIR:
        if opt[0] != "/":
            return "$(PROJECT_DIR)/" + opt
        return opt
    if opt.startswith("-ivfsoverlay"):
        value = opt[12:]
        if not value.startswith("/"):
            return "-ivfsoverlay" + "$(PROJECT_DIR)/" + value
        return opt

    return opt


def process_args(params_paths: List[str], parse_args) -> List[str]:
    # First line is "wrapped_clang"
    skip_next = 1

    processed_opts = []
    previous_opt = None
    for params_path in params_paths:
        for opt in parse_args(params_path):
            # Remove trailing newline
            opt = opt[:-1]

            if skip_next:
                skip_next -= 1
                continue

            # Change "compile.params" from `shell` to `multiline` format
            # https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
            if opt.startswith("'") and opt.endswith("'"):
                opt = opt[1:-1]

            root_opt = opt.split("=")[0]

            skip_next = _CC_SKIP_OPTS.get(root_opt, 0)
            if skip_next:
                skip_next -= 1
                continue

            processed_opt = _inner_process_cc_opts(
                opt,
                previous_opt,
            )

            previous_opt = opt

            opt = processed_opt
            if not opt:
                continue

            # Use Xcode set `DEVELOPER_DIR`
            opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

            # Use Xcode set `SDKROOT`
            opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

            # Quote the option if it contains spaces, quotes, or build setting
            # variables
            if " " in opt or "\"" in opt or ("$(" in opt and ")" in opt):
                opt = f"'{opt}'"

            processed_opts.append(opt)

    return processed_opts


def _main(output_path: str, params_paths: List[str]) -> None:
    processed_opts = process_args(params_paths, _parse_args)

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(processed_opts)
        fp.write(f'{result}\n')


def _parse_args(params_path: str) -> Iterator[str]:
    return open(params_path, encoding = "utf-8")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            f"""
Usage: {sys.argv[0]} output_path [params_file, ...]""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2:])

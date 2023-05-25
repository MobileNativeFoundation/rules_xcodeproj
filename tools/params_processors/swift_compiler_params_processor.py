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
    "-g": 1,
    "-incremental": 1,
    "-no-whole-module-optimization": 1,
    "-whole-module-optimization": 1,
    "-wmo": 1,

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
    },
}

_CLANG_SEARCH_PATHS = {
    "-iquote": None,
    "-isystem": None,
    "-I": None,
}


def _is_relative_path(path: str) -> bool:
    return not path.startswith("/") and not path.startswith("__BAZEL_")


def _process_clang_opt(
        opt: str,
        previous_opt: str,
        previous_clang_opt: str,
        is_bwx: bool) -> Optional[str]:
    if opt == "-Xcc":
        return opt

    is_clang_opt = previous_opt == "-Xcc"

    if not (is_clang_opt or is_bwx):
        return None

    if opt.startswith("-fmodule-map-file="):
        path = opt[18:]
        is_relative = _is_relative_path(path)
        if is_bwx and (is_clang_opt or is_relative):
            if path == ".":
                bwx_opt = "-fmodule-map-file=$(PROJECT_DIR)"
            elif is_relative:
                bwx_opt = "-fmodule-map-file=$(PROJECT_DIR)/" + path
            else:
                bwx_opt = opt
            return bwx_opt
        return opt
    if opt.startswith("-iquote"):
        path = opt[7:]
        if not path:
            return opt
        is_relative = _is_relative_path(path)
        if is_bwx and (is_clang_opt or is_relative):
            if path == ".":
                bwx_opt = "-iquote$(PROJECT_DIR)"
            elif is_relative:
                bwx_opt = "-iquote$(PROJECT_DIR)/" + path
            else:
                bwx_opt = opt
            return bwx_opt
        return opt
    if opt.startswith("-I"):
        path = opt[2:]
        if not path:
            return opt
        is_relative = _is_relative_path(path)
        if is_bwx and (is_clang_opt or is_relative):
            if path == ".":
                bwx_opt = "-I$(PROJECT_DIR)"
            elif is_relative:
                bwx_opt = "-I$(PROJECT_DIR)/" + path
            else:
                bwx_opt = opt
            return bwx_opt
        return opt
    if opt.startswith("-isystem"):
        path = opt[8:]
        if not path:
            return opt
        is_relative = _is_relative_path(path)
        if is_bwx and (is_clang_opt or is_relative):
            if path == ".":
                bwx_opt = "-isystem$(PROJECT_DIR)"
            elif is_relative:
                bwx_opt = "-isystem$(PROJECT_DIR)/" + path
            else:
                bwx_opt = opt
            return bwx_opt
        return opt
    if is_bwx and (previous_opt in _CLANG_SEARCH_PATHS or
                   previous_clang_opt in _CLANG_SEARCH_PATHS):
        if opt == ".":
            bwx_opt = "$(PROJECT_DIR)"
        elif _is_relative_path(opt):
            bwx_opt = "$(PROJECT_DIR)/" + opt
        else:
            bwx_opt = opt
        return bwx_opt
    if is_clang_opt:
        # -vfsoverlay doesn't apply `-working_directory=`, so we need to
        # prefix it ourselves
        if previous_clang_opt == "-ivfsoverlay":
            if opt[0] != "/":
                opt = "$(CURRENT_EXECUTION_ROOT)/" + opt
        elif opt.startswith("-ivfsoverlay"):
            value = opt[12:]
            if not value.startswith("/"):
                opt = "-ivfsoverlay$(CURRENT_EXECUTION_ROOT)/" + value
        return opt

    return None


def _inner_process_swiftcopts(
        *,
        opt: str,
        previous_opt: str,
        previous_frontend_opt: str,
        previous_clang_opt: str,
        is_bwx: bool) -> Optional[str]:
    clang_opt = _process_clang_opt(
        opt = opt,
        previous_opt = previous_opt,
        previous_clang_opt = previous_clang_opt,
        is_bwx = is_bwx,
    )
    if clang_opt:
        return clang_opt

    if opt[0] != "-" and opt.endswith(".swift"):
        # These are the files to compile, not options. They are seen here
        # because of the way we collect Swift compiler options. Ideally in
        # the future we could collect Swift compiler options similar to how
        # we collect C and C++ compiler options.
        return None

    if opt == "-Xfrontend":
        # We return early to prevent issues with the checks below
        return opt

    # -vfsoverlay doesn't apply `-working_directory=`, so we need to
    # prefix it ourselves
    previous_vfsoverlay_opt = previous_frontend_opt or previous_opt
    if previous_vfsoverlay_opt == "-vfsoverlay":
        if opt[0] != "/":
            return "$(CURRENT_EXECUTION_ROOT)/" + opt
        return opt
    if opt.startswith("-vfsoverlay"):
        value = opt[11:]
        if value and value[0] != "/":
            return "-vfsoverlay$(CURRENT_EXECUTION_ROOT)/" + value
        return opt

    return opt


def process_args(
        params_paths: List[str],
        parse_args,
        build_mode: str) -> List[str]:
    is_bwx = build_mode == "xcode"

    # First line is "swiftc"
    skip_next = 1

    processed_opts = []
    previous_opt = None
    previous_frontend_opt = None
    previous_clang_opt = None
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

            if skip_next:
                skip_next -= 1
                continue

            # Change "compile.params" from `shell` to `multiline` format
            # https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
            if opt.startswith("'") and opt.endswith("'"):
                opt = opt[1:-1]

            root_opt = opt.split("=")[0]

            skip_next = _SWIFTC_SKIP_OPTS.get(root_opt, 0)
            if skip_next:
                skip_next -= 1
                continue

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

            processed_opt = _inner_process_swiftcopts(
                opt = opt,
                previous_opt = previous_opt,
                previous_frontend_opt = previous_frontend_opt,
                previous_clang_opt = previous_clang_opt,
                is_bwx = is_bwx,
            )

            if previous_opt == "-Xcc":
                previous_clang_opt = opt
                previous_frontend_opt = None
            elif opt != "-Xcc":
                previous_clang_opt = None
                if previous_opt == "-Xfrontend":
                    previous_frontend_opt = opt
                elif opt != "-Xfrontend":
                    previous_frontend_opt = None

            previous_opt = opt

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


def _main(output_path: str, build_mode: str, params_paths: List[str]) -> None:
    processed_opts = process_args(params_paths, _parse_args, build_mode)

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        result = "\n".join(processed_opts)
        fp.write(f'{result}\n')


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(
            f"""
Usage: {sys.argv[0]} output_path build_mode [params_file, ...]""",
            file = sys.stderr,
        )
        exit(1)

    _main(sys.argv[1], sys.argv[2], sys.argv[3:])

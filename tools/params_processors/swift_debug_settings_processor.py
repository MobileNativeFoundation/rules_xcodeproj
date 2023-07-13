#!/usr/bin/python3

import json
import os
import sys
from typing import Iterator, List, Optional


def _build_setting_path(path):
    if path.startswith("bazel-out/"):
        return f'$(BAZEL_OUT)/{path[10:]}'
    if path.startswith("external/"):
        return f'$(BAZEL_EXTERNAL)/{path[9:]}'
    return path

def _is_pre_processed_relative_path(path: str) -> bool:
    if path.startswith("/"):
        return False
    for prefix in _PRE_PROCESSED_REPLACEMENT_PREFIXES:
        if path.startswith(prefix):
            return False
    return True


def _is_post_processed_relative_path(path: str) -> bool:
    if path.startswith("/"):
        return False
    for prefix in _POST_PROCESSED_REPLACEMENT_PREFIXES:
        if path.startswith(prefix):
            return False
    return True


_PRE_PROCESSED_REPLACEMENT_PREFIXES = [
    "__BAZEL_XCODE_DEVELOPER_DIR__",
    "__BAZEL_XCODE_SDKROOT__",
]

_POST_PROCESSED_REPLACEMENT_PREFIXES = [
    "$(DEVELOPER_DIR)",
    "$(SDKROOT)",
]

_CLANG_PATH_PREFIXES = [
    "-F",
    "-fmodule-map-file=",
    "-iquote",
    "-isystem",
    "-I",
]

_CLANG_SEARCH_PATHS = {
    "-iquote": None,
    "-isystem": None,
    "-I": None,
}

_ONCE_FLAGS = {
    "-D": None,
    "-F": None,
    "-I": None,
}


def _process_clang_opt(
        *,
        opt: str,
        previous_clang_opt: Optional[str]) -> Optional[str]:
    if opt == "-Xcc":
        return None

    for path_prefix in _CLANG_PATH_PREFIXES:
        if opt.startswith(path_prefix):
            path = opt[len(path_prefix):]
            if not path:
                return opt
            if path == ".":
                return f"{path_prefix}$(PROJECT_DIR)"
            if _is_pre_processed_relative_path(path):
                return f"{path_prefix}$(PROJECT_DIR)/{path}"
            return opt

    if previous_clang_opt in _CLANG_SEARCH_PATHS:
        if opt == ".":
            return "$(PROJECT_DIR)"
        if _is_pre_processed_relative_path(opt):
            return "$(PROJECT_DIR)/" + opt
        return opt
    if previous_clang_opt == "-ivfsoverlay":
        # -vfsoverlay doesn't apply `-working_directory=`, so we need to
        # prefix it ourselves
        if opt[0] != "/":
            return "$(PROJECT_DIR)/" + opt
        return opt
    if opt.startswith("-ivfsoverlay"):
        # Remove `-ivfsoverlay` prefix
        value = opt[12:]
        if not value:
            return opt
        if not value.startswith("/"):
            return "-ivfsoverlay$(PROJECT_DIR)/" + value
        return opt

    return opt


def _process_swift_opt(
        *,
        opt: str,
        previous_opt: Optional[str],
        framework_includes: List[str],
        swift_includes: List[str]) -> Optional[str]:
    if opt.startswith("-I"):
        path = opt[2:]
        if not path:
            return opt
        if path == ".":
            path = "$(PROJECT_DIR)"
        elif _is_post_processed_relative_path(path):
            path = f"$(PROJECT_DIR)/{path}"
        swift_includes.append(path)
        return None
    if previous_opt == "-I":
        path = opt
        if path == ".":
            path = "$(PROJECT_DIR)"
        elif _is_post_processed_relative_path(path):
            path = f"$(PROJECT_DIR)/{path}"
        swift_includes.append(path)
        return None
    if opt.startswith("-F"):
        path = opt[2:]
        if not path:
            return opt
        if path == ".":
            path = "$(PROJECT_DIR)"
        elif _is_post_processed_relative_path(path):
            path = f"$(PROJECT_DIR)/{path}"
        framework_includes.append(path)
        return None
    if previous_opt == "-F":
        path = opt
        if path == ".":
            path = "$(PROJECT_DIR)"
        elif _is_post_processed_relative_path(path):
            path = f"$(PROJECT_DIR)/{path}"
        framework_includes.append(path)
        return None

    return None


def process_swift_params(params_paths: List[str], parse_args):
    clang_opts = []
    framework_includes = []
    swift_includes = []
    next_previous_opt = None
    previous_clang_opt = None
    for params_path in params_paths:
        for opt in parse_args(params_path):
            # Remove trailing newline
            opt = opt[:-1]

            # Change "compile.params" from `shell` to `multiline` format
            # https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
            if opt.startswith("'") and opt.endswith("'"):
                opt = opt[1:-1]

            previous_opt = next_previous_opt
            next_previous_opt = opt

            is_clang_opt = opt == "-Xcc" or previous_opt == "-Xcc"

            if is_clang_opt:
                processed_opt = _process_clang_opt(
                    opt = opt,
                    previous_clang_opt = previous_clang_opt,
                )

            if previous_opt == "-Xcc":
                previous_clang_opt = opt
            elif opt != "-Xcc":
                previous_clang_opt = None

            if is_clang_opt:
                opt = processed_opt

            if opt:
                # Use Xcode set `DEVELOPER_DIR`
                opt = opt.replace(
                    "__BAZEL_XCODE_DEVELOPER_DIR__",
                    "$(DEVELOPER_DIR)",
                )

                # Use Xcode set `SDKROOT`
                opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

            if is_clang_opt:
                if opt:
                    clang_opts.append(opt)
            else:
                _process_swift_opt(
                    opt = opt,
                    previous_opt = previous_opt,
                    framework_includes = framework_includes,
                    swift_includes = swift_includes,
                )

    return framework_includes, swift_includes, clang_opts


def _main(args: Iterator[str]) -> None:
    output_path = next(args)[:-1]
    xcode_generated_paths_path = next(args)[:-1]

    with open(xcode_generated_paths_path, encoding = "utf-8") as fp:
        xcode_generated_paths = json.load(fp)

    if xcode_generated_paths:
       def _handle_swiftmodule_path(path: str) -> str:
            bs_path = xcode_generated_paths.get(path)
            if not bs_path:
                bs_path = _build_setting_path(path)
            return os.path.dirname(bs_path)
    else:
        def _handle_swiftmodule_path(path: str) -> str:
            return os.path.dirname(_build_setting_path(path))

    contexts = {}
    while True:
        key = next(args, "\n")[:-1]
        if key == "":
            break

        swiftmodule_includes = {}
        while True:
            path = next(args)[:-1]
            if path == "":
                break
            # In BwX mode swiftmodule paths are passed since we might need to
            # remap them. We process them first, so that remapped paths are
            # searched first. Any missed paths, such as for testing frameworks
            # will be added to the end by the params processing.
            swiftmodule_includes[_handle_swiftmodule_path(path)] = None

        once_flags = {}
        clang_opts = []
        framework_includes = {}
        parse_cache = {}
        while True:
            swift_sub_params_list = []
            while True:
                swift_params = next(args)[:-1]
                if swift_params == "":
                    # Groups of swift params files are separated by a blank line
                    break
                swift_sub_params_list.append(swift_params)
            if not swift_sub_params_list:
                # If we didn't get any swift params files, we're done with
                # processing clang opts
                break

            parse_cache_key = " ".join(swift_sub_params_list)

            parse = parse_cache.get(parse_cache_key, None)
            if not parse:
                parse = process_swift_params(
                    params_paths = swift_sub_params_list,
                    parse_args = _parse_args,
                )
                parse_cache[parse_cache_key] = parse
            (
                raw_framework_includes,
                raw_swift_includes,
                raw_clang_opts,
            ) = parse

            for path in raw_framework_includes:
                framework_includes[path] = None
            for path in raw_swift_includes:
                swiftmodule_includes[path] = None

            for opt in raw_clang_opts:
                if opt in once_flags:
                    continue
                if ((opt[0:2] in _ONCE_FLAGS) or
                    opt.startswith("-fmodule-map-file=")):
                    # This can lead to correctness issues if the value of a
                    # define is specified multiple times, and different on
                    # different targets, but it's how lldb currently handles it.
                    # Ideally it should use a dictionary for the key of the
                    # define and only filter ones that have the same value as
                    # the last time the key was used.
                    once_flags[opt] = None
                # Escape spaces in paths, since these opts are whitespace
                # separated
                clang_opts.append(opt.replace(' ', '\\ '))

        dto = {}

        if clang_opts:
            dto["c"] = " ".join(clang_opts)
        if framework_includes:
            dto["f"] = list(framework_includes.keys())
        if swiftmodule_includes:
            dto["s"] = list(swiftmodule_includes.keys())

        if dto:
            contexts[key] = dto

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        settings_content = json.dumps(contexts, indent = '\t', sort_keys = True)
        result = f'''\
#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb
import re

# Order matters, it needs to be from the most nested to the least
_BUNDLE_EXTENSIONS = [
    ".framework",
    ".xctest",
    ".appex",
    ".bundle",
    ".app",
]

_TRIPLE_MATCH = re.compile(r"([^-]+-[^-]+)(-\D+)[^-]*(-.*)?")

_SETTINGS = {settings_content}

def __lldb_init_module(debugger, _internal_dict):
    # Register the stop hook when this module is loaded in lldb
    ci = debugger.GetCommandInterpreter()
    res = lldb.SBCommandReturnObject()
    ci.HandleCommand(
        "target stop-hook add -P swift_debug_settings.StopHook",
        res,
    )
    if not res.Succeeded():
        print(f"""\\
Failed to register Swift debug options stop hook:

{{res.GetError()}}
Please file a bug report here: \\
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""")
        return

def _get_relative_executable_path(module):
    for extension in _BUNDLE_EXTENSIONS:
        prefix, _, suffix = module.rpartition(extension)
        if prefix:
            return prefix.split("/")[-1] + extension + suffix
    return module.split("/")[-1]

class StopHook:
    "An lldb stop hook class, that sets swift settings for the current module."

    def __init__(self, _target, _extra_args, _internal_dict):
        pass

    def handle_stop(self, exe_ctx, _stream):
        "Method that is called when the user stops in lldb."
        module = exe_ctx.frame.module
        if not module:
            return

        module_name = module.file.__get_fullpath__()
        versionless_triple = _TRIPLE_MATCH.sub(r"\\1\\2\\3", module.GetTriple())
        executable_path = _get_relative_executable_path(module_name)
        key = f"{{versionless_triple}} {{executable_path}}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{{path}}"'
                for path in settings.get("f", [])
            ])
            if frameworks:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-framework-search-paths {{frameworks}}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-framework-search-paths",
                )

            includes = " ".join([
                f'"{{path}}"'
                for path in settings.get("s", [])
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {{includes}}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings.get("c")
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{{clang}}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True'''
        fp.write(f'{result}\n')


def _parse_args(params_path: str) -> Iterator[str]:
    return open(params_path, encoding = "utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            f"""
Usage: {sys.argv[0]} @params_file""",
            file = sys.stderr,
        )
        exit(1)

    _main(_parse_args(sys.argv[1][1:]))

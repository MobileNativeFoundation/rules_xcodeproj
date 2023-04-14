#!/usr/bin/python3

import json
import os
import sys
from typing import Dict, Iterator


def _build_setting_path(path):
    if path.startswith("bazel-out/"):
        return f'$(BAZEL_OUT)/{path[10:]}'
    if path.startswith("external/"):
        return f'$(BAZEL_EXTERNAL)/{path[9:]}'
    return path


def _handle_swiftmodule_path(
        path: str,
        xcode_generated_paths: Dict[str, str]
    ) -> str:
    bs_path = xcode_generated_paths.get(path)
    if not bs_path:
        bs_path = _build_setting_path(path)
    return os.path.dirname(bs_path)


_ONCE_FLAGS = {
    "-D": None,
    "-F": None,
    "-I": None,
}


def _main(args: Iterator[str]) -> None:
    output_path = next(args)[:-1]
    xcode_generated_paths_path = next(args)[:-1]

    with open(xcode_generated_paths_path, encoding = "utf-8") as fp:
        xcode_generated_paths = json.load(fp)

    contexts = {}
    while True:
        key = next(args, "\n")[:-1]
        if not key:
            break

        framework_paths = []
        while True:
            path = next(args)[:-1]
            if path == "":
                break
            framework_paths.append(path)

        swiftmodule_paths = {}
        while True:
            path = next(args)[:-1]
            if path == "":
                break
            swiftmodule_paths[
                _handle_swiftmodule_path(path, xcode_generated_paths)
            ] = None

        once_flags = {}
        clang_opts = []
        while True:
            opt = next(args)[:-1]
            if opt == "":
                break
            if opt in once_flags:
                continue
            if ((opt[0:2] in _ONCE_FLAGS) or
                opt.startswith("-fmodule-map-file=")):
                # This can lead to correctness issues if the value of a define
                # is specified multiple times, and different on different
                # targets, but it's how lldb currently handles it. Ideally it
                # should use a dictionary for the key of the define and only
                # filter ones that have the same value as the last time the key
                # was used.
                once_flags[opt] = None
            clang_opts.append(opt)

        dto = {}

        if clang_opts:
            dto["c"] = " ".join(clang_opts)
        if framework_paths:
            dto["f"] = framework_paths
        if swiftmodule_paths:
            dto["s"] = list(swiftmodule_paths.keys())

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

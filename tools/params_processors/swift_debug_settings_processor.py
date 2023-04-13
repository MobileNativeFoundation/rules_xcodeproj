#/usr/bin/python3

import sys
from typing import List


def _main(
        output_path: str,
        keys_and_paths: List[str],
    ) -> None:
    context_json_strs = {}
    for key, path in zip(keys_and_paths[::2], keys_and_paths[1::2]):
        with open(path, encoding = "utf-8") as fp:
            context_json_strs[key] = fp.read()

    settings_entries = [
        f'"{key}": {content},'
        for key, content in context_json_strs.items()
        if content != '{}'
    ]

    with open(output_path, encoding = "utf-8", mode = "w") as fp:
        if settings_entries:
            settings_content = "\n" + "\n".join(settings_entries) + "\n"
        else:
            settings_content = ""
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

_SETTINGS = {{{settings_content}}}

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


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            f"""
Usage: {sys.argv[0]} <output> [key, path, [key, path, ...]]
""",
            file = sys.stderr,
        )
        exit(1)

    _main(
        # output_path
        sys.argv[1],
        # keys_and_paths
        sys.argv[2:],
    )

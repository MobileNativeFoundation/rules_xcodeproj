import Foundation
import PBXProj

extension Generator {
    struct WriteSwiftDebugSettings {
        private let write: Write

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            write: Write,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.write = write

            self.callable = callable
        }

        /// Writes the Swift debug settings to disk.
        func callAsFunction(
            _ keyedSwiftDebugSettings:
                [(key: String, settings: TargetSwiftDebugSettings)],
            to url: URL
        ) throws {
            try callable(
                /*keyedSwiftDebugSettings:*/ keyedSwiftDebugSettings,
                /*url:*/ url,
                /*write:*/ write
            )
        }
    }
}

// MARK: - WriteSwiftDebugSettings.Callable

extension Generator.WriteSwiftDebugSettings {
    typealias Callable = (
        _ keyedSwiftDebugSettings:
            [(key: String, settings: TargetSwiftDebugSettings)],
        _ url: URL,
        _ write: Write
    ) throws -> Void

    static func defaultCallable(
        _ keyedSwiftDebugSettings:
            [(key: String, settings: TargetSwiftDebugSettings)],
        to url: URL,
        write: Write
    ) throws {
        let content = #"""
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

_SETTINGS = {
\#(keyedSwiftDebugSettings.map(settingsString).joined())\#
}

def __lldb_init_module(debugger, _internal_dict):
    # Register the stop hook when this module is loaded in lldb
    ci = debugger.GetCommandInterpreter()
    res = lldb.SBCommandReturnObject()
    ci.HandleCommand(
        "target stop-hook add -P swift_debug_settings.StopHook",
        res,
    )
    if not res.Succeeded():
        print(f"""\
Failed to register Swift debug options stop hook:

{res.GetError()}
Please file a bug report here: \
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

        module_name = module.file.GetDirectory() + "/" + module.file.GetFilename()
        versionless_triple = _TRIPLE_MATCH.sub(r"\1\2\3", module.GetTriple())
        executable_path = _get_relative_executable_path(module_name)
        key = f"{versionless_triple} {executable_path}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{path}"'
                for path in settings.get("f", [])
            ])
            if frameworks:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-framework-search-paths {frameworks}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-framework-search-paths",
                )

            includes = " ".join([
                f'"{path}"'
                for path in settings.get("s", [])
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {includes}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings.get("c")
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{clang}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True

"""#

        try write(content, to: url)
    }
}

private func settingsString(
    key: String,
    settings: TargetSwiftDebugSettings
) -> String {
    let frameworkIncludes: String
    if settings.frameworkIncludes.isEmpty {
        frameworkIncludes = ""
    } else {
        frameworkIncludes = #"""
        "f": [
\#(settings.frameworkIncludes.map { #"            "\#($0)",\#n"# }.joined())\#
        ],

"""#
    }

    let swiftIncludes: String
    if settings.swiftIncludes.isEmpty {
        swiftIncludes = ""
    } else {
        swiftIncludes = #"""
        "s": [
\#(settings.swiftIncludes.map { #"            "\#($0)",\#n"# }.joined())\#
        ],

"""#
    }

    return #"""
    "\#(key)": {
        "c": "\#(settings.clangArgs.joined(separator: " "))",
\#(frameworkIncludes)\#
\#(swiftIncludes)\#
    },

"""#
}

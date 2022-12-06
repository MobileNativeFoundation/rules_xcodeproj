#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb

# Order matters, it needs to be from the most nested to the least
_BUNDLE_EXTENSIONS = [
    ".framework",
    ".xctest",
    ".appex",
    ".bundle",
    ".app",
]

_SETTINGS = {
  "x86_64-apple-macosx12.0.0 generator" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -I \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include\" -I \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include\" -I \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include\" -I \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter/JJLISO8601DateFormatter.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily/ZippyJSONCFamily.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_apple_swift_collections",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjson",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_tuist_xcodeproj",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_tadija_aexml",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_kylef_pathkit"
    ]
  },
  "x86_64-apple-macosx12.0.0 swiftc" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [

    ]
  },
  "x86_64-apple-macosx12.0.0 tests.xctest/Contents/MacOS/tests" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -I \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include\" -I \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include\" -I \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include\" -I \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter/JJLISO8601DateFormatter.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily/ZippyJSONCFamily.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_jjliso8601dateformatter\" -iquote \"$(BAZEL_EXTERNAL)/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjsoncfamily\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/tools/generator",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_pointfreeco_swift_custom_dump",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_apple_swift_collections",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_michaeleisel_zippyjson",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_tuist_xcodeproj",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_tadija_aexml",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_kylef_pathkit",
      "$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-0c83c5e59889/bin/external/com_github_pointfreeco_xctest_dynamic_overlay"
    ]
  }
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
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
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
        target_triple = module.GetTriple()
        executable_path = _get_relative_executable_path(module_name)
        key = f"{target_triple} {executable_path}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{path}"'
                for path in settings["frameworks"]
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
                for path in settings["includes"]
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {includes}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings["clang"]
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{clang}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True

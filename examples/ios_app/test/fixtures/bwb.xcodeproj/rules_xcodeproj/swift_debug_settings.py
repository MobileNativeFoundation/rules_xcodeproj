#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb

_BUNDLE_EXTENSIONS = [
    ".app",
    ".appex",
    ".bundle",
    ".framework",
    ".xctest",
]

_SETTINGS = {
  "x86_64-apple-ios15.0.0-simulator Example.app/Example_ExecutableName" : {
    "clang" : "-iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -I \"CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Utils/Utils.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [

    ]
  },
  "x86_64-apple-ios15.0.0-simulator ExampleObjcTests.xctest/ExampleObjcTests" : {
    "clang" : "-iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -DAWESOME -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -I \"CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Utils/Utils.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [

    ]
  },
  "x86_64-apple-ios15.0.0-simulator ExampleTests.xctest/ExampleTests" : {
    "clang" : "-iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -I \"CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Utils/Utils.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/TestingUtils/TestingUtils.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -DAWESOME -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -DAWESOME -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -I \"CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Utils/Utils.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Example",
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/TestingUtils"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator ExampleUITests.xctest/ExampleUITests" : {
    "clang" : "-iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin\" -I \"CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-a0d0e3b8f217/bin/Utils/Utils.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [

    ]
  }
}

_FALLBACK_KEYS = {
  "x86_64-apple-ios-simulator Example.app/Example_ExecutableName" : "x86_64-apple-ios15.0.0-simulator Example.app/Example_ExecutableName",
  "x86_64-apple-ios-simulator ExampleObjcTests.xctest/ExampleObjcTests" : "x86_64-apple-ios15.0.0-simulator ExampleObjcTests.xctest/ExampleObjcTests",
  "x86_64-apple-ios-simulator ExampleTests.xctest/ExampleTests" : "x86_64-apple-ios15.0.0-simulator ExampleTests.xctest/ExampleTests",
  "x86_64-apple-ios-simulator ExampleUITests.xctest/ExampleUITests" : "x86_64-apple-ios15.0.0-simulator ExampleUITests.xctest/ExampleUITests"
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
    https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md.
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
        module_name = module.file.__get_fullpath__()
        target_triple = module.GetTriple()
        executable_path = _get_relative_executable_path(module_name)
        key = f"{target_triple} {executable_path}"

        settings = _SETTINGS.get(key)
        if not settings:
            fallback_key = _FALLBACK_KEYS.get(key)
            if fallback_key:
                settings = _SETTINGS.get(fallback_key)

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

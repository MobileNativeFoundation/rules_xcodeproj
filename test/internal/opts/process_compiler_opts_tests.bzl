"""Tests for compiler options processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:opts.bzl", "testable")

process_compiler_opts = testable.process_compiler_opts

def _process_compiler_opts_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    search_paths = process_compiler_opts(
        conlyopts = ctx.attr.conlyopts,
        cxxopts = ctx.attr.cxxopts,
        full_swiftcopts = ctx.attr.full_swiftcopts,
        user_swiftcopts = ctx.attr.user_swiftcopts,
        build_mode = ctx.attr.build_mode,
        compilation_mode = ctx.attr.compilation_mode,
        cpp_fragment = _cpp_fragment_stub(ctx.attr.cpp_fragment),
        objc_fragment = _objc_fragment_stub(ctx.attr.objc_fragment),
        cc_info = struct(
            compilation_context = struct(
                defines = depset(ctx.attr.cc_info_defines),
            ),
        ),
        package_bin_dir = ctx.attr.package_bin_dir,
        build_settings = build_settings,
    )
    string_build_settings = stringify_dict(build_settings)
    json_search_paths = json.encode(search_paths)

    expected_build_settings = {
        "DEBUG_INFORMATION_FORMAT": "",
        "ENABLE_STRICT_OBJC_MSGSEND": "True",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "SWIFT_OBJC_INTERFACE_HEADER_NAME": "",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5.0",
    }
    expected_build_settings.update(ctx.attr.expected_build_settings)

    if (ctx.attr.expected_build_settings.get("DEBUG_INFORMATION_FORMAT", "") ==
        "None"):
        expected_build_settings.pop("DEBUG_INFORMATION_FORMAT")

    asserts.equals(
        env,
        expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    asserts.equals(
        env,
        ctx.attr.expected_search_paths,
        json_search_paths,
        "search_paths",
    )

    return unittest.end(env)

process_compiler_opts_test = unittest.make(
    impl = _process_compiler_opts_test_impl,
    attrs = {
        "build_mode": attr.string(mandatory = True),
        "cc_info_defines": attr.string_list(default = []),
        "compilation_mode": attr.string(mandatory = True),
        "conlyopts": attr.string_list(mandatory = True),
        "cxxopts": attr.string_list(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_search_paths": attr.string(mandatory = True),
        "cpp_fragment": attr.string_dict(mandatory = False),
        "objc_fragment": attr.string_dict(mandatory = False),
        "package_bin_dir": attr.string(mandatory = True),
        "full_swiftcopts": attr.string_list(mandatory = True),
        "user_swiftcopts": attr.string_list(mandatory = True),
    },
)

def _cpp_fragment(*, apple_generate_dsym):
    return {
        "apple_generate_dsym": json.encode(apple_generate_dsym),
    }

def _objc_fragment(
        *,
        copts,
        copts_for_current_compilation_mode):
    return {
        "copts": json.encode(copts),
        "copts_for_current_compilation_mode": json.encode(
            copts_for_current_compilation_mode,
        ),
    }

def _cpp_fragment_stub(dict):
    if not dict:
        return struct(
            apple_generate_dsym = True,
        )
    return struct(
        apple_generate_dsym = json.decode(dict["apple_generate_dsym"]),
    )

def _objc_fragment_stub(dict):
    if not dict:
        return struct(
            copts = [],
            copts_for_current_compilation_mode = ["-DCOPTS_FOR_CURRENT"],
        )
    return struct(
        copts = json.decode(dict["copts"]),
        copts_for_current_compilation_mode = json.decode(
            dict["copts_for_current_compilation_mode"],
        ),
    )

def process_compiler_opts_test_suite(name):
    """Test suite for `process_compiler_opts`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            expected_build_settings,
            expected_search_paths = {
                "quote_includes": [],
                "includes": [],
                "system_includes": [],
            },
            conlyopts = [],
            cxxopts = [],
            full_swiftcopts = [],
            user_swiftcopts = [],
            build_mode = "bazel",
            compilation_mode = "dbg",
            cpp_fragment = None,
            objc_fragment = None,
            cc_info_defines = [],
            package_bin_dir = ""):
        test_names.append(name)
        process_compiler_opts_test(
            name = name,
            conlyopts = conlyopts,
            cxxopts = cxxopts,
            full_swiftcopts = full_swiftcopts,
            user_swiftcopts = user_swiftcopts,
            build_mode = build_mode,
            compilation_mode = compilation_mode,
            cpp_fragment = cpp_fragment,
            objc_fragment = objc_fragment,
            cc_info_defines = cc_info_defines,
            package_bin_dir = package_bin_dir,
            expected_build_settings = stringify_dict(expected_build_settings),
            expected_search_paths = json.encode(expected_search_paths),
            timeout = "short",
        )

    # Base

    _add_test(
        name = "{}_swift_integration".format(name),
        full_swiftcopts = [
            "-target",
            "arm64-apple-ios15.0-simulator",
            "-sdk",
            "__BAZEL_XCODE_SDKROOT__",
            "-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
            "-F__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks",
            "-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-emit-object",
            "-output-file-map",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.library.output_file_map.json",
            "-Xfrontend",
            "-no-clang-module-breadcrumbs",
            "-emit-module-path",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.swiftmodule",
            "-DDEBUG",
            "-Onone",
            "-Xfrontend",
            "-serialize-debugging-options",
            "-enable-testing",
            "-application-extension",
            "weird",
            "-gline-tables-only",
            "-Xwrapped-swift=-debug-prefix-pwd-is-dot",
            "-Xwrapped-swift=-ephemeral-module-cache",
            "-Xcc",
            "-iquote.",
            "-Xcc",
            "-iquotebazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin",
            "-Xfrontend",
            "-color-diagnostics",
            "-enable-batch-mode",
            "-unhandled",
            "-module-name",
            "ExampleUITests",
            "-parse-as-library",
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
        user_swiftcopts = [],
        expected_build_settings = {
            "APPLICATION_EXTENSION_API_ONLY": "True",
            "ENABLE_TESTABILITY": "True",
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT weird -unhandled",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        },
    )

    _add_test(
        name = "{}_empty".format(name),
        conlyopts = [],
        cxxopts = [],
        full_swiftcopts = [],
        user_swiftcopts = [],
        expected_build_settings = {},
    )

    # Skips

    ## C and C++
    # Anything with __BAZEL_XCODE_
    # -isysroot
    # -mios-simulator-version-min
    # -miphoneos-version-min
    # -mmacosx-version-min
    # -mtvos-simulator-version-min
    # -mtvos-version-min
    # -mwatchos-simulator-version-min
    # -mwatchos-version-min
    # -target

    ## Swift:
    # Anything with __BAZEL_XCODE_
    # -Ipath
    # -debug-prefix-map
    # -emit-module-path
    # -emit-object
    # -enable-batch-mode
    # -gline-tables-only
    # -module-name
    # -num-threads
    # -output-file-map
    # -parse-as-library
    # -sdk
    # -target
    # -Xcc
    # -Xfrontend
    # -Xwrapped-swift
    # Other things that end with ".swift", but don't start with "-"

    _add_test(
        name = "{}_skips".format(name),
        conlyopts = [
            "-mtvos-simulator-version-min=8.0",
            "-passthrough",
            "-isysroot",
            "other",
            "-mios-simulator-version-min=11.2",
            "-miphoneos-version-min=9.0",
            "-passthrough",
            "-mtvos-version-min=12.1",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-mwatchos-simulator-version-min=10.1",
            "-passthrough",
            "-mwatchos-version-min=9.2",
            "-target",
            "ios",
            "-mmacosx-version-min=12.0",
            "-passthrough",
        ],
        cxxopts = [
            "-isysroot",
            "something",
            "-miphoneos-version-min=9.4",
            "-mmacosx-version-min=10.9",
            "-passthrough",
            "-mtvos-version-min=12.2",
            "-mwatchos-simulator-version-min=9.3",
            "-passthrough",
            "-mtvos-simulator-version-min=12.1",
            "-mwatchos-version-min=10.2",
            "-I__BAZEL_XCODE_BOSS_",
            "-target",
            "macos",
            "-passthrough",
            "-mios-simulator-version-min=14.0",
        ],
        full_swiftcopts = [
            "-output-file-map",
            "path",
            "-passthrough",
            "-debug-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-file-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-emit-module-path",
            "path",
            "-passthrough",
            "-Xfrontend",
            "-color-diagnostics",
            "-Xfrontend",
            "-import-underlying-module",
            "-emit-object",
            "-enable-batch-mode",
            "-vfsoverlay",
            "Some/Path.yaml",
            "-passthrough",
            "-gline-tables-only",
            "-sdk",
            "something",
            "-module-name",
            "name",
            "-passthrough",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-num-threads",
            "6",
            "-passthrough",
            "-Ibazel-out/...",
            "-parse-as-library",
            "-passthrough",
            "-parse-as-library",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "/Some/Path.yaml",
            "-keep-me=something.swift",
            "reject-me.swift",
            "-Xfrontend",
            "-vfsoverlay/Some/Path.yaml",
            "-target",
            "ios",
            "-Xcc",
            "-weird",
            "-Xcc",
            "-a=bazel-out/hi",
            "-Xwrapped-swift",
            "-passthrough",
        ],
        user_swiftcopts = [
            "-Xcc",
            "-a=bazel-out/hi",
        ],
        expected_build_settings = {
            "OTHER_CFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_CPLUSPLUSFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_SWIFT_FLAGS": """\
-Xcc -DCOPTS_FOR_CURRENT \
-passthrough \
-passthrough \
-Xfrontend \
-import-underlying-module \
-passthrough \
-passthrough \
-passthrough \
-passthrough \
-keep-me=something.swift \
-passthrough \
-Xcc \
-a=$(BAZEL_OUT)/hi\
""",
        },
    )

    # Specific Xcode build settings

    ## DEBUG_INFORMATION_FORMAT

    _add_test(
        name = "{}_all-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        full_swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    _add_test(
        name = "{}_all-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        full_swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    _add_test(
        name = "{}_c-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        full_swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_c-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        full_swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
        },
    )

    _add_test(
        name = "{}_conly-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        full_swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CFLAGS": ["-g"],
        },
    )

    _add_test(
        name = "{}_cxx-debug".format(name),
        conlyopts = [],
        cxxopts = ["-g"],
        full_swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CPLUSPLUSFLAGS": ["-g"],
        },
    )

    _add_test(
        name = "{}_swift-debug-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        full_swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    _add_test(
        name = "{}_swift-debug-no-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        full_swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    _add_test(
        name = "{}_swift-and-c-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        full_swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CFLAGS": ["-g"],
            "OTHER_SWIFT_FLAGS": "-g -Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    ## ENABLE_STRICT_OBJC_MSGSEND

    _add_test(
        name = "{}_enable_strict_objc_msgsend".format(name),
        conlyopts = ["-DOBJC_OLD_DISPATCH_PROTOTYPES=1"],
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "ENABLE_STRICT_OBJC_MSGSEND": "False",
        },
    )

    ## ENABLE_TESTABILITY

    _add_test(
        name = "{}_swift_option-enable-testing".format(name),
        full_swiftcopts = ["-enable-testing"],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    ## APPLICATION_EXTENSION_API_ONLY

    _add_test(
        name = "{}_swift_option-application-extension".format(name),
        full_swiftcopts = ["-application-extension"],
        expected_build_settings = {
            "APPLICATION_EXTENSION_API_ONLY": "True",
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
        },
    )

    ## GCC_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_differing_gcc_optimization_level".format(name),
        conlyopts = ["-O0"],
        cxxopts = ["-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": ["-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O1"],
        },
    )

    _add_test(
        name = "{}_differing_gcc_optimization_level_common_first".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O1", "-O2"],
        expected_build_settings = {
            "GCC_OPTIMIZATION_LEVEL": "1",
            "OTHER_CFLAGS": ["-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O2"],
        },
    )

    _add_test(
        name = "{}_multiple_gcc_optimization_levels".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O0", "-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": ["-O1", "-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O0", "-O1"],
        },
    )

    _add_test(
        name = "{}_common_gcc_optimization_level".format(name),
        conlyopts = ["-O1"],
        cxxopts = ["-O1"],
        expected_build_settings = {
            "GCC_OPTIMIZATION_LEVEL": "1",
        },
    )

    ## GCC_PREPROCESSOR_DEFINITIONS

    _add_test(
        name = "{}_gcc_optimization_preprocessor_definitions".format(name),
        conlyopts = ["-DDEBUG", "-DDEBUG", "-DA=1", "-DZ=1", "-DB", "-DE"],
        cxxopts = ["-DDEBUG", "-DDEBUG", "-DA=1", "-DZ=2", "-DC", "-DE"],
        expected_build_settings = {
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG", "A=1"],
            "OTHER_CFLAGS": ["-DZ=1", "-DB", "-DE"],
            "OTHER_CPLUSPLUSFLAGS": ["-DZ=2", "-DC", "-DE"],
        },
    )

    ## SWIFT_ACTIVE_COMPILATION_CONDITIONS

    _add_test(
        name = "{}_defines".format(name),
        full_swiftcopts = [
            "-DDEBUG",
            "-DBAZEL",
            "-DDEBUG",
            "-DBAZEL",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG BAZEL",
        },
    )

    ## SWIFT_COMPILATION_MODE

    _add_test(
        name = "{}_multiple_swift_compilation_modes".format(name),
        full_swiftcopts = [
            "-wmo",
            "-no-whole-module-optimization",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-incremental".format(name),
        full_swiftcopts = ["-incremental"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-whole-module-optimization".format(name),
        full_swiftcopts = ["-whole-module-optimization"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-wmo".format(name),
        full_swiftcopts = ["-wmo"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-no-whole-module-optimization".format(name),
        full_swiftcopts = ["-no-whole-module-optimization"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    ## SWIFT_OBJC_INTERFACE_HEADER_NAME

    _add_test(
        name = "{}_generated_header".format(name),
        full_swiftcopts = [
            "-emit-objc-header-path",
            "a/b/c/TestingUtils-Custom.h",
        ],
        package_bin_dir = "a/b",
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "c/TestingUtils-Custom.h",
        },
    )

    ## SWIFT_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_multiple_swift_optimization_levels".format(name),
        full_swiftcopts = [
            "-Osize",
            "-Onone",
            "-O",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Onone".format(name),
        full_swiftcopts = ["-Onone"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        },
    )

    _add_test(
        name = "{}_swift_option-O".format(name),
        full_swiftcopts = ["-O"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Osize".format(name),
        full_swiftcopts = ["-Osize"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_OPTIMIZATION_LEVEL": "-Osize",
        },
    )

    ## SWIFT_STRICT_CONCURRENCY

    _add_test(
        name = "{}_swift_option-strict-concurrency".format(name),
        full_swiftcopts = ["-strict-concurrency=targeted"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_STRICT_CONCURRENCY": "targeted",
        },
    )

    ## SWIFT_VERSION

    _add_test(
        name = "{}_swift_option-swift-version".format(name),
        full_swiftcopts = ["-swift-version=42"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT",
            "SWIFT_VERSION": "42",
        },
    )

    # Swift PCM flags

    _add_test(
        name = "{}_pcm_no_copts_no_legacy".format(name),
        full_swiftcopts = ["-Xcc", "-O1", "-Xcc", "-DNDEBUG=1"],
        objc_fragment = _objc_fragment(
            copts = [],
            copts_for_current_compilation_mode = None,
        ),
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-Xcc -O0 -Xcc -DDEBUG=1 -Xcc -fstack-protector -Xcc -fstack-protector-all\
""",
        },
    )

    _add_test(
        name = "{}_pcm_copts_no_legacy".format(name),
        full_swiftcopts = ["-Xcc", "-O1", "-Xcc", "-DNDEBUG=1"],
        objc_fragment = _objc_fragment(
            copts = ["-wild", "-card"],
            copts_for_current_compilation_mode = None,
        ),
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-Xcc -wild -Xcc -card -Xcc -O0 -Xcc -DDEBUG=1 -Xcc -fstack-protector -Xcc \
-fstack-protector-all\
""",
        },
    )

    _add_test(
        name = "{}_pcm_no_copts_legacy".format(name),
        full_swiftcopts = ["-Xcc", "-O1", "-Xcc", "-DNDEBUG=1"],
        objc_fragment = _objc_fragment(
            copts = [],
            copts_for_current_compilation_mode = ["-legacy", "-flags"],
        ),
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -legacy -Xcc -flags",
        },
    )

    _add_test(
        name = "{}_pcm_copts_and_legacy".format(name),
        full_swiftcopts = ["-Xcc", "-O1", "-Xcc", "-DNDEBUG=1"],
        objc_fragment = _objc_fragment(
            copts = ["-c", "-flags"],
            copts_for_current_compilation_mode = ["-legacy", "-flags"],
        ),
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -c -Xcc -flags -Xcc -legacy -Xcc -flags",
        },
    )

    _add_test(
        name = "{}_pcm_defines".format(name),
        cc_info_defines = ["SWIFTY"],
        full_swiftcopts = ["-Xcc", "-O0", "-Xcc", "-DDEBUG=1"],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -DCOPTS_FOR_CURRENT -Xcc -DSWIFTY",
        },
    )

    # Search Paths

    _add_test(
        name = "{}_search_paths".format(name),
        conlyopts = [
            "-iquote",
            "a/b/c",
            "-Ix/y/z",
            "-I",
            "1/2/3",
            "-iquote",
            "0/9",
            "-isystem",
            "s1/s2",
        ],
        cxxopts = [
            "-iquote",
            "y/z",
            "-Ix/y/z",
            "-I",
            "aa/bb",
            "-isystem",
            "s3/s4",
        ],
        user_swiftcopts = [
            "-Xcc",
            "-Ic/d/e",
            "-Xcc",
            "-iquote4/5",
            "-Xcc",
            "-isystems5/s6",
        ],
        expected_build_settings = {},
        expected_search_paths = {
            "quote_includes": [
                "a/b/c",
                "0/9",
                "y/z",
                "4/5",
            ],
            "includes": [
                "x/y/z",
                "1/2/3",
                "aa/bb",
                "c/d/e",
            ],
            "system_includes": [
                "s1/s2",
                "s3/s4",
                "s5/s6",
            ],
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

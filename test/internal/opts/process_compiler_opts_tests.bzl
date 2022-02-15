"""Tests for compiler and linking options processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj/internal:opts.bzl", "testable")

process_compiler_opts = testable.process_compiler_opts

def _stringify_dict(dict):
    return {k: str(v) for k, v in dict.items()}

def _process_compiler_opts_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    process_compiler_opts(
        ctx.attr.conlyopts,
        ctx.attr.cxxopts,
        ctx.attr.swiftcopts,
        build_settings,
    )
    string_build_settings = _stringify_dict(build_settings)
    expected_build_settings = {
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5",
    }
    expected_build_settings.update(ctx.attr.expected_build_settings)

    asserts.equals(
        env,
        expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    return unittest.end(env)

process_compiler_opts_test = unittest.make(
    impl = _process_compiler_opts_test_impl,
    attrs = {
        "conlyopts": attr.string_list(mandatory = True),
        "cxxopts": attr.string_list(mandatory = True),
        "swiftcopts": attr.string_list(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
    },
)

def process_compiler_opts_test_suite(name):
    """Test suite for `process_compiler_opts`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
        name,
        expected_build_settings,
        conlyopts = [],
        cxxopts = [],
        swiftcopts = []):
        test_names.append(name)
        process_compiler_opts_test(
            name = name,
            conlyopts = conlyopts,
            cxxopts = cxxopts,
            swiftcopts = swiftcopts,
            expected_build_settings = expected_build_settings,
        )

    # Base

    _add_test(
        name = "{}_swift_integration".format(name),
        swiftcopts = [
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
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
            "OTHER_SWIFT_FLAGS": '''["weird", "-unhandled"]''',
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '''["DEBUG"]''',
        },
    )

    _add_test(
        name = "{}_empty".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = [],
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
        swiftcopts = [
            "-output-file-map",
            "path",
            "-passthrough",
            "-emit-module-path",
            "path",
            "-passthrough",
            "-Xfrontend",
            "-hidden",
            "-emit-object",
            "-enable-batch-mode",
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
            "-keep-me=something.swift",
            "reject-me.swift",
            "-target",
            "ios",
            "-Xcc",
            "-weird",
            "-Xwrapped-swift",
            "-passthrough",
        ],
        expected_build_settings = {
            "OTHER_CFLAGS": '''["-passthrough", "-passthrough", \
"-passthrough", "-passthrough"]''',
            "OTHER_CPLUSPLUSFLAGS": '''["-passthrough", "-passthrough", \
"-passthrough"]''',
            "OTHER_SWIFT_FLAGS": '''["-passthrough", "-passthrough", \
"-passthrough", "-passthrough", "-passthrough", "-passthrough", \
"-keep-me=something.swift", "-passthrough"]''',
        },
    )

    # Specific Xcode build settings

    # CLANG_CXX_LANGUAGE_STANDARD

    _add_test(
        name = "{}_options-std".format(name),
        conlyopts = ["-std=c++42"],
        cxxopts = ["-std=c++42"],
        expected_build_settings = {
            "CLANG_CXX_LANGUAGE_STANDARD": "c++42",
            "OTHER_CFLAGS": '''["-std=c++42"]''',
        },
    )

    _add_test(
        name = "{}_options-std=c++0x".format(name),
        cxxopts = ["-std=c++11"],
        expected_build_settings = {
            "CLANG_CXX_LANGUAGE_STANDARD": "c++0x",
        },
    )

    # CLANG_CXX_LIBRARY

    _add_test(
        name = "{}_options-stdlib".format(name),
        conlyopts = ["-stdlib=random"],
        cxxopts = ["-stdlib=random"],
        expected_build_settings = {
            "CLANG_CXX_LIBRARY": "random",
            "OTHER_CFLAGS": '''["-stdlib=random"]''',
        },
    )

    ## ENABLE_TESTABILITY

    _add_test(
        name = "{}_swift_option-enable-testing".format(name),
        swiftcopts = ["-enable-testing"],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
        },
    )

    ## GCC_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_differing_gcc_optimization_level".format(name),
        conlyopts = ["-O0"],
        cxxopts = ["-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": '''["-O0"]''',
            "OTHER_CPLUSPLUSFLAGS": '''["-O1"]''',
        },
    )

    _add_test(
        name = "{}_differing_gcc_optimization_level_common_first".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O1", "-O2"],
        expected_build_settings = {
            "GCC_OPTIMIZATION_LEVEL": "1",
            "OTHER_CFLAGS": '''["-O0"]''',
            "OTHER_CPLUSPLUSFLAGS": '''["-O2"]''',
        },
    )

    _add_test(
        name = "{}_multiple_gcc_optimization_levels".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O0", "-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": '''["-O1", "-O0"]''',
            "OTHER_CPLUSPLUSFLAGS": '''["-O0", "-O1"]''',
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

    ## SWIFT_ACTIVE_COMPILATION_CONDITIONS

    _add_test(
        name = "{}_defines".format(name),
        swiftcopts = [
            "-DDEBUG",
            "-DBAZEL=1",
            "-DDEBUG=1",
            "-DBAZEL=1",
        ],
        expected_build_settings = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '''["DEBUG", "BAZEL=1", "DEBUG=1", "BAZEL=1"]''',
        },
    )

    ## SWIFT_COMPILATION_MODE

    _add_test(
        name = "{}_multiple_swift_compilation_modes".format(name),
        swiftcopts = [
            "-wmo",
            "-no-whole-module-optimization",
        ],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-incremental".format(name),
        swiftcopts = ["-incremental"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-whole-module-optimization".format(name),
        swiftcopts = ["-whole-module-optimization"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-wmo".format(name),
        swiftcopts = ["-wmo",],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-no-whole-module-optimization".format(name),
        swiftcopts = ["-no-whole-module-optimization"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    ## SWIFT_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_multiple_swift_optimization_levels".format(name),
        swiftcopts = [
            "-Osize",
            "-Onone",
            "-O",
        ],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Onone".format(name),
        swiftcopts = ["-Onone"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        },
    )

    _add_test(
        name = "{}_swift_option-O".format(name),
        swiftcopts = ["-O"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Osize".format(name),
        swiftcopts = ["-Osize"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-Osize",
        },
    )

    # SWIFT_VERSION

    _add_test(
        name = "{}_swift_option-swift-version".format(name),
        swiftcopts = ["-swift-version=42"],
        expected_build_settings = {
            "SWIFT_VERSION": "42",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

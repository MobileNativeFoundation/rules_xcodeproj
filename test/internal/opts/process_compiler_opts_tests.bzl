"""Tests for compiler options processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:opts.bzl", "testable")

process_compiler_opts = testable.process_compiler_opts

def _process_compiler_opts_test_impl(ctx):
    env = unittest.begin(ctx)

    conlyopts = ctx.attr.conlyopts
    cxxopts = ctx.attr.cxxopts
    swiftcopts = ctx.attr.swiftcopts

    build_settings = {}
    (
        _,
        _,
        _,
        _,
        c_has_fortify_source,
        cxx_has_fortify_source,
    ) = process_compiler_opts(
        actions = None,
        name = "process_compiler_opts_tests",
        conlyopts = conlyopts,
        conly_args = [],
        cxxopts = cxxopts,
        cxx_args = [],
        swiftcopts = swiftcopts,
        swift_args = [],
        build_mode = ctx.attr.build_mode,
        cpp_fragment = _cpp_fragment_stub(ctx.attr.cpp_fragment),
        package_bin_dir = ctx.attr.package_bin_dir,
        build_settings = build_settings,
        cc_compiler_params_processor = None,
        swift_compiler_params_processor = None,
    )
    string_build_settings = stringify_dict(build_settings)

    expected_build_settings = {}
    if conlyopts or cxxopts or swiftcopts:
        expected_build_settings["DEBUG_INFORMATION_FORMAT"] = ""

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
        ctx.attr.expected_c_has_fortify_source,
        c_has_fortify_source,
        "c_has_fortify_source",
    )

    asserts.equals(
        env,
        ctx.attr.expected_cxx_has_fortify_source,
        cxx_has_fortify_source,
        "cxx_has_fortify_source",
    )

    return unittest.end(env)

process_compiler_opts_test = unittest.make(
    impl = _process_compiler_opts_test_impl,
    attrs = {
        "build_mode": attr.string(mandatory = True),
        "conlyopts": attr.string_list(mandatory = True),
        "cxxopts": attr.string_list(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_c_has_fortify_source": attr.bool(mandatory = True),
        "expected_cxx_has_fortify_source": attr.bool(mandatory = True),
        "cpp_fragment": attr.string_dict(mandatory = False),
        "package_bin_dir": attr.string(mandatory = True),
        "swiftcopts": attr.string_list(mandatory = True),
    },
)

def _cpp_fragment(*, apple_generate_dsym):
    return {
        "apple_generate_dsym": json.encode(apple_generate_dsym),
    }

def _cpp_fragment_stub(dict):
    if not dict:
        return struct(
            apple_generate_dsym = False,
        )
    return struct(
        apple_generate_dsym = json.decode(dict["apple_generate_dsym"]),
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
            expected_build_settings = {},
            expected_c_has_fortify_source = False,
            expected_cxx_has_fortify_source = False,
            conlyopts = [],
            cxxopts = [],
            swiftcopts = [],
            build_mode = "bazel",
            cpp_fragment = None,
            package_bin_dir = ""):
        test_names.append(name)
        process_compiler_opts_test(
            name = name,
            conlyopts = conlyopts,
            cxxopts = cxxopts,
            swiftcopts = swiftcopts,
            build_mode = build_mode,
            cpp_fragment = cpp_fragment,
            package_bin_dir = package_bin_dir,
            expected_build_settings = stringify_dict(expected_build_settings),
            expected_c_has_fortify_source = expected_c_has_fortify_source,
            expected_cxx_has_fortify_source = expected_cxx_has_fortify_source,
            timeout = "short",
        )

    # Base

    _add_test(
        name = "{}_swift_integration_bazel".format(name),
        build_mode = "bazel",
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
            "-fmodule-map-file=/abs/path",
            "-Xcc",
            "-I/abs/path",
            "-Xcc",
            "-iquote/abs/path",
            "-Xcc",
            "-isystem/abs/path",
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "-Xcc",
            "-Fsomewhere",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
        },
    )

    _add_test(
        name = "{}_swift_integration_xcode".format(name),
        build_mode = "xcode",
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
            "-fmodule-map-file=/abs/path",
            "-Xcc",
            "-I/abs/path",
            "-Xcc",
            "-iquote/abs/path",
            "-Xcc",
            "-isystem/abs/path",
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "-Xcc",
            "-Fsomewhere",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
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

    _add_test(
        name = "{}_skips_bazel".format(name),
        build_mode = "bazel",
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
            "-index-store-path",
            "bazel-out/_global_index_store",
            "-index-ignore-system-symbols",
            "--config",
            "relative/Path.yaml",
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
            "-index-store-path",
            "bazel-out/_global_index_store",
            "-index-ignore-system-symbols",
            "--config",
            "relative/Path.yaml",
        ],
        swiftcopts = [
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
            "/Some/Path.yaml",
            "-vfsoverlay",
            "relative/Path.yaml",
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
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "relative/Path.yaml",
            "-keep-me=something.swift",
            "reject-me.swift",
            "-Xfrontend",
            "-vfsoverlay/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlayrelative/Path.yaml",
            "-target",
            "ios",
            "-Xcc",
            "-weird",
            "-Xcc",
            "-a=bazel-out/hi",
            "-Xwrapped-swift",
            "-passthrough",
        ],
    )

    _add_test(
        name = "{}_skips_xcode".format(name),
        build_mode = "xcode",
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
            "-index-store-path",
            "bazel-out/_global_index_store",
            "-index-ignore-system-symbols",
            "--config",
            "relative/Path.yaml",
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
            "-index-store-path",
            "bazel-out/_global_index_store",
            "-index-ignore-system-symbols",
            "--config",
            "relative/Path.yaml",
        ],
        swiftcopts = [
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
            "-Xcc",
            "-a=bazel-out/hi",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "relative/path",
            "-Xwrapped-swift",
            "-passthrough",
        ],
    )

    # -D_FORTIFY_SOURCE=1

    _add_test(
        name = "{}_has_fortify_source".format(name),
        conlyopts = [
            "-D_FORTIFY_SOURCE=1",
        ],
        cxxopts = [
            "-D_FORTIFY_SOURCE=1",
        ],
        expected_c_has_fortify_source = True,
        expected_cxx_has_fortify_source = True,
    )

    # Specific Xcode build settings

    ## DEBUG_INFORMATION_FORMAT

    _add_test(
        name = "{}_all-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        },
    )

    _add_test(
        name = "{}_all-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_no-debug-no-dsym".format(name),
        conlyopts = ["-a"],
        cxxopts = ["-b"],
        swiftcopts = ["-c"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
        },
    )

    _add_test(
        name = "{}_c-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        },
    )

    _add_test(
        name = "{}_c-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_conly-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_cxx-debug".format(name),
        conlyopts = [],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_swift-debug-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        },
    )

    _add_test(
        name = "{}_swift-debug-no-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_swift-and-c-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
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
        swiftcopts = ["-enable-testing"],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
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
        swiftcopts = ["-wmo"],
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

    ## SWIFT_OBJC_INTERFACE_HEADER_NAME

    _add_test(
        name = "{}_generated_header".format(name),
        swiftcopts = [
            "-emit-objc-header-path",
            "a/b/c/TestingUtils-Custom.h",
        ],
        package_bin_dir = "a/b",
        expected_build_settings = {
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "c/TestingUtils-Custom.h",
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
        expected_build_settings = {},
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

    ## SWIFT_VERSION

    _add_test(
        name = "{}_swift_option-swift-version".format(name),
        swiftcopts = ["-swift-version=42"],
        expected_build_settings = {
            "SWIFT_VERSION": "42",
        },
    )

    # Search Paths

    _add_test(
        name = "{}_search_paths".format(name),
        conlyopts = [
            "-iquote",
            "a/b/c",
            "-iquotea/b/c/d",
            "-Ix/y/z",
            "-I",
            "1/2/3",
            "-iquote",
            "0/9",
            "-isystem",
            "s1/s2",
            "-isystems1/s2/s3",
        ],
        cxxopts = [
            "-iquote",
            "y/z",
            "-iquotey/z/1",
            "-Ix/y/z",
            "-I",
            "aa/bb",
            "-isystem",
            "s3/s4",
            "-isystems3/s4/s5",
        ],
        swiftcopts = [
            "-Xcc",
            "-Ic/d/e",
            "-Xcc",
            "-iquote4/5",
            "-Xcc",
            "-isystems5/s6",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

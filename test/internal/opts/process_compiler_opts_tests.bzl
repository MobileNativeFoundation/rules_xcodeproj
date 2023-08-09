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
            "-Xfrontend",
            "-color-diagnostics",
            "-enable-batch-mode",
            "-unhandled",
            "-module-name",
            "ExampleUITests",
            "-parse-as-library",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
    )

    _add_test(
        name = "{}_swift_integration_xcode".format(name),
        build_mode = "xcode",
        swiftcopts = [
            "-target",
            "arm64-apple-ios15.0-simulator",
            "-sdk",
            "__BAZEL_XCODE_SDKROOT__",
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
            "-Xfrontend",
            "-color-diagnostics",
            "-enable-batch-mode",
            "-unhandled",
            "-module-name",
            "ExampleUITests",
            "-parse-as-library",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
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
            "-num-threads",
            "6",
            "-passthrough",
            "-parse-as-library",
            "-passthrough",
            "-parse-as-library",
            "-keep-me=something.swift",
            "reject-me.swift",
            "-target",
            "ios",
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
            "-Xwrapped-swift",
            "-passthrough",
        ],
    )

    # -Xcc

    _add_test(
        name = "{}_swift_xcc".format(name),
        build_mode = "bazel",
        swiftcopts = [
            # -fmodule-map-file
            "-Xcc",
            "-fmodule-map-file=/absolute/path",
            "-Xcc",
            "-fmodule-map-file=relative/path",
            "-Xcc",
            "-fmodule-map-file=bazel-out/relative/path",
            "-Xcc",
            "-fmodule-map-file=external/relative/path",

            # -iquote
            "-Xcc",
            "-iquote/absolute/path",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "/absolute/path",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "/absolute/path",
            "-Xcc",
            "-iquoterelative/path",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "relative/path",
            "-Xcc",
            "-iquotebazel-out/relative/path",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "bazel-out/relative/path",
            "-Xcc",
            "-iquoteexternal/relative/path",
            "-Xcc",
            "-iquote",
            "-Xcc",
            "external/relative/path",
            "-Xcc",
            "-iquote.",
            "-Xcc",
            "-iquote",
            "-Xcc",
            ".",

            # -I
            "-Xcc",
            "-I/absolute/path",
            "-Xcc",
            "-I",
            "-Xcc",
            "/absolute/path",
            "-Xcc",
            "-Irelative/path",
            "-Xcc",
            "-I",
            "-Xcc",
            "relative/path",
            "-Xcc",
            "-Ibazel-out/relative/path",
            "-Xcc",
            "-I",
            "-Xcc",
            "bazel-out/relative/path",
            "-Xcc",
            "-Iexternal/relative/path",
            "-Xcc",
            "-I",
            "-Xcc",
            "external/relative/path",
            "-Xcc",
            "-I.",
            "-Xcc",
            "-I",
            "-Xcc",
            ".",

            # -isystem
            "-Xcc",
            "-isystem/absolute/path",
            "-Xcc",
            "-isystem",
            "-Xcc",
            "/absolute/path",
            "-Xcc",
            "-isystemrelative/path",
            "-Xcc",
            "-isystem",
            "-Xcc",
            "relative/path",
            "-Xcc",
            "-isystembazel-out/relative/path",
            "-Xcc",
            "-isystem",
            "-Xcc",
            "bazel-out/relative/path",
            "-Xcc",
            "-isystemexternal/relative/path",
            "-Xcc",
            "-isystem",
            "-Xcc",
            "external/relative/path",
            "-Xcc",
            "-isystem.",
            "-Xcc",
            "-isystem",
            "-Xcc",
            ".",

            # -ivfsoverlay
            "-Xcc",
            "-ivfsoverlay",
            "-Xcc",
            "/Some/Path.yaml",
            "-Xcc",
            "-ivfsoverlay",
            "-Xcc",
            "relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay",
            "-Xcc",
            "bazel-out/relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay",
            "-Xcc",
            "external/relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay/Some/Path.yaml",
            "-Xcc",
            "-ivfsoverlayrelative/Path.yaml",
            "-Xcc",
            "-ivfsoverlaybazel-out/relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlayexternal/relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay=/Some/Path.yaml",
            "-Xcc",
            "-ivfsoverlay=relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay=bazel-out/relative/Path.yaml",
            "-Xcc",
            "-ivfsoverlay=external/relative/Path.yaml",

            # Other
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "-Xcc",
            "-DNEEDS_QUOTES=Two words",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-Xcc -fmodule-map-file=/absolute/path \
-Xcc -fmodule-map-file=$(SRCROOT)/relative/path \
-Xcc -fmodule-map-file=$(BAZEL_OUT)/relative/path \
-Xcc -fmodule-map-file=$(BAZEL_EXTERNAL)/relative/path \
-Xcc -iquote -Xcc /absolute/path \
-Xcc -iquote -Xcc /absolute/path \
-Xcc -iquote -Xcc /absolute/path \
-Xcc -iquote -Xcc $(SRCROOT)/relative/path \
-Xcc -iquote -Xcc $(SRCROOT)/relative/path \
-Xcc -iquote -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -iquote -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -iquote -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -iquote -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -iquote -Xcc $(PROJECT_DIR) \
-Xcc -iquote -Xcc $(PROJECT_DIR) \
-Xcc -I -Xcc /absolute/path \
-Xcc -I -Xcc /absolute/path \
-Xcc -I -Xcc $(SRCROOT)/relative/path \
-Xcc -I -Xcc $(SRCROOT)/relative/path \
-Xcc -I -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -I -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -I -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -I -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -I -Xcc $(PROJECT_DIR) \
-Xcc -I -Xcc $(PROJECT_DIR) \
-Xcc -isystem -Xcc /absolute/path \
-Xcc -isystem -Xcc /absolute/path \
-Xcc -isystem -Xcc $(SRCROOT)/relative/path \
-Xcc -isystem -Xcc $(SRCROOT)/relative/path \
-Xcc -isystem -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -isystem -Xcc $(BAZEL_OUT)/relative/path \
-Xcc -isystem -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -isystem -Xcc $(BAZEL_EXTERNAL)/relative/path \
-Xcc -isystem -Xcc $(PROJECT_DIR) \
-Xcc -isystem -Xcc $(PROJECT_DIR) \
-Xcc -ivfsoverlay -Xcc /Some/Path.yaml \
-Xcc -ivfsoverlay -Xcc $(PROJECT_DIR)/relative/Path.yaml \
-Xcc -ivfsoverlay -Xcc $(PROJECT_DIR)/bazel-out/relative/Path.yaml \
-Xcc -ivfsoverlay -Xcc $(PROJECT_DIR)/external/relative/Path.yaml \
-Xcc -ivfsoverlay/Some/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/relative/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/bazel-out/relative/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/external/relative/Path.yaml \
-Xcc -ivfsoverlay=/Some/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/relative/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/bazel-out/relative/Path.yaml \
-Xcc -ivfsoverlay$(PROJECT_DIR)/external/relative/Path.yaml \
-Xcc -O0 \
-Xcc -DDEBUG=1 \
-Xcc "-DNEEDS_QUOTES=Two words"\
""",
        },
    )

    # -I

    _add_test(
        name = "{}_swift_I_paths_bazel".format(name),
        build_mode = "bazel",
        swiftcopts = [
            # -I
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-I",
            "__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-Irelative/path",
            "-Ibazel-out/relative/path",
            "-Iexternal/relative/path",
            "-I/absolute/path",
            "-I.",
            "-I",
            "relative/path",
            "-I",
            "bazel-out/relative/path",
            "-I",
            "external/relative/path",
            "-I",
            "/absolute/path",
            "-I",
            ".",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-I__BAZEL_XCODE_SOMETHING_/path \
-I$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-I \
$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-I$(SRCROOT)/relative/path \
-I$(BAZEL_OUT)/relative/path \
-I$(BAZEL_EXTERNAL)/relative/path \
-I/absolute/path \
-I$(PROJECT_DIR) \
-I \
$(SRCROOT)/relative/path \
-I \
$(BAZEL_OUT)/relative/path \
-I \
$(BAZEL_EXTERNAL)/relative/path \
-I \
/absolute/path \
-I \
$(PROJECT_DIR)\
""",
        },
    )

    _add_test(
        name = "{}_swift_I_paths_xcode".format(name),
        build_mode = "xcode",
        swiftcopts = [
            # -I
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-I",
            "__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-Irelative/path",
            "-Ibazel-out/relative/path",
            "-Iexternal/relative/path",
            "-I/absolute/path",
            "-I.",
            "-I",
            "relative/path",
            "-I",
            "bazel-out/relative/path",
            "-I",
            "external/relative/path",
            "-I",
            "/absolute/path",
            "-I",
            ".",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-I__BAZEL_XCODE_SOMETHING_/path \
-I$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-I \
$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-I/absolute/path \
-I \
/absolute/path\
""",
        },
    )

    # -F, -explicit-swift-module-map-file, -load-plugin-executable,
    # -load-plugin-library, and -vfsoverlay

    _add_test(
        name = "{}_swift_other_paths".format(name),
        build_mode = "bazel",
        swiftcopts = [
            # -explicit-swift-module-map-file
            "-explicit-swift-module-map-file",
            "/Some/Path.json",
            "-explicit-swift-module-map-file",
            "relative/Path.json",
            "-explicit-swift-module-map-file",
            "bazel-out/relative/Path.json",
            "-explicit-swift-module-map-file",
            "external/relative/Path.json",
            "-Xfrontend",
            "-explicit-swift-module-map-file",
            "-Xfrontend",
            "/Some/Path.json",
            "-Xfrontend",
            "-explicit-swift-module-map-file",
            "-Xfrontend",
            "relative/Path.json",
            "-Xfrontend",
            "-explicit-swift-module-map-file",
            "-Xfrontend",
            "bazel-out/relative/Path.json",
            "-Xfrontend",
            "-explicit-swift-module-map-file",
            "-Xfrontend",
            "external/relative/Path.json",

            # -load-plugin-executable
            "-load-plugin-executable",
            "/Some/MacroPlugin#MacroPlugin",
            "-load-plugin-executable",
            "relative/MacroPlugin#MacroPlugin",
            "-load-plugin-executable",
            "bazel-out/relative/MacroPlugin#MacroPlugin",
            "-load-plugin-executable",
            "external/relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-executable",
            "-Xfrontend",
            "/Some/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-executable",
            "-Xfrontend",
            "relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-executable",
            "-Xfrontend",
            "bazel-out/relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-executable",
            "-Xfrontend",
            "external/relative/MacroPlugin#MacroPlugin",

            # -load-plugin-library
            "-load-plugin-library",
            "/Some/MacroPlugin#MacroPlugin",
            "-load-plugin-library",
            "relative/MacroPlugin#MacroPlugin",
            "-load-plugin-library",
            "bazel-out/relative/MacroPlugin#MacroPlugin",
            "-load-plugin-library",
            "external/relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-library",
            "-Xfrontend",
            "/Some/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-library",
            "-Xfrontend",
            "relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-library",
            "-Xfrontend",
            "bazel-out/relative/MacroPlugin#MacroPlugin",
            "-Xfrontend",
            "-load-plugin-library",
            "-Xfrontend",
            "external/relative/MacroPlugin#MacroPlugin",

            # -vfsoverlay
            "-vfsoverlay",
            "/Some/Path.yaml",
            "-vfsoverlay",
            "relative/Path.yaml",
            "-vfsoverlay",
            "bazel-out/relative/Path.yaml",
            "-vfsoverlay",
            "external/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "bazel-out/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "external/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlayrelative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlaybazel-out/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlayexternal/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay=/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay=relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay=bazel-out/relative/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay=external/relative/Path.yaml",

            # -F
            "-F__BAZEL_XCODE_SOMETHING_/path",
            "-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-F",
            "__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-Frelative/path",
            "-Fbazel-out/relative/path",
            "-Fexternal/relative/path",
            "-F/absolute/path",
            "-F.",
            "-F",
            "relative/path",
            "-F",
            "bazel-out/relative/path",
            "-F",
            "external/relative/path",
            "-F",
            "/absolute/path",
            "-F",
            ".",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": """\
-explicit-swift-module-map-file \
/Some/Path.json \
-explicit-swift-module-map-file \
$(SRCROOT)/relative/Path.json \
-explicit-swift-module-map-file \
$(BAZEL_OUT)/relative/Path.json \
-explicit-swift-module-map-file \
$(BAZEL_EXTERNAL)/relative/Path.json \
-Xfrontend \
-explicit-swift-module-map-file \
-Xfrontend \
/Some/Path.json \
-Xfrontend \
-explicit-swift-module-map-file \
-Xfrontend \
$(SRCROOT)/relative/Path.json \
-Xfrontend \
-explicit-swift-module-map-file \
-Xfrontend \
$(BAZEL_OUT)/relative/Path.json \
-Xfrontend \
-explicit-swift-module-map-file \
-Xfrontend \
$(BAZEL_EXTERNAL)/relative/Path.json \
-load-plugin-executable \
/Some/MacroPlugin#MacroPlugin \
-load-plugin-executable \
$(SRCROOT)/relative/MacroPlugin#MacroPlugin \
-load-plugin-executable \
$(BAZEL_OUT)/relative/MacroPlugin#MacroPlugin \
-load-plugin-executable \
$(BAZEL_EXTERNAL)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-executable \
-Xfrontend \
/Some/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-executable \
-Xfrontend \
$(SRCROOT)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-executable \
-Xfrontend \
$(BAZEL_OUT)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-executable \
-Xfrontend \
$(BAZEL_EXTERNAL)/relative/MacroPlugin#MacroPlugin \
-load-plugin-library \
/Some/MacroPlugin#MacroPlugin \
-load-plugin-library \
$(SRCROOT)/relative/MacroPlugin#MacroPlugin \
-load-plugin-library \
$(BAZEL_OUT)/relative/MacroPlugin#MacroPlugin \
-load-plugin-library \
$(BAZEL_EXTERNAL)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-library \
-Xfrontend \
/Some/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-library \
-Xfrontend \
$(SRCROOT)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-library \
-Xfrontend \
$(BAZEL_OUT)/relative/MacroPlugin#MacroPlugin \
-Xfrontend \
-load-plugin-library \
-Xfrontend \
$(BAZEL_EXTERNAL)/relative/MacroPlugin#MacroPlugin \
-vfsoverlay \
/Some/Path.yaml \
-vfsoverlay \
$(SRCROOT)/relative/Path.yaml \
-vfsoverlay \
$(BAZEL_OUT)/relative/Path.yaml \
-vfsoverlay \
$(BAZEL_EXTERNAL)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
/Some/Path.yaml \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
$(SRCROOT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
$(BAZEL_OUT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
$(BAZEL_EXTERNAL)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay/Some/Path.yaml \
-Xfrontend \
-vfsoverlay$(SRCROOT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay$(BAZEL_OUT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay$(BAZEL_EXTERNAL)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay/Some/Path.yaml \
-Xfrontend \
-vfsoverlay$(SRCROOT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay$(BAZEL_OUT)/relative/Path.yaml \
-Xfrontend \
-vfsoverlay$(BAZEL_EXTERNAL)/relative/Path.yaml \
-F__BAZEL_XCODE_SOMETHING_/path \
-F$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-F \
$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
-F$(SRCROOT)/relative/path \
-F$(BAZEL_OUT)/relative/path \
-F$(BAZEL_EXTERNAL)/relative/path \
-F/absolute/path \
-F$(PROJECT_DIR) \
-F \
$(SRCROOT)/relative/path \
-F \
$(BAZEL_OUT)/relative/path \
-F \
$(BAZEL_EXTERNAL)/relative/path \
-F \
/absolute/path \
-F \
$(PROJECT_DIR)\
""",
        },
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
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

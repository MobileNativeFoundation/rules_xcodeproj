"""Tests for `pbxproj_partials.write_target_build_settings`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_BUILD_SETTINGS_DECLARED_FILE = mock_actions.mock_file(
    "a_target_name.rules_xcodeproj.build_settings",
)
_DEBUG_SETTINGS_DECLARED_FILE = mock_actions.mock_file(
    "a_target_name.rules_xcodeproj.debug_settings",
)
_C_PARAMS_DECLARED_FILE = mock_actions.mock_file(
    "a_target_name.c.compile.params",
)
_CXX_PARAMS_DECLARED_FILE = mock_actions.mock_file(
    "a_target_name.cxx.compile.params",
)
_CLANG_PARAMS_DECLARED_FILE = mock_actions.mock_file(
    "a_target_name.clang.params",
)

def _write_target_build_settings_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_files = {}
    expected_inputs = []
    expected_outputs = []
    expected_params = []

    if ctx.attr.expect_build_settings:
        expected_build_settings = _BUILD_SETTINGS_DECLARED_FILE
        expected_declared_files[expected_build_settings] = None
        expected_outputs.append(expected_build_settings)
    else:
        expected_build_settings = None

    swift_debug_settings_to_merge = depset(
        ctx.attr.swift_debug_settings_to_merge,
    )

    if ctx.attr.expect_debug_settings:
        expected_debug_settings = _DEBUG_SETTINGS_DECLARED_FILE
        expected_declared_files[expected_debug_settings] = None
        expected_inputs = swift_debug_settings_to_merge
        expected_outputs.append(expected_debug_settings)
    else:
        expected_debug_settings = None

    if ctx.attr.expect_c_params:
        expected_declared_files[_C_PARAMS_DECLARED_FILE] = None
        expected_outputs.append(_C_PARAMS_DECLARED_FILE)
        expected_params.append(_C_PARAMS_DECLARED_FILE)
    if ctx.attr.expect_cxx_params:
        expected_declared_files[_CXX_PARAMS_DECLARED_FILE] = None
        expected_outputs.append(_CXX_PARAMS_DECLARED_FILE)
        expected_params.append(_CXX_PARAMS_DECLARED_FILE)
    if ctx.attr.expect_clang_params:
        expected_declared_files[_CLANG_PARAMS_DECLARED_FILE] = None
        expected_outputs.append(_CLANG_PARAMS_DECLARED_FILE)
        expected_params.append(_CLANG_PARAMS_DECLARED_FILE)

    expect_outputs = bool(expected_build_settings or expected_debug_settings)

    conly_args = ctx.attr.conly_args
    cxx_args = ctx.attr.cxx_args
    swift_args = ctx.attr.swift_args

    # Act

    (
        build_settings,
        debug_settings,
        params,
    ) = pbxproj_partials.write_target_build_settings(
        actions = actions.mock,
        allow_remote = ctx.attr.allow_remote,
        apple_generate_dsym = ctx.attr.apple_generate_dsym,
        certificate_name = ctx.attr.certificate_name,
        colorize = ctx.attr.colorize,
        conly_args = conly_args,
        cxx_args = cxx_args,
        device_family = ctx.attr.device_family,
        entitlements = ctx.attr.entitlements,
        extension_safe = ctx.attr.extension_safe,
        generate_build_settings = ctx.attr.generate_build_settings,
        generate_swift_debug_settings = ctx.attr.generate_swift_debug_settings,
        include_self_swift_debug_settings = (
            ctx.attr.include_self_swift_debug_settings
        ),
        infoplist = ctx.attr.infoplist,
        name = "a_target_name",
        previews_dynamic_frameworks = [
            (mock_actions.mock_file(f), True)
            for f in ctx.attr.previews_dynamic_frameworks
        ],
        previews_include_path = ctx.attr.previews_include_path,
        provisioning_profile_is_xcode_managed = ctx.attr.provisioning_profile_is_xcode_managed,
        provisioning_profile_name = ctx.attr.provisioning_profile_name,
        separate_index_build_output_base = ctx.attr.separate_index_build_output_base,
        swift_args = swift_args,
        swift_debug_settings_to_merge = swift_debug_settings_to_merge,
        team_id = ctx.attr.team_id,
        tool = None,
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_files,
        actions.declared_files,
        "actions.declare_file",
    )

    if expect_outputs:
        asserts.equals(
            env,
            ([actions.args_objects[0]] + swift_args +
             [actions.args_objects[1]] + conly_args +
             [actions.args_objects[2]] + cxx_args),
            actions.run_args["arguments"],
            "actions.run.arguments",
        )

        asserts.equals(
            env,
            ctx.attr.expected_args,
            actions.args_objects[0].captured.args,
            "args[0] arguments",
        )

        asserts.equals(
            env,
            expected_inputs,
            actions.run_args["inputs"],
            "actions.run.inputs",
        )

        asserts.equals(
            env,
            expected_outputs,
            actions.run_args["outputs"],
            "actions.run.outputs",
        )

    asserts.equals(
        env,
        expected_build_settings,
        build_settings,
        "build_settings",
    )
    asserts.equals(
        env,
        expected_debug_settings,
        debug_settings,
        "debug_settings",
    )
    asserts.equals(
        env,
        expected_params,
        params,
        "params",
    )

    return unittest.end(env)

write_target_build_settings_test = unittest.make(
    impl = _write_target_build_settings_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "allow_remote": attr.bool(mandatory = True),
        "apple_generate_dsym": attr.bool(mandatory = True),
        "certificate_name": attr.string(),
        "colorize": attr.bool(mandatory = True),
        "conly_args": attr.string_list(mandatory = True),
        "cxx_args": attr.string_list(mandatory = True),
        "device_family": attr.string(mandatory = True),
        "entitlements": attr.string(),
        "extension_safe": attr.bool(mandatory = True),
        "generate_build_settings": attr.bool(mandatory = True),
        "generate_swift_debug_settings": attr.bool(mandatory = True),
        "include_self_swift_debug_settings": attr.bool(mandatory = True),
        "infoplist": attr.string(),
        "previews_dynamic_frameworks": attr.string_list(mandatory = True),
        "previews_include_path": attr.string(mandatory = True),
        "provisioning_profile_is_xcode_managed": attr.bool(mandatory = True),
        "provisioning_profile_name": attr.string(),
        "separate_index_build_output_base": attr.bool(mandatory = True),
        "swift_debug_settings_to_merge": attr.string_list(mandatory = True),
        "swift_args": attr.string_list(mandatory = True),
        "team_id": attr.string(),

        # Expected
        "expect_build_settings": attr.bool(mandatory = True),
        "expect_c_params": attr.bool(mandatory = True),
        "expect_clang_params": attr.bool(mandatory = True),
        "expect_cxx_params": attr.bool(mandatory = True),
        "expect_debug_settings": attr.bool(mandatory = True),
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_target_build_settings_test_suite(name):
    """Test suite for `pbxproj_partials.write_target_build_settings`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            allow_remote = False,
            apple_generate_dsym = False,
            certificate_name = None,
            colorize = False,
            conly_args,
            cxx_args,
            device_family = "",
            entitlements = None,
            extension_safe = False,
            generate_build_settings,
            generate_swift_debug_settings,
            include_self_swift_debug_settings = True,
            infoplist = None,
            previews_dynamic_frameworks = [],
            previews_include_path = "",
            provisioning_profile_is_xcode_managed = False,
            provisioning_profile_name = None,
            separate_index_build_output_base = False,
            swift_args,
            swift_debug_settings_to_merge = [],
            team_id = None,

            # Expected
            expect_build_settings = True,
            expect_c_params,
            expect_clang_params,
            expect_cxx_params,
            expect_debug_settings,
            expected_args):
        test_names.append(name)
        write_target_build_settings_test(
            name = name,

            # Inputs
            allow_remote = allow_remote,
            apple_generate_dsym = apple_generate_dsym,
            certificate_name = certificate_name,
            colorize = colorize,
            conly_args = conly_args,
            cxx_args = cxx_args,
            device_family = device_family,
            entitlements = entitlements,
            extension_safe = extension_safe,
            generate_build_settings = generate_build_settings,
            generate_swift_debug_settings = generate_swift_debug_settings,
            include_self_swift_debug_settings = include_self_swift_debug_settings,
            infoplist = infoplist,
            previews_dynamic_frameworks = previews_dynamic_frameworks,
            previews_include_path = previews_include_path,
            provisioning_profile_is_xcode_managed = provisioning_profile_is_xcode_managed,
            provisioning_profile_name = provisioning_profile_name,
            separate_index_build_output_base = separate_index_build_output_base,
            swift_args = swift_args,
            swift_debug_settings_to_merge = swift_debug_settings_to_merge,
            team_id = team_id,

            # Expected
            expect_build_settings = expect_build_settings,
            expect_c_params = expect_c_params,
            expect_clang_params = expect_clang_params,
            expect_cxx_params = expect_cxx_params,
            expect_debug_settings = expect_debug_settings,
            expected_args = expected_args,
        )

    # No build settings and no debug settings

    _add_test(
        name = "{}_no_build_settings_no_debug_settings".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        generate_build_settings = False,
        generate_swift_debug_settings = False,
        swift_args = [],

        # Expected
        expect_build_settings = False,
        expect_c_params = False,
        expect_clang_params = False,
        expect_cxx_params = False,
        expect_debug_settings = False,
        expected_args = [],
    )

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        generate_build_settings = True,
        generate_swift_debug_settings = False,
        swift_args = [],

        # Expected
        expect_c_params = False,
        expect_clang_params = False,
        expect_cxx_params = False,
        expect_debug_settings = False,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            "",
        ],
    )

    # C and C++

    _add_test(
        name = "{}_conly".format(name),

        # Inputs
        conly_args = ["a", "c", "b"],
        cxx_args = [],
        generate_build_settings = True,
        generate_swift_debug_settings = False,
        swift_args = [],

        # Expected
        expect_c_params = True,
        expect_clang_params = False,
        expect_cxx_params = False,
        expect_debug_settings = False,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            "",
        ],
    )

    _add_test(
        name = "{}_cxx".format(name),

        # Inputs
        conly_args = [],
        cxx_args = ["a", "c", "b"],
        generate_build_settings = True,
        generate_swift_debug_settings = False,
        swift_args = [],

        # Expected
        expect_c_params = False,
        expect_clang_params = False,
        expect_cxx_params = True,
        expect_debug_settings = False,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            "",
        ],
    )

    _add_test(
        name = "{}_conly_and_cxx".format(name),

        # Inputs
        conly_args = ["a1", "c2", "b1"],
        cxx_args = ["a2", "c1", "b2"],
        generate_build_settings = True,
        generate_swift_debug_settings = False,
        swift_args = [],

        # Expected
        expect_c_params = True,
        expect_clang_params = False,
        expect_cxx_params = True,
        expect_debug_settings = False,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            "",
        ],
    )

    # Mixed language

    _add_test(
        name = "{}_mixed_language".format(name),

        # Inputs
        conly_args = ["a1", "c2", "b1"],
        cxx_args = ["a2", "c1", "b2"],
        generate_build_settings = True,
        generate_swift_debug_settings = True,
        include_self_swift_debug_settings = False,
        swift_args = ["a", "c", "b"],

        # Expected
        expect_c_params = True,
        expect_clang_params = True,
        expect_cxx_params = True,
        expect_debug_settings = True,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            _DEBUG_SETTINGS_DECLARED_FILE.path,
            # includeSelfSwiftDebugSettings
            "0",
            # transitiveSwiftDebugSettingPaths
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            _CLANG_PARAMS_DECLARED_FILE.path,
        ],
    )

    # Provisioning profile

    _add_test(
        name = "{}_provisioning_profile".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        certificate_name = "best certificate",
        entitlements = "some/app.entitlements",
        generate_build_settings = True,
        generate_swift_debug_settings = False,
        provisioning_profile_is_xcode_managed = True,
        provisioning_profile_name = "a profile",
        swift_args = [],
        team_id = "12345-a 54",

        # Expected
        expect_c_params = False,
        expect_clang_params = False,
        expect_cxx_params = False,
        expect_debug_settings = False,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "some/app.entitlements",
            # certificateName
            "best certificate",
            # provisioningProfileName
            "a profile",
            # teamID
            "12345-a 54",
            # provisioningProfileIsXcodeManaged
            "1",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            "",
        ],
    )

    # Swift

    _add_test(
        name = "{}_swift_args_no_transitive".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        generate_build_settings = True,
        generate_swift_debug_settings = True,
        swift_args = ["-v", "a"],

        # Expected
        expect_c_params = False,
        expect_clang_params = True,
        expect_cxx_params = False,
        expect_debug_settings = True,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            _DEBUG_SETTINGS_DECLARED_FILE.path,
            # includeSelfSwiftDebugSettings
            "1",
            # transitiveSwiftDebugSettingPaths
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            _CLANG_PARAMS_DECLARED_FILE.path,
        ],
    )

    _add_test(
        name = "{}_swift_args_transitive".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        generate_build_settings = True,
        generate_swift_debug_settings = True,
        swift_args = ["-v", "a"],
        swift_debug_settings_to_merge = [
            "transitive_debug_settings/2",
            "transitive_debug_settings/1",
        ],

        # Expected
        expect_c_params = False,
        expect_clang_params = True,
        expect_cxx_params = False,
        expect_debug_settings = True,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            _BUILD_SETTINGS_DECLARED_FILE.path,
            # swiftDebugSettingsOutputPath
            _DEBUG_SETTINGS_DECLARED_FILE.path,
            # includeSelfSwiftDebugSettings
            "1",
            # transitiveSwiftDebugSettingPaths
            "transitive_debug_settings/2",
            "transitive_debug_settings/1",
            "",
            # deviceFamily
            "",
            # extensionSafe
            "0",
            # generatesDsyms
            "0",
            # infoPlist
            "",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            "",
            # previewsIncludePath
            "",
            # separateIndexBuildOutputBase
            "0",
            # clangParamsOutputPath
            _CLANG_PARAMS_DECLARED_FILE.path,
        ],
    )

    # Top-level

    _add_test(
        name = "{}_top_level".format(name),

        # Inputs
        conly_args = [],
        cxx_args = [],
        device_family = "1,2",
        extension_safe = True,
        generate_build_settings = False,
        generate_swift_debug_settings = True,
        include_self_swift_debug_settings = False,
        infoplist = "some/Info.plist",
        previews_dynamic_frameworks = [
            "bazel-out/generated.framework",
            "/absolute/f.framework",
            "../repo/2.framework",
            "project/a.framework",
            "external/repo/1.framework",
        ],
        previews_include_path = "bazel-out/swiftmodule/parent",
        separate_index_build_output_base = True,
        swift_args = [],
        swift_debug_settings_to_merge = [
            "transitive_debug_settings/3",
            "transitive_debug_settings/1",
            "transitive_debug_settings/2",
        ],

        # Expected
        expect_build_settings = False,
        expect_c_params = False,
        expect_clang_params = False,
        expect_cxx_params = False,
        expect_debug_settings = True,
        expected_args = [
            # colorize
            "0",
            # buildSettingsOutputPath
            "",
            # swiftDebugSettingsOutputPath
            _DEBUG_SETTINGS_DECLARED_FILE.path,
            # includeSelfSwiftDebugSettings
            "0",
            # transitiveSwiftDebugSettingPaths
            "transitive_debug_settings/3",
            "transitive_debug_settings/1",
            "transitive_debug_settings/2",
            "",
            # deviceFamily
            "1,2",
            # extensionSafe
            "1",
            # generatesDsyms
            "0",
            # infoPlist
            "some/Info.plist",
            # entitlements
            "",
            # certificateName
            "",
            # provisioningProfileName
            "",
            # teamID
            "",
            # provisioningProfileIsXcodeManaged
            "0",
            # previewsFrameworkPaths
            """\
"$(BAZEL_OUT)/generated.framework" \
"/absolute/f.framework" \
"$(BAZEL_EXTERNAL)/repo/2.framework" \
"$(SRCROOT)/project/a.framework" \
"$(BAZEL_EXTERNAL)/repo/1.framework"\
""",
            # previewsIncludePath
            "bazel-out/swiftmodule/parent",
            # separateIndexBuildOutputBase
            "1",
            # clangParamsOutputPath
            "",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

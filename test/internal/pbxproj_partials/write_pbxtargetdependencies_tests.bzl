"""Tests for `pbxproj_partials.write_pbxtargetdependencies`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")
load("//test:utils.bzl", "mock_apple_platform_to_platform_name")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_TARGET_DEPENDENCIES_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pbxtargetdependencies",
)
_TARGETS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pbxproject_targets",
)
_TARGET_ATTRIBUTES_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pbxproject_target_attributes",
)
_CONSOLIDATION_MAPS_INPUTS_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/consolidation_maps_inputs_file",
)

def _consolidation_map_declared_file(idx):
    return mock_actions.mock_file(
        "a_generator_name_pbxproj_partials/consolidation_maps/{}".format(idx),
    )

def _json_to_xcode_targets_by_label(json_str):
    return {
        Label(label): _dict_to_xcode_targets_by_id(d)
        for label, d in json.decode(json_str).items()
    }

def _dict_to_xcode_targets_by_id(d):
    return {
        id: _dict_to_xcode_target(xcode_target_dict)
        for id, xcode_target_dict in d.items()
    }

def _dict_to_xcode_target(d):
    return struct(
        id = d["id"],
        direct_dependencies = depset(d["direct_dependencies"]),
        module_name_attribute = d["module_name_attribute"],
        platform = struct(
            apple_platform = d["apple_platform"],
            arch = d["arch"],
            os_version = d["os_version"],
        ),
        product = struct(
            basename = d["product_basename"],
            original_basename = d["product_original_basename"],
            type = d["product_type"],
        ),
        test_host = d["test_host"],
        watchkit_extension = d["watchkit_extension"],
    )

# FIXME: Extract
def mock_xcode_target(
        *,
        id,
        apple_platform,
        arch,
        direct_dependencies,
        module_name_attribute,
        os_version,
        product_basename,
        product_original_basename,
        product_type,
        test_host = None,
        watchkit_extension = None):
    return struct(
        id = id,
        apple_platform = apple_platform,
        arch = arch,
        direct_dependencies = direct_dependencies,
        module_name_attribute = module_name_attribute or "",
        os_version = os_version,
        product_basename = product_basename,
        product_original_basename = product_original_basename,
        product_type = product_type,
        test_host = test_host,
        watchkit_extension = watchkit_extension,
    )

def _write_pbxtargetdependencies_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_files = {
        _TARGET_DEPENDENCIES_DECLARED_FILE: None,
        _TARGETS_DECLARED_FILE: None,
        _TARGET_ATTRIBUTES_DECLARED_FILE: None,
        _CONSOLIDATION_MAPS_INPUTS_FILE: None,
    }
    expected_outputs = [
        _TARGET_DEPENDENCIES_DECLARED_FILE,
        _TARGETS_DECLARED_FILE,
        _TARGET_ATTRIBUTES_DECLARED_FILE,
    ]

    xcode_targets_by_label = _json_to_xcode_targets_by_label(
        ctx.attr.xcode_targets_by_label,
    )

    shard_count = ctx.attr.generator_shard_count

    bucketed_labels = {}
    for label in xcode_targets_by_label:
        bucketed_labels.setdefault(
            hash(label.name) % shard_count,
            [],
        ).append(label)

    expected_consolidation_maps = {}
    for idx, labels in enumerate(bucketed_labels.values()):
        file = _consolidation_map_declared_file(idx)
        expected_consolidation_maps[file] = labels
        expected_declared_files[file] = None
        expected_outputs.append(file)

    # Act

    (
        pbxtargetdependencies,
        pbxproject_targets,
        pbxproject_target_attributes,
        consolidation_maps,
    ) = pbxproj_partials.write_pbxtargetdependencies(
        actions = actions.mock,
        apple_platform_to_platform_name = mock_apple_platform_to_platform_name,
        colorize = ctx.attr.colorize,
        generator_name = "a_generator_name",
        install_path = "a/project.xcodeproj",
        minimum_xcode_version = ctx.attr.minimum_xcode_version,
        shard_count = shard_count,
        target_name_mode = ctx.attr.target_name_mode,
        tool = None,
        xcode_target_configurations = ctx.attr.xcode_target_configurations,
        xcode_targets_by_label = xcode_targets_by_label,
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_files,
        actions.declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        ctx.attr.expected_writes,
        actions.writes,
        "actions.write",
    )

    asserts.equals(
        env,
        "@%s",
        actions.args_objects[0].captured.use_param_file_args["use_param_file"],
        "args[0].use_param_file",
    )

    asserts.equals(
        env,
        "multiline",
        actions.args_objects[0].captured.set_param_file_format_args["format"],
        "args[0].param_file_format",
    )

    asserts.equals(
        env,
        [actions.args_objects[0]],
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
        expected_outputs,
        actions.run_args["outputs"],
        "actions.run.outputs",
    )

    asserts.equals(
        env,
        _TARGET_DEPENDENCIES_DECLARED_FILE,
        pbxtargetdependencies,
        "pbxtargetdependencies",
    )
    asserts.equals(
        env,
        _TARGETS_DECLARED_FILE,
        pbxproject_targets,
        "pbxproject_targets",
    )
    asserts.equals(
        env,
        _TARGET_ATTRIBUTES_DECLARED_FILE,
        pbxproject_target_attributes,
        "pbxproject_target_attributes",
    )

    asserts.equals(
        env,
        expected_consolidation_maps,
        consolidation_maps,
        "consolidation_maps",
    )

    return unittest.end(env)

write_pbxtargetdependencies_test = unittest.make(
    impl = _write_pbxtargetdependencies_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "generator_shard_count": attr.int(mandatory = True),
        "minimum_xcode_version": attr.string(mandatory = True),
        "target_name_mode": attr.string(mandatory = True),
        "xcode_target_configurations": attr.string_list_dict(mandatory = True),
        "xcode_targets_by_label": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
        "expected_writes": attr.string_dict(mandatory = True),
    },
)

def write_pbxtargetdependencies_test_suite(name):
    """Test suite for `pbxproj_partials.write_pbxtargetdependencies`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            colorize = False,
            minimum_xcode_version,
            target_name_mode,
            shard_count = 2,
            xcode_target_configurations,
            xcode_targets_by_label,

            # Expected
            expected_args,
            expected_writes):
        test_names.append(name)
        write_pbxtargetdependencies_test(
            name = name,

            # Inputs
            colorize = colorize,
            generator_shard_count = shard_count,
            minimum_xcode_version = minimum_xcode_version,
            target_name_mode = target_name_mode,
            xcode_target_configurations = xcode_target_configurations,
            xcode_targets_by_label = json.encode(xcode_targets_by_label),

            # Expected
            expected_args = expected_args,
            expected_writes = {
                file.path: content
                for file, content in expected_writes.items()
            },
        )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
        minimum_xcode_version = "14.3.1",
        target_name_mode = "label",
        xcode_target_configurations = {
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": ["Release"],
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3": ["Debug", "Release"],
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": ["Debug"],
        },
        xcode_targets_by_label = {
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle": {
                "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": mock_xcode_target(
                    id = "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                    direct_dependencies = [
                        "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                    ],
                    apple_platform = "MACOS",
                    arch = "arm64",
                    os_version = "16.2.1",
                    product_type = "u",
                    product_basename = "tests.xctest",
                    product_original_basename = "tests.xctest",
                    module_name_attribute = "tests",
                    test_host = "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                ),
            },
            "//tools/generators/legacy:generator": {
                "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3": mock_xcode_target(
                    id = "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                    apple_platform = "IOS_DEVICE",
                    arch = "x86_64",
                    direct_dependencies = [
                        "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                    ],
                    os_version = "12.0",
                    product_type = "T",
                    product_basename = "codesigned_generator",
                    product_original_basename = "generator",
                    module_name_attribute = None,
                ),
            },
            "//tools/generators/legacy:generator.library": {
                "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": mock_xcode_target(
                    id = "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                    apple_platform = "WATCHOS_SIMULATOR",
                    arch = "i386",
                    direct_dependencies = [],
                    os_version = "9.1",
                    product_type = "L",
                    product_basename = "libgenerator.a",
                    product_original_basename = "libgenerator.a",
                    module_name_attribute = "generator",
                    # This doesn't make sense, it's just to test it
                    watchkit_extension = "//some/extension some-config",
                ),
            },
        },

        # Expected
        expected_args = [
            # targetDependenciesOutputPath
            _TARGET_DEPENDENCIES_DECLARED_FILE.path,
            # targetsOutputPath
            _TARGETS_DECLARED_FILE.path,
            # targetAttributesOutputPath
            _TARGET_ATTRIBUTES_DECLARED_FILE.path,
            # consolidationMapsInputsFile,
            _CONSOLIDATION_MAPS_INPUTS_FILE.path,
            # minimumXcodeVersion
            "14.3.1",
            # targetNameMode
            "label",
            # targetAndTestHosts
            "--target-and-test-hosts",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
            # targetAndWatchKitExtensions
            "--target-and-watch-kit-extensions",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "//some/extension some-config",
            "--colorize",
        ],
        expected_writes = {
            _CONSOLIDATION_MAPS_INPUTS_FILE: "\n".join([
                "2",
                _consolidation_map_declared_file(0).path,
                _consolidation_map_declared_file(1).path,
                "2",
                str(Label("//tools/generators/legacy/test:tests.__internal__.__test_bundle")),
                "1",
                "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                "u",
                "macosx",
                "16.2.1",
                "arm64",
                "tests",
                "tests.xctest",
                "tests.xctest",
                "1",
                "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                "1",
                "Release",
                str(Label("//tools/generators/legacy:generator")),
                "1",
                "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                "T",
                "iphoneos",
                "12.0",
                "x86_64",
                "",
                "generator",
                "codesigned_generator",
                "1",
                "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                "2",
                "Debug",
                "Release",
                "1",
                str(Label("//tools/generators/legacy:generator.library")),
                "1",
                "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                "L",
                "watchsimulator",
                "9.1",
                "i386",
                "generator",
                "libgenerator.a",
                "libgenerator.a",
                "0",
                "1",
                "Debug",
            ]) + "\n",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

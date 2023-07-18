"""Tests for `pbxproj_partials.write_pbxproject_targets`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "mock_apple_platform_to_platform_name")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_TARGETS_DECLARED_FILE = "a_generator_name_pbxproj_partials/pbxproject_targets"
_TARGET_ATTRIBUTES_DECLARED_FILE = "a_generator_name_pbxproj_partials/pbxproject_target_attributes"
_TARGET_DEPENDENCIES_DECLARED_FILE = "a_generator_name_pbxproj_partials/pbxtargetdependencies"

def _consolidation_map_declared_file(idx):
    return "a_generator_name_pbxproj_partials/consolidation_maps/{}".format(idx)

def _quote_if_needed(str):
    if " " in str:
        return "'{}'".format(str)
    return str

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
        dependencies = depset(d["dependencies"]),
        platform = struct(
            arch = d["arch"],
            os_version = d["os_version"],
            platform = d["platform"],
        ),
        product = struct(
            type = d["product_type"],
        ),
        test_host = d["test_host"],
    )

# FIXME: Extract
def mock_xcode_target(
        *,
        id,
        arch,
        dependencies,
        os_version,
        platform,
        product_type,
        test_host = None):
    return struct(
        id = id,
        arch = arch,
        dependencies = dependencies,
        os_version = os_version,
        platform = platform,
        product_type = product_type,
        test_host = test_host,
    )

def _write_pbxproject_targets_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    args = []

    def _args_add_all(flag_or_values, values = None, *, map_each = None):
        if values != None:
            flag = flag_or_values
        else:
            flag = None
            values = flag_or_values

        if type(values) == "depset":
            values = values.to_list()

        if not values:
            return

        if flag:
            args.append(flag)

        if map_each:
            for value in values:
                mapped_value = map_each(value)
                if type(mapped_value) == "list":
                    args.extend(
                        [_quote_if_needed(str(v)) for v in mapped_value],
                    )
                elif mapped_value:
                    args.append(_quote_if_needed(str(mapped_value)))
        else:
            args.extend([_quote_if_needed(str(value)) for value in values])

    use_param_file_args = {}

    def _args_use_param_file(param_file):
        use_param_file_args["use_param_file"] = param_file

    set_param_file_format_args = {}

    def _args_set_param_file_format(format):
        set_param_file_format_args["format"] = format

    action_args = struct(
        add = lambda *x: args.extend(x),
        add_all = _args_add_all,
        use_param_file = _args_use_param_file,
        set_param_file_format = _args_set_param_file_format,
    )

    run_args = {}

    def _action_run(*, arguments, outputs, **_kwargs):
        run_args["arguments"] = arguments
        run_args["outputs"] = outputs

    declared_files = {}

    def _actions_declare_file(path):
        declared_files[path] = None
        return path

    actions = struct(
        args = lambda: action_args,
        declare_file = _actions_declare_file,
        run = _action_run,
    )

    expected_declared_files = {
        _TARGETS_DECLARED_FILE: None,
        _TARGET_ATTRIBUTES_DECLARED_FILE: None,
        _TARGET_DEPENDENCIES_DECLARED_FILE: None,
    }

    xcode_targets_by_label = _json_to_xcode_targets_by_label(
        ctx.attr.xcode_targets_by_label,
    )

    bucketed_labels = {}
    for label in xcode_targets_by_label:
        bucketed_labels.setdefault(hash(label.name) % 8, []).append(label)

    expected_consolidation_maps = {}
    for idx, labels in enumerate(bucketed_labels.values()):
        file = _consolidation_map_declared_file(idx)
        expected_consolidation_maps[file] = labels
        expected_declared_files[file] = None

    # Act

    (
        pbxproject_targets,
        pbxproject_target_attributes,
        pbxtargetdependencies,
        consolidation_maps,
    ) = pbxproj_partials.write_pbxproject_targets(
        actions = actions,
        apple_platform_to_platform_name = mock_apple_platform_to_platform_name,
        colorize = ctx.attr.colorize,
        generator_name = "a_generator_name",
        minimum_xcode_version = ctx.attr.minimum_xcode_version,
        tool = None,
        xcode_target_configurations = ctx.attr.xcode_target_configurations,
        xcode_targets_by_label = xcode_targets_by_label,
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_files,
        declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        "@%s",
        use_param_file_args["use_param_file"],
        "args.use_param_file",
    )

    asserts.equals(
        env,
        "multiline",
        set_param_file_format_args["format"],
        "args.param_file_format",
    )

    asserts.equals(
        env,
        [action_args],
        run_args["arguments"],
        "actions.run.arguments",
    )

    asserts.equals(
        env,
        ctx.attr.expected_args,
        args,
        "actions.run.arguments[0]",
    )

    asserts.equals(
        env,
        expected_declared_files.keys(),
        run_args["outputs"],
        "actions.run.outputs",
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
        _TARGET_DEPENDENCIES_DECLARED_FILE,
        pbxtargetdependencies,
        "pbxtargetdependencies",
    )

    asserts.equals(
        env,
        expected_consolidation_maps,
        consolidation_maps,
        "consolidation_maps",
    )

    return unittest.end(env)

write_pbxproject_targets_test = unittest.make(
    impl = _write_pbxproject_targets_test_impl,
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "minimum_xcode_version": attr.string(mandatory = True),
        "xcode_target_configurations": attr.string_list_dict(mandatory = True),
        "xcode_targets_by_label": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_pbxproject_targets_test_suite(name):
    """Test suite for `pbxproj_partials.write_pbxproject_targets`.

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
            xcode_target_configurations,
            xcode_targets_by_label,

            # Expected
            expected_args):
        test_names.append(name)
        write_pbxproject_targets_test(
            name = name,

            # Inputs
            colorize = colorize,
            minimum_xcode_version = minimum_xcode_version,
            xcode_target_configurations = xcode_target_configurations,
            xcode_targets_by_label = json.encode(xcode_targets_by_label),

            # Expected
            expected_args = expected_args,
        )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
        minimum_xcode_version = "14.3.1",
        xcode_target_configurations = {
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": ["Release"],
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3": ["Debug", "Release"],
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": ["Debug"],
        },
        xcode_targets_by_label = {
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle": {
                "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": mock_xcode_target(
                    id = "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                    dependencies = [
                        "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                    ],
                    arch = "arm64",
                    os_version = "16.2.1",
                    platform = "MACOS",
                    product_type = "com.apple.product-type.bundle.unit-test",
                    test_host = "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                ),
            },
            "//tools/generators/legacy:generator": {
                "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3": mock_xcode_target(
                    id = "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                    arch = "x86_64",
                    dependencies = [
                        "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                    ],
                    os_version = "12.0",
                    platform = "IOS_DEVICE",
                    product_type = "com.apple.product-type.tool",
                ),
            },
            "//tools/generators/legacy:generator.library": {
                "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": mock_xcode_target(
                    id = "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                    arch = "i386",
                    dependencies = [],
                    os_version = "9.1",
                    platform = "WATCHOS_SIMULATOR",
                    product_type = "com.apple.product-type.library.static",
                ),
            },
        },

        # Expected
        expected_args = [
            # targetsOutputPath
            _TARGETS_DECLARED_FILE,
            # targetAttributesOutputPath
            _TARGET_ATTRIBUTES_DECLARED_FILE,
            # targetDependenciesOutputPath
            _TARGET_DEPENDENCIES_DECLARED_FILE,
            # minimumXcodeVersion
            "14.3.1",
            # targetAndTestHosts
            "--target-and-test-hosts",
            "'//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3'",
            "'//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'",
            # consolidationMapOutputPaths
            "--consolidation-map-output-paths",
            _consolidation_map_declared_file(0),
            _consolidation_map_declared_file(1),
            # labelCounts
            "--label-counts",
            "2",
            "1",
            # labels
            "--labels",
            str(Label("//tools/generators/legacy/test:tests.__internal__.__test_bundle")),
            str(Label("//tools/generators/legacy:generator")),
            str(Label("//tools/generators/legacy:generator.library")),
            # targetCounts
            "--target-counts",
            "1",
            "1",
            "1",
            # targets
            "--targets",
            "'//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3'",
            "'//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'",
            "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'",
            # xcodeConfigurationCounts
            "--xcode-configuration-counts",
            "1",
            "2",
            "1",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
            "Release",
            "Debug",
            # productTypes
            "--product-types",
            "com.apple.product-type.bundle.unit-test",
            "com.apple.product-type.tool",
            "com.apple.product-type.library.static",
            # platforms
            "--platforms",
            "macosx",
            "iphoneos",
            "watchsimulator",
            # osVersions
            "--os-versions",
            "16.2.1",
            "12.0",
            "9.1",
            # archs
            "--archs",
            "arm64",
            "x86_64",
            "i386",
            # dependencyCounts
            "--dependency-counts",
            "1",
            "1",
            "0",
            # dependencies
            "--dependencies",
            "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2'",
            "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'",
            "--colorize",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

"""Tests for target id functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:target_id.bzl", "write_target_ids_list")

_DECLARED_OUTPUT_FILE = "_declared_output_file_"

def _write_target_ids_list_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    expected_output = _DECLARED_OUTPUT_FILE

    set_param_file_format_args = {}

    def _args_set_param_file_format(format):
        set_param_file_format_args["format"] = format

    args = []
    actions_args = struct(
        add_all = lambda x: args.extend(x),
        set_param_file_format = _args_set_param_file_format,
    )

    write_args = {}

    def _actions_write(write_output, args):
        write_args["output"] = write_output
        write_args["args"] = args

    actions = struct(
        args = lambda: actions_args,
        declare_file = lambda _: expected_output,
        write = _actions_write,
    )

    # Act

    output = write_target_ids_list(
        actions = actions,
        name = "a_generator_name",
        target_ids = ctx.attr.target_ids,
    )

    # Assert

    asserts.equals(
        env,
        "multiline",
        set_param_file_format_args["format"],
        "args.param_file_format",
    )

    asserts.equals(
        env,
        expected_output,
        write_args["output"],
        "actions.write.output",
    )

    asserts.equals(
        env,
        actions_args,
        write_args["args"],
        "actions.write.args",
    )

    asserts.equals(
        env,
        ctx.attr.expected_args,
        args,
        "actions.write.args content",
    )

    asserts.equals(
        env,
        expected_output,
        output,
        "output",
    )

    return unittest.end(env)

write_target_ids_list_test = unittest.make(
    impl = _write_target_ids_list_test_impl,
    attrs = {
        # Inputs
        "target_ids": attr.string_list(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_target_ids_list_test_suite(name):
    """Test suite for `write_target_ids_list`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            target_ids,
            expected_args):
        test_names.append(name)
        write_target_ids_list_test(
            name = name,
            target_ids = target_ids,
            expected_args = expected_args,
        )

    _add_test(
        name = "{}_sorted".format(name),
        target_ids = [
            "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParser macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParser macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParserToolInfo macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParserToolInfo macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
        ],
        expected_args = [
            "@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParser macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParser macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParserToolInfo macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_argument_parser//:ArgumentParserToolInfo macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
            "@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636",
            "@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

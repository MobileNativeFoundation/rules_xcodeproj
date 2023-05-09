"""Tests for target id functions."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _write_target_ids_list_test_impl(ctx):
    env = analysistest.begin(ctx)

    xcodeproj = analysistest.target_under_test(env)

    expected_action = "action 'Writing file {package}/{name}_target_ids'".format(
        package = xcodeproj.label.package,
        name = xcodeproj.label.name,
    )

    found_action = False
    content = None
    for action in xcodeproj.actions:
        if action.mnemonic != "FileWrite":
            continue
        if str(action) == expected_action:
            found_action = True
            content = action.content

    asserts.true(
        env,
        found_action,
        "Did not find an action named \"{}\"".format(expected_action),
    )

    if found_action:
        asserts.equals(
            env,
            ctx.attr.expected_content,
            content,
            "content",
        )

    return analysistest.end(env)

write_target_ids_list_test = analysistest.make(
    impl = _write_target_ids_list_test_impl,
    attrs = {
        "expected_content": attr.string(mandatory = True),
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
            target_under_test,
            expected_content):
        test_names.append(name)
        write_target_ids_list_test(
            name = name,
            expected_content = expected_content,
            target_under_test = target_under_test,
            # TODO: Remove "manual" once we remove Bazel 5 and non-bzlmod tests
            tags = ["manual"],
        )

    _add_test(
        name = "{}_generator_bwb".format(name),
        target_under_test = "//test/fixtures/generator/generated/xcodeproj_bwb",
        expected_content = """\
@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
""",
    )

    _add_test(
        name = "{}_generator_bwx".format(name),
        target_under_test = "//test/fixtures/generator/generated/xcodeproj_bwx",
        expected_content = """\
@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy:generator applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@//tools/swiftc_stub:swiftc applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter//:JJLISO8601DateFormatter macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily//:ZippyJSONCFamily macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_tadija_aexml//:AEXML macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-c233c8334636
@@_main~non_module_deps~com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-opt-ST-5e821ae22d1b
""",
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
        # TODO: Remove "manual" once we remove Bazel 5 and non-bzlmod tests
        tags = ["manual"],
    )

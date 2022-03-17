"""Tests for the `xcodeproj` rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj:xcodeproj.bzl", "XcodeProjOutputInfo")
load(":fixtures.bzl", "fixtures_transition")

def _xcodeproj_test_impl(ctx):
    validator = ctx.actions.declare_file(
        "{}-spec-validator.sh".format(ctx.label.name),
    )

    xcodeproj_outputs = ctx.attr.target_under_test[0][XcodeProjOutputInfo]
    spec = xcodeproj_outputs.spec
    expected_spec = ctx.file.expected_spec
    xcodeproj = xcodeproj_outputs.xcodeproj
    expected_xcodeproj = ctx.files.expected_xcodeproj

    expected_xcodeproj_path = expected_xcodeproj[0].short_path
    suffix_len = len(expected_xcodeproj_path.split(".xcodeproj/")[1]) + 1
    expected_xcodeproj_path = expected_xcodeproj_path[:-suffix_len]

    ctx.actions.expand_template(
        template = ctx.file._validator_template,
        output = validator,
        is_executable = True,
        substitutions = {
            "%expected_spec%": expected_spec.short_path,
            "%expected_xcodeproj%": expected_xcodeproj_path,
            "%spec%": spec.short_path,
            "%xcodeproj%": xcodeproj.short_path,
        },
    )

    return [
        DefaultInfo(
            executable = validator,
            runfiles = ctx.runfiles(
                files = [spec, expected_spec, xcodeproj] + expected_xcodeproj,
            ),
        ),
    ]

xcodeproj_test = rule(
    implementation = _xcodeproj_test_impl,
    attrs = {
        "expected_spec": attr.label(mandatory = True, allow_single_file = True),
        "expected_xcodeproj": attr.label(mandatory = True, allow_files = True),
        "target_under_test": attr.label(
            cfg = fixtures_transition,
            mandatory = True,
            providers = [XcodeProjOutputInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_validator_template": attr.label(
            allow_single_file = True,
            default = ":validator.template.sh",
        ),
    },
    test = True,
)

def _fixture_test(
        target_under_test,
        basename = None,
        expected_spec = None,
        expected_xcodeproj = None):
    if target_under_test == None:
        fail("Need to specify the target under test.")
    if target_under_test.find(":") < 0:
        target_under_test += ":xcodeproj"

    test_target_parts = target_under_test.split(":")
    pkg = test_target_parts[0]

    if basename == None:
        basename = paths.basename(pkg)
    if expected_spec == None:
        expected_spec = "{pkg}:spec.json".format(pkg = pkg)
    if expected_xcodeproj == None:
        expected_xcodeproj = "{pkg}:xcodeproj_output".format(pkg = pkg)

    return struct(
        basename = basename,
        target_under_test = target_under_test,
        expected_spec = expected_spec,
        expected_xcodeproj = expected_xcodeproj,
    )

def xcodeproj_test_suite(name, test_pkgs = []):
    """Test suite for `xcodeproj`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []
    all_test_structs = []

    for pkg in test_pkgs:
        all_test_structs.append(_fixture_test(pkg))

    for test_struct in all_test_structs:
        test_name = "{suite_name}_{test_name}".format(
            suite_name = name,
            test_name = test_struct.basename,
        )
        test_names.append(test_name)
        xcodeproj_test(
            name = test_name,
            target_under_test = test_struct.target_under_test,
            expected_spec = test_struct.expected_spec,
            expected_xcodeproj = test_struct.expected_xcodeproj,
        )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )

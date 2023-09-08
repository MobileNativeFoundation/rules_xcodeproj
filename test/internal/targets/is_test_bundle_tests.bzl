"""Tests for targets.is_test_bundle"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "IosXcTestBundleInfo",
    "MacosXcTestBundleInfo",
)

# buildifier: disable=bzl-visibility
load(
    "@build_bazel_rules_apple//apple/internal:providers.bzl",
    "new_iosxctestbundleinfo",
    "new_macosxctestbundleinfo",
)

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:targets.bzl", "targets")

def _is_test_bundle_for_ios_test_bundle_test(ctx):
    env = unittest.begin(ctx)

    target = {IosXcTestBundleInfo: new_iosxctestbundleinfo()}
    dep = {IosXcTestBundleInfo: new_iosxctestbundleinfo()}
    deps = [dep]

    actual = targets.is_test_bundle(target, deps)
    asserts.true(env, actual)

    return unittest.end(env)

is_test_bundle_for_ios_test_bundle_test = unittest.make(_is_test_bundle_for_ios_test_bundle_test)

def _is_test_bundle_for_macos_test_bundel_test(ctx):
    env = unittest.begin(ctx)

    target = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    dep = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    deps = [dep]

    actual = targets.is_test_bundle(target, deps)
    asserts.true(env, actual)

    return unittest.end(env)

is_test_bundle_for_macos_test_bundel_test = unittest.make(_is_test_bundle_for_macos_test_bundel_test)

def _is_test_bundle_has_provider_but_not_dep_test(ctx):
    env = unittest.begin(ctx)

    target = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    dep = {}
    deps = [dep]

    actual = targets.is_test_bundle(target, deps)
    asserts.false(env, actual)

    return unittest.end(env)

is_test_bundle_has_provider_but_not_dep_test = unittest.make(_is_test_bundle_has_provider_but_not_dep_test)

def _is_test_bundle_does_not_have_provider_test(ctx):
    env = unittest.begin(ctx)

    target = {}
    dep = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    deps = [dep]

    actual = targets.is_test_bundle(target, deps)
    asserts.false(env, actual)

    return unittest.end(env)

is_test_bundle_does_not_have_provider_test = unittest.make(_is_test_bundle_does_not_have_provider_test)

def _is_test_bundle_more_than_one_dep_test(ctx):
    env = unittest.begin(ctx)

    target = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    dep = {MacosXcTestBundleInfo: new_macosxctestbundleinfo()}
    deps = [dep, dep]

    actual = targets.is_test_bundle(target, deps)
    asserts.false(env, actual)

    return unittest.end(env)

is_test_bundle_more_than_one_dep_test = unittest.make(_is_test_bundle_more_than_one_dep_test)

def is_test_bundle_test_suite(name):
    return unittest.suite(
        name,
        is_test_bundle_for_ios_test_bundle_test,
        is_test_bundle_for_macos_test_bundel_test,
        is_test_bundle_has_provider_but_not_dep_test,
        is_test_bundle_does_not_have_provider_test,
        is_test_bundle_more_than_one_dep_test,
    )

"""Tests for `info_plists.get_file()`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:info_plists.bzl", "info_plists")

# NOTE: It is not possible to create a dict with a key of apple_common.Objc.
# So, we cannot test extracting of info plist via an ObjcProvider via get_file.
# See the get_file_from_objc_provider_tests.bzl for those tests.

# NOTE: It is not possible to test a target that does not have a provider,
# because it is not possible to create a Target and set providers. If you pass
# an empty dict, the `get_file` will fail because apple_common.Objc is not
# hashable.

def _get_file_from_bundle_info_test(ctx):
    env = unittest.begin(ctx)

    info_plist_file = ctx.actions.declare_file("Info.plist")
    ctx.actions.write(info_plist_file, content = "")

    bundle_info = AppleBundleInfo(infoplist = info_plist_file)
    target = {AppleBundleInfo: bundle_info}

    actual = info_plists.get_file(target)
    asserts.equals(env, info_plist_file, actual)

    return unittest.end(env)

get_file_from_bundle_info_test = unittest.make(_get_file_from_bundle_info_test)

def get_file_test_suite(name):
    return unittest.suite(
        name,
        get_file_from_bundle_info_test,
    )

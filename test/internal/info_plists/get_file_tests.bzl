load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:info_plists.bzl", "info_plists")

def _get_file_from_bundle_info_test(ctx):
    env = unittest.begin(ctx)

    info_plist_file = struct(_id = "info_plist")

    # TODO(chuck): Replace with real AppleBundleInfo?
    bundle_info = struct(infoplist = info_plist_file)
    target = {AppleBundleInfo: bundle_info}

    actual = info_plists.get_file(target)
    asserts.equals(env, info_plist_file, actual)

    return unittest.end(env)

get_file_from_bundle_info_test = unittest.make(_get_file_from_bundle_info_test)

def _get_file_from_objc_provider_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

get_file_from_objc_provider_test = unittest.make(_get_file_from_objc_provider_test)

def _get_file_without_info_list_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

get_file_without_info_list_test = unittest.make(_get_file_without_info_list_test)

def get_file_test_suite():
    return unittest.suite(
        "get_file_tests",
        get_file_from_bundle_info_test,
        get_file_from_objc_provider_test,
        get_file_without_info_list_test,
    )

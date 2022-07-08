"""Tests for `launchd_plists.get_file_from_objc_provider`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:launchd_plists.bzl", "launchd_plists")

def _get_file_from_objc_provider_test(ctx):
    env = unittest.begin(ctx)

    launchd_plist_file = ctx.actions.declare_file("Launchd.plist")
    ctx.actions.write(launchd_plist_file, content = "")
    launchd_plist_path = launchd_plist_file.path

    linkopt_list = [
        "-Wl,-sectcreate,__TEXT,__launchd_plist,{}".format(launchd_plist_path),
    ]
    link_inputs_list = [launchd_plist_file]
    linkopt_depset = depset(linkopt_list)
    link_inputs_depset = depset(link_inputs_list)

    objc_prov = apple_common.new_objc_provider(
        linkopt = linkopt_depset,
        link_inputs = link_inputs_depset,
    )

    actual = launchd_plists.get_file_from_objc_provider(objc_prov)
    asserts.equals(env, launchd_plist_file, actual)

    return unittest.end(env)

get_file_from_objc_provider_test = unittest.make(
    _get_file_from_objc_provider_test,
)

def get_file_from_objc_provider_test_suite(name):
    return unittest.suite(
        name,
        get_file_from_objc_provider_test,
    )

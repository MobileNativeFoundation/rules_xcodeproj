"""Tests for `provisioning_profiles.process_attr`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:provisioning_profiles.bzl",
    "XcodeProjProvisioningProfileInfo",
    "provisioning_profiles",
)

def _certificate_name(objc_fragment, **kwargs):
    profile_info = XcodeProjProvisioningProfileInfo(
        is_xcode_managed = False,
        profile_name = "Profile",
        team_id = "TEAMID",
    )
    return provisioning_profiles.process_attr(
        automatic_target_info = struct(provisioning_profile = "provisioning_profile"),
        objc_fragment = objc_fragment,
        rule_attr = struct(provisioning_profile = {
            XcodeProjProvisioningProfileInfo: profile_info,
        }),
        **kwargs
    ).certificate_name

def _native_certificate_test(ctx):
    env = unittest.begin(ctx)
    actual = _certificate_name(struct(signing_certificate_name = "Native Certificate"))
    asserts.equals(env, "Native Certificate", actual)
    return unittest.end(env)

def _empty_setting_falls_back_to_native_certificate_test(ctx):
    env = unittest.begin(ctx)
    actual = _certificate_name(
        struct(signing_certificate_name = "Native Certificate"),
        signing_certificate_name = "",
    )
    asserts.equals(env, "Native Certificate", actual)
    return unittest.end(env)

def _setting_overrides_native_certificate_test(ctx):
    env = unittest.begin(ctx)
    actual = _certificate_name(
        struct(signing_certificate_name = "Native Certificate"),
        signing_certificate_name = "Setting Certificate",
    )
    asserts.equals(env, "Setting Certificate", actual)
    return unittest.end(env)

def _setting_without_native_field_test(ctx):
    env = unittest.begin(ctx)
    actual = _certificate_name(
        struct(),
        signing_certificate_name = "Setting Certificate",
    )
    asserts.equals(env, "Setting Certificate", actual)
    return unittest.end(env)

def _unset_certificate_without_native_field_test(ctx):
    env = unittest.begin(ctx)
    actual = _certificate_name(struct(), signing_certificate_name = "")
    asserts.equals(env, None, actual)
    return unittest.end(env)

native_certificate_test = unittest.make(_native_certificate_test)
empty_setting_falls_back_to_native_certificate_test = unittest.make(_empty_setting_falls_back_to_native_certificate_test)
setting_overrides_native_certificate_test = unittest.make(_setting_overrides_native_certificate_test)
setting_without_native_field_test = unittest.make(_setting_without_native_field_test)
unset_certificate_without_native_field_test = unittest.make(_unset_certificate_without_native_field_test)

def process_attr_test_suite(name):
    return unittest.suite(
        name,
        native_certificate_test,
        empty_setting_falls_back_to_native_certificate_test,
        setting_overrides_native_certificate_test,
        setting_without_native_field_test,
        unset_certificate_without_native_field_test,
    )

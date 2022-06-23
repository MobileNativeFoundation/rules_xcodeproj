"""API to process provisioning profile information for `Target`s."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleProvisioningProfileInfo",
)
load(":collections.bzl", "set_if_true")
load(":providers.bzl", "XcodeProjProvisioningProfileInfo")

def _process_attr(*, ctx, automatic_target_info, build_settings):
    attr = automatic_target_info.provisioning_profile
    if not attr:
        return

    provisioning_profile_target = getattr(ctx.rule.attr, attr)
    if (provisioning_profile_target and
        XcodeProjProvisioningProfileInfo in provisioning_profile_target):
        info = provisioning_profile_target[XcodeProjProvisioningProfileInfo]
        is_xcode_managed = info.is_xcode_managed
        team_id = info.team_id

        # We need to not set the profile name if the profile is managed by Xcode
        name = info.profile_name if not is_xcode_managed else None
    else:
        is_xcode_managed = False
        team_id = None
        name = None

    set_if_true(
        build_settings,
        "DEVELOPMENT_TEAM",
        team_id,
    )
    set_if_true(
        build_settings,
        "PROVISIONING_PROFILE_SPECIFIER",
        name,
    )
    build_settings["CODE_SIGN_STYLE"] = (
        "Automatic" if is_xcode_managed else "Manual"
    )
    set_if_true(
        build_settings,
        "CODE_SIGN_IDENTITY",
        ctx.fragments.objc.signing_certificate_name,
    )

def _create_profileinfo(
        *,
        target,
        is_xcode_managed = False,
        profile_name = None,
        team_id = None):
    if target and AppleProvisioningProfileInfo in target:
        info = target[AppleProvisioningProfileInfo]
        profile_name = profile_name or info.profile_name
        team_id = team_id or info.team_id

    return XcodeProjProvisioningProfileInfo(
        is_xcode_managed = is_xcode_managed,
        profile_name = profile_name,
        team_id = team_id,
    )

provisioning_profiles = struct(
    create_profileinfo = _create_profileinfo,
    process_attr = _process_attr,
)

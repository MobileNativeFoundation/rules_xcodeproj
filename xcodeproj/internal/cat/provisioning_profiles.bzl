"""API to process provisioning profile information for `Target`s."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleProvisioningProfileInfo",
)
load("//xcodeproj/internal:providers.bzl", "XcodeProjProvisioningProfileInfo")

def _process_attr(*, automatic_target_info, objc_fragment, rule_attr):
    attr = automatic_target_info.provisioning_profile
    if attr and hasattr(rule_attr, attr):
        provisioning_profile_target = getattr(rule_attr, attr, None)
        is_missing_profile = not provisioning_profile_target
    else:
        is_missing_profile = False
        provisioning_profile_target = None

    if (not provisioning_profile_target or
        XcodeProjProvisioningProfileInfo not in provisioning_profile_target):
        return struct(
            certificate_name = None,
            is_missing_profile = is_missing_profile,
            is_xcode_managed = False,
            name = None,
            team_id = None,
        )

    info = provisioning_profile_target[XcodeProjProvisioningProfileInfo]

    is_xcode_managed = info.is_xcode_managed

    return struct(
        certificate_name = objc_fragment.signing_certificate_name,
        is_missing_profile = is_missing_profile,
        is_xcode_managed = is_xcode_managed,
        # We need to not set the profile name if the profile is managed by Xcode
        name = info.profile_name if not is_xcode_managed else None,
        team_id = info.team_id,
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

"""API to process provisioning profile information for `Target`s."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleProvisioningProfileInfo",
)
load(":collections.bzl", "set_if_true")

def _legacy_process_attr(
        *,
        automatic_target_info,
        build_settings,
        objc_fragment,
        rule_attr):
    attr = automatic_target_info.provisioning_profile
    if not attr or not hasattr(rule_attr, attr):
        return

    provisioning_profile_target = getattr(rule_attr, attr)
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
        objc_fragment.signing_certificate_name,
    )

# Provider

XcodeProjProvisioningProfileInfo = provider(
    "Provides information about a provisioning profile.",
    fields = {
        "is_xcode_managed": "Whether the profile is managed by Xcode.",
        "profile_name": """\
The profile name (e.g. "iOS Team Provisioning Profile: com.example.app").
""",
        "team_id": """\
The Team ID the profile is associated with (e.g. "V82V4GQZXM").
""",
    },
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
    create_provider = _create_profileinfo,
    legacy_process_attr = _legacy_process_attr,
)

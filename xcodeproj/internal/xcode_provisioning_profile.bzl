"""Implementation of the `xcode_provisioning_profile` rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":provisioning_profiles.bzl", "provisioning_profiles")

# Utility

def _requires_team_id(ctx):
    """Determines whether a team id is needed.

    The team id can come from `ctx.attr.team_id` or
    `ctx.attr.provisioning_file[AppleProvisioningProfileInfo].team_id`.

    Args:
        ctx: The aspect context.

    Returns:
        `True` if a team ide is needed, `False` otherwise.
    """
    return ctx.attr._build_mode[BuildSettingInfo].value == "xcode"

# API

def _xcode_provisioning_profile_impl(ctx):
    target = ctx.attr.provisioning_profile

    info = provisioning_profiles.create_profileinfo(
        target = target,
        is_xcode_managed = ctx.attr.managed_by_xcode,
        profile_name = ctx.attr.profile_name,
        team_id = ctx.attr.team_id,
    )
    if not info.team_id and _requires_team_id(ctx):
        fail("""\
`provisioning_profile[AppleProvisioningProfileInfo].team_id` or `team_id` must \
be set if `build_mode = \"xcode\"`.
""")

    return [
        DefaultInfo(files = target.files),
        info,
    ]

xcode_provisioning_profile = rule(
    implementation = _xcode_provisioning_profile_impl,
    attrs = {
        "managed_by_xcode": attr.bool(
            mandatory = True,
        ),
        "profile_name": attr.string(),
        "provisioning_profile": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "team_id": attr.string(),
        "_build_mode": attr.label(
            default = Label("//xcodeproj/internal:build_mode"),
            providers = [BuildSettingInfo],
        ),
    },
)

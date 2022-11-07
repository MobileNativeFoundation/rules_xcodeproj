"""Implementation of the `xcode_provisioning_profile` rule."""

load(":provisioning_profiles.bzl", "provisioning_profiles")

# API

def _xcode_provisioning_profile_impl(ctx):
    target = ctx.attr.provisioning_profile

    info = provisioning_profiles.create_profileinfo(
        target = target,
        is_xcode_managed = ctx.attr.managed_by_xcode,
        profile_name = ctx.attr.profile_name,
        team_id = ctx.attr.team_id,
    )
    if not info.team_id:
        fail("""\
`provisioning_profile[AppleProvisioningProfileInfo].team_id` or `team_id` must \
be set.
""")

    return [
        DefaultInfo(files = target.files),
        info,
    ]

xcode_provisioning_profile = rule(
    doc = """\
This rule declares a target that you can pass to the `provisioning_profile`
attribute of rules that require it. It wraps another provisioning profile
target, either a `File` or a rule like rules_apple's
`local_provisioning_profile`, and allows specifying additional information to
adjust Xcode related build settings related to code signing.

If you are already using `local_provisioning_profile`, or another rule that
returns the `AppleProvisioningProfileInfo` provider, you don't need to use this
rule, unless you want to enable Xcode's "Automatic Code Signing" feature. If you
are using a `File`, then this rule is needed in order to set the
`DEVELOPER_TEAM` build setting via the `team_id` attribute.

**EXAMPLE**

```starlark
ios_application(
   ...
   provisioning_profile = ":xcode_profile",
   ...
)

xcode_provisioning_profile(
   name = "xcode_profile",
   managed_by_xcode = True,
   provisioning_profile = ":provisioning_profile",
)

local_provisioning_profile(
    name = "provisioning_profile",
    profile_name = "iOS Team Provisioning Profile: com.example.app",
    team_id = "A12B3CDEFG",
)
```
""",
    implementation = _xcode_provisioning_profile_impl,
    attrs = {
        "managed_by_xcode": attr.bool(
            doc = """\
Whether the provisioning profile is managed by Xcode. If `True`, "Automatic Code
Signing" will be enabled in Xcode, and the profile name will be ignored. Xcode
will add devices to profiles automatically via the currently logged in Apple
Developer Account, and otherwise fully manage the profile. If `False`, "Manual
Code Signing" will be enabled in Xcode, and the profile name will be used to
determine which profile to use.

If `xcodeproj.build_mode != "xcode"`, then Xcode will still manage the profile
when this is `True`, but otherwise won't use it to actually sign the binary.
Instead Bazel will perform the code signing with the file set to
`provisioning_profile`. Using rules_apple's `local_provisioning_profile` as the
target set to `provisioning_profile` will then allow Bazel to code sign with the
Xcode managed profile.
""",
            mandatory = True,
        ),
        "profile_name": attr.string(
            doc = """\
When `managed_by_xcode` is `False`, the `PROVISIONING_PROFILE_SPECIFIER` Xcode
build setting will be set to this value. If this is `None` (the default), and
`provisioning_profile` returns the `AppleProvisioningProfileInfo` provider (as
`local_provisioning_profile` does), then
`AppleProvisioningProfileInfo.profile_name` will be used instead.
""",
        ),
        "provisioning_profile": attr.label(
            doc = """\
The `File` that Bazel will use when code signing. If the target returns the
`AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does),
then it will provide default values for `profile_name` and `team_id`.

When `xcodeproj.build_mode = "xcode"`, the actual file isn't used directly by
Xcode, but in order to satisfy Bazel constraints this can't be `None`.
""",
            allow_single_file = True,
            mandatory = True,
        ),
        "team_id": attr.string(
            doc = """\
The `DEVELOPER_TEAM` Xcode build setting will be set to this value. If this is
`None` (the default), and `provisioning_profile` returns the
`AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does),
then `AppleProvisioningProfileInfo.team_id` will be used instead.
""",
        ),
    },
)

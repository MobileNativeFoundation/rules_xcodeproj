"""Providers that are used throughout the rules."""

XcodeProjOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj` rule.",
    fields = {
        "installer": "The xcodeproj installer.",
        "project_name": "The installed project name.",
    },
)

XcodeProjRunnerOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj_runner` rule.",
    fields = {
        "project_name": "The installed project name.",
        "runner": "The xcodeproj runner.",
    },
)

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

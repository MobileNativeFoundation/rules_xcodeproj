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

ToolchainInfo = provider(
    doc = "Information about the custom toolchain",
    fields = {
        "identifier": "The bundle identifier of the toolchain",
        "name": "The full name of the toolchain",
    },
)

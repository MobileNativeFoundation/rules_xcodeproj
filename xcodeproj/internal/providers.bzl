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

XcodeProjSynchronizedFoldersHintInfo = provider(
    doc = """\
Provides the folders of a target to show as synchronized folders during project
generation.
""",
    fields = {
        "folders": """\
A `tuple` of folder paths, relative to the package of the target that the hint
is attached to.
""",
    },
)

XcodeProjExtraFilesHintInfo = provider(
    doc = "Provides a list of extra files to include during project generation",
    fields = {
        "files": "List of files to include in the extra files.",
    },
)

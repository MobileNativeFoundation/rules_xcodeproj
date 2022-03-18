load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "update_fixtures",
    "xcodeproj_fixture",
)
load("//:xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj_fixture(
    targets = XCODEPROJ_TARGETS,
)

update_fixtures(
    name = "update",
    tags = ["manual"],
    targets = [
        ":xcodeproj",
    ],
)

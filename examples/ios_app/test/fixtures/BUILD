load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:testing.bzl",
    "update_fixtures",
    "xcodeproj_fixture",
    "xcodeproj_test_suite",
    "xcodeproj_tests",
)
load("//:xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj_fixture(
    name = "fixture",
    workspace_name = "ios_app",
    targets = XCODEPROJ_TARGETS,
)

update_fixtures(
    name = "update",
    tags = ["manual"],
    targets = [
        ":fixture",
    ],
)

xcodeproj_test_suite(
    name = "xcodeproj",
    fixture_tests = [
        xcodeproj_tests.from_fixture("//test/fixtures:fixture"),
    ],
)

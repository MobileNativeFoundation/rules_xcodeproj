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
    targets = XCODEPROJ_TARGETS,
    workspace_name = "ios_app",
)

update_fixtures(
    name = "update",
    tags = ["manual"],
    targets = [
        ":fixture_bwb",
        ":fixture_bwx",
    ],
)

xcodeproj_test_suite(
    name = "xcodeproj",
    fixture_tests = [
        xcodeproj_tests.from_fixture("//test/fixtures:fixture_bwb"),
        xcodeproj_tests.from_fixture("//test/fixtures:fixture_bwx"),
    ],
)

"""Testing related rules and macros."""

load(
    "//xcodeproj/internal:fixtures.bzl",
    _update_fixtures = "update_fixtures",
    _xcodeproj_fixture = "xcodeproj_fixture",
)
load(
    "//xcodeproj/internal:xcodeproj_tests.bzl",
    _xcodeproj_test = "xcodeproj_test",
    _xcodeproj_test_suite = "xcodeproj_test_suite",
    _xcodeproj_tests = "xcodeproj_tests",
)

update_fixtures = _update_fixtures
xcodeproj_fixture = _xcodeproj_fixture
xcodeproj_test_suite = _xcodeproj_test_suite
xcodeproj_test = _xcodeproj_test
xcodeproj_tests = _xcodeproj_tests

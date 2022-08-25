"""Testing related rules and macros."""

load(
    "//xcodeproj/internal:fixtures.bzl",
    _update_fixtures = "update_fixtures",
    _validate_fixtures = "validate_fixtures",
    _xcodeproj_fixture = "xcodeproj_fixture",
)

# Re-exporting fixture rules.
update_fixtures = _update_fixtures
validate_fixtures = _validate_fixtures
xcodeproj_fixture = _xcodeproj_fixture

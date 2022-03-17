"""Public Definitions"""

load(
    "//xcodeproj/internal:fixtures.bzl",
    _update_fixtures = "update_fixtures",
    _xcodeproj_fixture = "xcodeproj_fixture",
)

xcodeproj_fixture = _xcodeproj_fixture
update_fixtures = _update_fixtures

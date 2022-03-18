"""Constants for fixture declarations."""

FIXTURE_BASENAMES = [
    "cc",
    "command_line",
    "generator",
    "ios_app",
]

_FIXTURE_PACKAGES = ["//test/fixtures/{}".format(b) for b in FIXTURE_BASENAMES]

FIXTURE_TARGETS = ["{}:xcodeproj".format(p) for p in _FIXTURE_PACKAGES]

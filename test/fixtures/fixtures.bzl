"""Constants for Fixture Declarations."""

FIXTURE_BASENAMES = [
    "cc",
    "command_line",
    "generator",
    "ios_app",
]

FIXTURE_PACKAGES = ["//test/fixtures/{}".format(b) for b in FIXTURE_BASENAMES]

FIXTURE_TARGETS = ["{}:xcodeproj".format(p) for p in FIXTURE_PACKAGES]

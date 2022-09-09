"""Constants for fixture declarations."""

_FIXTURE_BASENAMES = [
    "generator",
]

_FIXTURE_SUFFIXES = ["bwx", "bwb"]

_FIXTURE_PACKAGES = ["//test/fixtures/{}".format(b) for b in _FIXTURE_BASENAMES]

FIXTURE_TARGETS = [
    "{}:xcodeproj_{}".format(package, suffix)
    for package in _FIXTURE_PACKAGES
    for suffix in _FIXTURE_SUFFIXES
]

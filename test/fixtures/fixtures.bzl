"""Constants for fixture declarations."""

load("@bazel_features//:features.bzl", "bazel_features")

_FIXTURE_BASENAMES = [
    "generator",
]

FIXTURE_MODE_AND_SUFFIXES = (
    [("bazel", "bwb")] if bazel_features.cc.objc_linking_info_migrated else [
        ("xcode", "bwx"),
        ("bazel", "bwb"),
    ]
)

_FIXTURE_PACKAGES = ["//test/fixtures/{}".format(b) for b in _FIXTURE_BASENAMES]

FIXTURE_TARGETS = [
    "{}:xcodeproj_{}".format(package, suffix)
    for package in _FIXTURE_PACKAGES
    for _, suffix in FIXTURE_MODE_AND_SUFFIXES
]

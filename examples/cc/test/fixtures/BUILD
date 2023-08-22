load("@bazel_features//:features.bzl", "bazel_features")
load(
    "@rules_xcodeproj//xcodeproj:testing.bzl",
    "update_fixtures",
    "validate_fixtures",
    "xcodeproj_fixture",
)
load("//:xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

_FIXTURE_MODE_AND_SUFFIXES = (
    [("bazel", "bwb")] if bazel_features.cc.objc_linking_info_migrated else [
        ("xcode", "bwx"),
        ("bazel", "bwb"),
    ]
)

xcodeproj_fixture(
    modes_and_suffixes = _FIXTURE_MODE_AND_SUFFIXES,
    top_level_targets = XCODEPROJ_TARGETS,
)

_FIXTURES = [
    ":xcodeproj_{}".format(suffix)
    for _, suffix in _FIXTURE_MODE_AND_SUFFIXES
]

update_fixtures(
    name = "update",
    tags = ["manual"],
    targets = _FIXTURES,
)

validate_fixtures(
    name = "validate",
    tags = ["manual"],
    targets = _FIXTURES,
)

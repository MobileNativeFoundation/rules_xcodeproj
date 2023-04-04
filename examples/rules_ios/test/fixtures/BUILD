load(
    "@rules_xcodeproj//xcodeproj:testing.bzl",
    "update_fixtures",
    "validate_fixtures",
    "xcodeproj_fixture",
)
load(
    "//:xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
)

xcodeproj_fixture(
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    top_level_targets = XCODEPROJ_TARGETS,
)

_FIXTURES = [
    ":xcodeproj_bwb",
    # Disabled since VFS is enabled by default for 'rules_ios' examples.
    # ":xcodeproj_bwx",
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

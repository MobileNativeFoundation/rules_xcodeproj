load(
    "@rules_xcodeproj//xcodeproj:testing.bzl",
    "update_fixtures",
    "validate_fixtures",
    "xcodeproj_fixture",
)
load(
    "//:xcodeproj_targets.bzl",
    "ASSOCIATED_EXTRA_FILES",
    "BAZEL_ENV",
    "CONFIG",
    "DEFAULT_XCODE_CONFIGURATION",
    "EXTRA_FILES",
    "FAIL_FOR_INVALID_EXTRA_FILES_TARGETS",
    "PRE_BUILD",
    "PROJECT_OPTIONS",
    "SCHEME_AUTOGENERATION_MODE",
    "UNFOCUSED_TARGETS",
    "XCODEPROJ_TARGETS",
    "XCODE_CONFIGURATIONS",
    "get_xcode_schemes",
)

xcodeproj_fixture(
    associated_extra_files = ASSOCIATED_EXTRA_FILES,
    bazel_env = BAZEL_ENV,
    config = CONFIG,
    default_xcode_configuration = DEFAULT_XCODE_CONFIGURATION,
    extra_files = EXTRA_FILES,
    fail_for_invalid_extra_files_targets = FAIL_FOR_INVALID_EXTRA_FILES_TARGETS,
    pre_build = PRE_BUILD,
    project_options = PROJECT_OPTIONS,
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    top_level_targets = XCODEPROJ_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
    xcode_configurations = XCODE_CONFIGURATIONS,
)

_FIXTURES = [
    ":xcodeproj_bwb",
    ":xcodeproj_bwx",
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

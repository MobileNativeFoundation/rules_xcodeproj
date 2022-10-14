load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)
load(
    ":xcodeproj_targets.bzl",
    "ASSOCIATED_EXTRA_FILES",
    "CONFIG",
    "EXTRA_FILES",
    "UNFOCUSED_TARGETS",
    "XCODEPROJ_TARGETS",
)

exports_files(["README.md"])

xcodeproj(
    name = "xcodeproj",
    associated_extra_files = ASSOCIATED_EXTRA_FILES,
    build_mode = "xcode",
    config = CONFIG,
    extra_files = EXTRA_FILES,
    project_name = "Integration",
    schemes = [
        xcode_schemes.scheme(
            name = "iOSAppUnitTests_Scheme",
            test_action = xcode_schemes.test_action(
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEME": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                ],
            ),
        ),
    ],
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
)

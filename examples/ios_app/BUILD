load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcode_schemes", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "iOS App",
    # TODO(chuck): REVERT ME!
    schemes = [
        xcode_schemes.scheme(
            name = "Chuck Scheme",
            test_action = xcode_schemes.test_action([
                "//ExampleTests:ExampleTests.__internal__.__test_bundle",
            ]),
        ),
    ],
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)

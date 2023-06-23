load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
    "get_xcode_schemes",
)

exports_files(["README.md"])

[
    xcodeproj(
        name = "xcodeproj-cat" if use_experimental_incremental else "xcodeproj",
        build_mode = "bazel",
        project_name = "rules_ios_cat" if use_experimental_incremental else "rules_ios",
        scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
        schemes = get_xcode_schemes(),
        tags = ["manual"],
        top_level_targets = XCODEPROJ_TARGETS,
        use_experimental_incremental = use_experimental_incremental,
    )
    for use_experimental_incremental in [
        True,
        False,
    ]
]

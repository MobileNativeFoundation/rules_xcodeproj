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
        name = "xcodeproj-cat" if generation_mode == "incremental" else "xcodeproj",
        build_mode = "bazel",
        generation_mode = generation_mode,
        project_name = "rules_ios_cat" if generation_mode == "incremental" else "rules_ios",
        scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
        schemes = get_xcode_schemes(),
        tags = ["manual"],
        top_level_targets = XCODEPROJ_TARGETS,
    )
    for generation_mode in [
        "legacy",
        "incremental",
    ]
]

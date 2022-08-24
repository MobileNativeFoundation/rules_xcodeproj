"""Macro wrapper for the `xcodeproj` rule."""

load(":bazel_labels.bzl", "bazel_labels")
load(":xcode_schemes.bzl", "xcode_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")

def xcodeproj(*, name, xcodeproj_rule = _xcodeproj, schemes = None, **kwargs):
    """Creates an .xcodeproj file in the workspace when run.

    Args:
        name: The name of the target.
        xcodeproj_rule: The actual `xcodeproj` rule. This is overridden during
            fixture testing. You shouldn't need to set it yourself.
        schemes: Optional. A `list` of values returned by
            `xcode_schemes.scheme`.
        **kwargs: Additional arguments to pass to `xcodeproj_rule`.
    """
    testonly = kwargs.pop("testonly", True)

    project = kwargs.get("project_name", name)

    focused_targets = [
        bazel_labels.normalize(t)
        for t in kwargs.pop("focused_targets", [])
    ]
    unfocused_targets = [
        bazel_labels.normalize(t)
        for t in kwargs.pop("unfocused_targets", [])
    ]

    # Combine targets that are specified directly and implicitly via the schemes
    top_level_targets = [
        bazel_labels.normalize(t)
        for t in kwargs.pop("top_level_targets", [])
    ]
    schemes_json = None
    if schemes != None:
        if unfocused_targets:
            schemes = xcode_schemes.unfocus_schemes(
                schemes = schemes,
                unfocused_targets = unfocused_targets,
            )
        if focused_targets:
            schemes = xcode_schemes.focus_schemes(
                schemes = schemes,
                focused_targets = focused_targets,
            )
        schemes_json = json.encode(schemes)

    if kwargs.get("toplevel_cache_buster"):
        fail("`toplevel_cache_buster` is for internal use only")

    # We control an input file to force downloading of top-level outputs,
    # without having them be declared as the exact top level outputs. This makes
    # the BEP a lot smaller and the UI output cleaner.
    # See `//xcodeproj/internal:output_files.bzl` for more details.
    toplevel_cache_buster = native.glob(
        [
            "{}.xcodeproj/rules_xcodeproj/toplevel_cache_buster".format(
                project,
            ),
        ],
        allow_empty = True,
    )

    xcodeproj_rule(
        name = name,
        focused_targets = focused_targets,
        schemes_json = schemes_json,
        testonly = testonly,
        top_level_targets = top_level_targets,
        toplevel_cache_buster = toplevel_cache_buster,
        unfocused_targets = unfocused_targets,
        **kwargs
    )

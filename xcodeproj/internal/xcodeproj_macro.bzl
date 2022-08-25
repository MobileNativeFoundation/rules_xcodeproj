"""Macro wrapper for the `xcodeproj` rule."""

load(":bazel_labels.bzl", "bazel_labels")
load(":xcode_schemes.bzl", "xcode_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")

def xcodeproj(
        *,
        name,
        focused_targets = [],
        project_name = None,
        schemes = [],
        top_level_targets,
        unfocused_targets = [],
        **kwargs):
    """Creates an `.xcodeproj` file in the workspace when run.

    The is a wrapper macro for the
    [actual `xcodeproj` rule](../xcodeproj/internal/xcodeproj_rule.bzl), which
    can't be used directly. All public API is documented below. The `kwargs`
    argument will pass forward values for globally available attributes (e.g.
    `visibility`, `features`, etc.) to the underlying rule.

    Args:
        name: A unique name for this target.
        focused_targets: Optional. A `list` of target labels as `string` values.
            If specified, only these targets will be included in the generated
            project; all other targets will be excluded, as if they were
            listed explicitly in the `unfocused_targets` argument. The labels
            must match transitive dependencies of the targets specified in the
            `top_level_targets` argument.
        project_name: Optional. The name to use for the `.xcodeproj` file. If
            not specified, the value of the `name` argument is used.
        schemes: Optional. A `list` of values returned by
            `xcode_schemes.scheme`.
        top_level_targets: A `list` of top-level targets labels.
        unfocused_targets: Optional. A `list` of target labels as `string`
            values. Any targets in the transitive dependencies of the targets
            specified in the `top_level_targets` argument with a matching
            label will be excluded from the generated project. This overrides
            any targets specified in the `focused_targets` argument.
        **kwargs: Additional arguments to pass to the underlying `xcodeproj`
            rule specified by `xcodeproj_rule`.
    """
    testonly = kwargs.pop("testonly", True)

    if not project_name:
        project_name = name

    if not top_level_targets:
        fail("`top_level_targets` cannot be empty.")

    focused_targets = [
        bazel_labels.normalize(t)
        for t in focused_targets
    ]
    unfocused_targets = [
        bazel_labels.normalize(t)
        for t in unfocused_targets
    ]

    schemes_json = None
    if schemes:
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
                project_name,
            ),
        ],
        allow_empty = True,
    )

    xcodeproj_rule = kwargs.pop("xcodeproj_rule", _xcodeproj)

    xcodeproj_rule(
        name = name,
        focused_targets = focused_targets,
        project_name = project_name,
        schemes_json = schemes_json,
        testonly = testonly,
        top_level_targets = top_level_targets,
        toplevel_cache_buster = toplevel_cache_buster,
        unfocused_targets = unfocused_targets,
        **kwargs
    )

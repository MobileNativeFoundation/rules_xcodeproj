"""Macro wrapper for the `xcodeproj` rule."""

load(":bazel_labels.bzl", "bazel_labels")
load(":xcode_schemes.bzl", "xcode_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")

def xcodeproj(
        *,
        name,
        bazel_path = "bazel",
        build_mode = "xcode",
        focused_targets = [],
        project_name = None,
        scheme_autogeneration_mode = "auto",
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
        bazel_path: Optional. The path the `bazel` binary or wrapper script. If
            the path is relative it will be resolved using the `PATH`
            environment variable (which is set to
            `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` in
            Xcode). If you want to specify a path to a workspace-relative
            binary, you must prepend the path with `./` (e.g. `"./bazelw"`).
        build_mode: Optional. The build mode the generated project should use.

            If this is set to `"xcode"`, the project will use the Xcode build
            system to build targets. Generated files and unfocused targets (see
            the `focused_targets` and `unfocused_targets` arguments) will be
            built with Bazel.

            If this is set to `"bazel"`, the project will use Bazel to build
            targets, inside of Xcode. The Xcode build system still unavoidably
            orchestrates some things at a high level.
        focused_targets: Optional. A `list` of target labels as `string` values.
            If specified, only these targets will be included in the generated
            project; all other targets will be excluded, as if they were
            listed explicitly in the `unfocused_targets` argument. The labels
            must match transitive dependencies of the targets specified in the
            `top_level_targets` argument.
        project_name: Optional. The name to use for the `.xcodeproj` file. If
            not specified, the value of the `name` argument is used.
        scheme_autogeneration_mode: Optional. Specifies how Xcode schemes are
            automatically generated.
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

    # Apply defaults
    if not bazel_path:
        bazel_path = "bazel"
    if not build_mode:
        build_mode = "xcode"
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
        build_mode = build_mode,
        bazel_path = bazel_path,
        focused_targets = focused_targets,
        project_name = project_name,
        scheme_autogeneration_mode = scheme_autogeneration_mode,
        schemes_json = schemes_json,
        testonly = testonly,
        top_level_targets = top_level_targets,
        toplevel_cache_buster = toplevel_cache_buster,
        unfocused_targets = unfocused_targets,
        **kwargs
    )

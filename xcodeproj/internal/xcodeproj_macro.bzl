"""Macro wrapper for the `xcodeproj` rule."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", "bazel_labels")
load(":xcode_schemes.bzl", "xcode_schemes")
load(":xcodeproj_rule.bzl", _xcodeproj = "xcodeproj")

def xcodeproj(*, name, xcodeproj_rule = _xcodeproj, schemes = None, **kwargs):
    """Creates an .xcodeproj file in the workspace when run.

    Args:
        name: The name of the target.
        xcodeproj_rule: The actual `xcodeproj` rule. This is overridden during
            fixture testing. You shouldn't need to set it yourself.
        schemes: Optional. A `list` of `struct` values as returned by
            `xcode_schemes.scheme`.
        **kwargs: Additional arguments to pass to `xcodeproj_rule`.
    """
    testonly = kwargs.pop("testonly", True)

    project = kwargs.get("project_name", name)

    # Combine targets that are specified directly and implicitly via the schemes
    targets = [bazel_labels.normalize(t) for t in kwargs.pop("targets", [])]
    schemes_json = None
    if schemes != None:
        schemes_json = json.encode(schemes)
        targets_from_schemes = xcode_schemes.collect_top_level_targets(schemes)
        targets_set = sets.make(targets)
        targets_set = sets.union(targets_set, targets_from_schemes)
        targets = sorted(sets.to_list(targets_set))

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
        testonly = testonly,
        toplevel_cache_buster = toplevel_cache_buster,
        schemes_json = schemes_json,
        targets = targets,
        **kwargs
    )

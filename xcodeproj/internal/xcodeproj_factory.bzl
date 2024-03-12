"""Module to create `xcodeproj` rules and transitions."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(":xcodeproj_incremental_aspect.bzl", "xcodeproj_incremental_aspect")
load(":xcodeproj_incremental_rule.bzl", "xcodeproj_incremental_rule")
load(":xcodeproj_legacy_aspect.bzl", "xcodeproj_legacy_aspect")
load(":xcodeproj_legacy_rule.bzl", "xcodeproj_legacy_rule")
load(":xcodeproj_transitions.bzl", "XCODEPROJ_TRANSITION_ATTRS")

def _make_xcodeproj_aspect(
        *,
        build_mode,
        focused_labels,
        generator_name,
        unfocused_labels,
        use_incremental):
    if use_incremental:
        attrs = xcodeproj_incremental_aspect.attrs(
            focused_labels = focused_labels,
            generator_name = generator_name,
            unfocused_labels = unfocused_labels,
        )
        implementation = xcodeproj_incremental_aspect.impl
    else:
        attrs = xcodeproj_legacy_aspect.attrs(
            build_mode = build_mode,
            generator_name = generator_name,
        )
        implementation = xcodeproj_legacy_aspect.impl

    return aspect(
        implementation = implementation,
        attr_aspects = ["*"],
        attrs = attrs,
        fragments = ["apple", "cpp", "objc"],
        toolchains = use_cpp_toolchain(),
    )

def _make_xcodeproj_rule(
        *,
        focused_labels,
        is_fixture = False,
        target_transitions = None,
        unfocused_labels,
        use_incremental,
        xcodeproj_aspect,
        xcodeproj_transition = None):
    if use_incremental:
        attrs = xcodeproj_incremental_rule.attrs(
            is_fixture = is_fixture,
            target_transitions = target_transitions,
            xcodeproj_aspect = xcodeproj_aspect,
        )
        impl = xcodeproj_incremental_rule.impl
    else:
        attrs = xcodeproj_legacy_rule.attrs(
            focused_labels = focused_labels,
            is_fixture = is_fixture,
            target_transitions = target_transitions,
            unfocused_labels = unfocused_labels,
            xcodeproj_aspect = xcodeproj_aspect,
        )
        impl = xcodeproj_legacy_rule.impl

    return rule(
        doc = "Creates an `.xcodeproj` file in the workspace when run.",
        cfg = xcodeproj_transition,
        implementation = impl,
        attrs = attrs | XCODEPROJ_TRANSITION_ATTRS,
        executable = True,
    )

xcodeproj_factory = struct(
    make_aspect = _make_xcodeproj_aspect,
    make_rule = _make_xcodeproj_rule,
)

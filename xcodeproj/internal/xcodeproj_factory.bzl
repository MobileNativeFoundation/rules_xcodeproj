"""Module to create `xcodeproj` rules and transitions."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")
load(":xcodeproj_rule.bzl", "xcodeproj_rule")
load(":xcodeproj_transitions.bzl", "XCODEPROJ_TRANSITION_ATTRS")

def _make_xcodeproj_aspect(
        *,
        focused_labels,
        generator_name,
        unfocused_labels):
    attrs = xcodeproj_aspect.attrs(
        focused_labels = focused_labels,
        generator_name = generator_name,
        unfocused_labels = unfocused_labels,
    )
    implementation = xcodeproj_aspect.impl

    return aspect(
        implementation = implementation,
        attr_aspects = ["*"],
        attrs = attrs,
        fragments = ["apple", "cpp", "objc"],
        toolchains = use_cpp_toolchain(),
    )

def _make_xcodeproj_rule(
        *,
        target_transitions = None,
        xcodeproj_aspect):
    attrs = xcodeproj_rule.attrs(
        target_transitions = target_transitions,
        xcodeproj_aspect = xcodeproj_aspect,
    )
    impl = xcodeproj_rule.impl

    return rule(
        doc = "Creates an `.xcodeproj` file in the workspace when run.",
        implementation = impl,
        attrs = attrs | XCODEPROJ_TRANSITION_ATTRS,
        executable = True,
    )

xcodeproj_factory = struct(
    make_aspect = _make_xcodeproj_aspect,
    make_rule = _make_xcodeproj_rule,
)

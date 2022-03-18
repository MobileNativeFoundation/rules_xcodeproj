"""Implementation of the `xcodeproj_aspect` aspect."""

load(":input_files_aspect.bzl", "input_files_aspect")
load(":target.bzl", "XcodeProjInfo", "process_target")

_ASPECT_DEP_ATTR = [
    "test_host",
]

_ASPECT_DEP_ATTRS = [
    "deps",
]

_ASPECT_RESOURCES_ATTRS = [
    "data",
    "resources",
]

# Utility

def _transitive_infos(*, ctx):
    transitive_infos = []
    for attr in _ASPECT_RESOURCES_ATTRS:
        deps = getattr(ctx.rule.attr, attr, [])
        for dep in deps:
            if XcodeProjInfo in dep:
                transitive_infos.append(dep[XcodeProjInfo])
    for attr in _ASPECT_DEP_ATTRS:
        deps = getattr(ctx.rule.attr, attr, [])
        for dep in deps:
            if XcodeProjInfo in dep:
                transitive_infos.append(dep[XcodeProjInfo])
    for attr in _ASPECT_DEP_ATTR:
        dep = getattr(ctx.rule.attr, attr, None)
        if dep:
            transitive_infos.append(dep[XcodeProjInfo])

    return transitive_infos

# Aspect

def _xcodeproj_aspect_impl(target, ctx):
    return [
        process_target(
            ctx = ctx,
            target = target,
            transitive_infos = _transitive_infos(ctx = ctx),
        ),
    ]

xcodeproj_aspect = aspect(
    implementation = _xcodeproj_aspect_impl,
    attr_aspects = (
        _ASPECT_DEP_ATTR + _ASPECT_DEP_ATTRS + _ASPECT_RESOURCES_ATTRS
    ),
    attrs = {
        "_cc_toolchain": attr.label(default = Label(
            "@bazel_tools//tools/cpp:current_cc_toolchain",
        )),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    },
    fragments = ["apple", "cpp"],
    requires = [input_files_aspect],
)

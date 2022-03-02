"""Implementation of the `xcodeproj_aspect` aspect."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:target.bzl",
    "process_target",
    "XcodeProjInfo",
)

_ASPECT_ATTR= [
    "test_host",
]

_ASPECT_ATTRS = [
    "data",
    "deps",
    "resources",
]

# Utility

def _transitive_infos(*, ctx):
    list_of_deps = []
    for attr in _ASPECT_ATTR:
        single = getattr(ctx.rule.attr, attr, None)
        if single:
            list_of_deps.append([single])
    for attr in _ASPECT_ATTRS:
        list_of_deps.append(getattr(ctx.rule.attr, attr, []))

    transitive_infos = []
    for deps in list_of_deps:
        for dep in deps:
            if XcodeProjInfo in dep:
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
    attr_aspects = _ASPECT_ATTR + _ASPECT_ATTRS,
    attrs = {
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
        "_cc_toolchain": attr.label(default = Label(
            "@bazel_tools//tools/cpp:current_cc_toolchain",
        )),
    },
    fragments = ["apple", "cpp"],
)

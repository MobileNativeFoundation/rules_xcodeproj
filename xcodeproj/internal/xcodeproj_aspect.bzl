"""Implementation of the `xcodeproj_aspect` aspect."""

load(
    ":default_input_file_attributes_aspect.bzl",
    "default_input_file_attributes_aspect",
)
load(":providers.bzl", "XcodeProjInfo")
load(":target.bzl", "process_target")

# Utility

def _should_ignore_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _transitive_infos(*, ctx):
    transitive_infos = []
    for attr in dir(ctx.rule.attr):
        if _should_ignore_attr(attr):
            continue

        dep = getattr(ctx.rule.attr, attr)
        if type(dep) == "list":
            for dep in dep:
                if type(dep) == "Target" and XcodeProjInfo in dep:
                    transitive_infos.append(dep[XcodeProjInfo])
        elif type(dep) == "Target" and XcodeProjInfo in dep:
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
    attr_aspects = ["*"],
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
    requires = [default_input_file_attributes_aspect],
)

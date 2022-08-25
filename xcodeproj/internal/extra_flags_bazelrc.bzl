"""Implementation of the `extra_flags_bazelrc` rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _process_extra_flags(*, attr, content, setting, config_suffix):
    extra_flags = getattr(attr, setting)[BuildSettingInfo].value
    if extra_flags:
        content.append(
            "build:rules_xcodeproj{} {}".format(config_suffix, extra_flags),
        )

def _extra_flags_bazelrc_impl(ctx):
    output = ctx.actions.declare_file("xcodeproj_extra_flags.bazelrc")

    content = []

    _process_extra_flags(
        attr = ctx.attr,
        content = content,
        setting = "_extra_common_flags",
        config_suffix = "",
    )
    _process_extra_flags(
        attr = ctx.attr,
        content = content,
        setting = "_extra_build_flags",
        config_suffix = "_build",
    )
    _process_extra_flags(
        attr = ctx.attr,
        content = content,
        setting = "_extra_indexbuild_flags",
        config_suffix = "_indexbuild",
    )
    _process_extra_flags(
        attr = ctx.attr,
        content = content,
        setting = "_extra_swiftuipreviews_flags",
        config_suffix = "_swiftuipreviews",
    )

    # Trailing newline
    content.append("")

    ctx.actions.write(
        output = output,
        content = "\n".join(content),
    )

    return [DefaultInfo(files = depset([output]))]

extra_flags_bazelrc = rule(
    implementation = _extra_flags_bazelrc_impl,
    attrs = {
        "_extra_build_flags": attr.label(
            default = Label("//xcodeproj:extra_build_flags"),
            providers = [BuildSettingInfo],
        ),
        "_extra_common_flags": attr.label(
            default = Label("//xcodeproj:extra_common_flags"),
            providers = [BuildSettingInfo],
        ),
        "_extra_indexbuild_flags": attr.label(
            default = Label("//xcodeproj:extra_indexbuild_flags"),
            providers = [BuildSettingInfo],
        ),
        "_extra_swiftuipreviews_flags": attr.label(
            default = Label("//xcodeproj:extra_swiftuipreviews_flags"),
            providers = [BuildSettingInfo],
        ),
    },
)

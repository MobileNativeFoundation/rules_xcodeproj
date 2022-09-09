"""Implementation of the `xcodeproj_runner` rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":providers.bzl", "XcodeProjRunnerOutputInfo")

def _process_extra_flags(*, attr, content, setting, config, config_suffix):
    extra_flags = getattr(attr, setting)[BuildSettingInfo].value
    if extra_flags:
        content.append(
            "build:{}{} {}".format(config, config_suffix, extra_flags),
        )

        if config != "rules_xcodeproj" and not config_suffix:
            content.append(
            """\
build:{config}_build --config={config}
build:{config}_generator --config={config}
build:{config}_indexbuild --config={config}
build:{config}_info --config={config}
build:{config}_swiftuipreviews --config={config}\
""".format(config = config),
        )

def _write_extra_flags_bazelrc(name, actions, attr, config):
    output = actions.declare_file("{}-extra-flags.bazelrc".format(name))

    content = []

    if config != "rules_xcodeproj":
        content.append(
            """\
build:{config}_build --config=rules_xcodeproj_build
build:{config}_generator --config=rules_xcodeproj_generator
build:{config}_indexbuild --config=rules_xcodeproj_indexbuild
build:{config}_info --config=rules_xcodeproj_info
build:{config}_swiftuipreviews --config=rules_xcodeproj_swiftuipreviews\
""".format(config = config),
        )

    _process_extra_flags(
        attr = attr,
        content = content,
        setting = "_extra_common_flags",
        config = config,
        config_suffix = "",
    )
    _process_extra_flags(
        attr = attr,
        content = content,
        setting = "_extra_build_flags",
        config = config,
        config_suffix = "_build",
    )
    _process_extra_flags(
        attr = attr,
        content = content,
        setting = "_extra_indexbuild_flags",
        config = config,
        config_suffix = "_indexbuild",
    )
    _process_extra_flags(
        attr = attr,
        content = content,
        setting = "_extra_swiftuipreviews_flags",
        config = config,
        config_suffix = "_swiftuipreviews",
    )

    # Trailing newline
    content.append("")

    actions.write(
        output = output,
        content = "\n".join(content),
    )

    return output

def _write_runner(
        *,
        name,
        actions,
        bazelrc,
        bazel_path,
        config,
        extra_flags_bazelrc,
        extra_generator_flags,
        generator_label,
        project_name,
        template):
    output = actions.declare_file("{}-runner.sh".format(name))

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%bazel_path%": bazel_path,
            "%bazelrc%": bazelrc.short_path,
            "%config%": config,
            "%extra_flags_bazelrc%": extra_flags_bazelrc.short_path,
            "%extra_generator_flags%": extra_generator_flags,
            "%generator_label%": generator_label,
            "%project_name%": project_name,
        },
    )

    return output

def _xcodeproj_runner_impl(ctx):
    bazelrc = ctx.file._bazelrc
    config = "rules_xcodeproj"
    project_name = ctx.attr.project_name

    extra_flags_bazelrc = _write_extra_flags_bazelrc(
        name = ctx.attr.name,
        actions = ctx.actions,
        attr = ctx.attr,
        config = config,
    )

    runner = _write_runner(
        name = ctx.attr.name,
        actions = ctx.actions,
        bazel_path = ctx.attr.bazel_path,
        bazelrc = bazelrc,
        config = config,
        extra_flags_bazelrc = extra_flags_bazelrc,
        extra_generator_flags = (
            ctx.attr._extra_generator_flags[BuildSettingInfo].value
        ),
        generator_label = ctx.attr.xcodeproj_target,
        project_name = project_name,
        template = ctx.file._runner_template,
    )

    return [
        DefaultInfo(
            executable = runner,
            runfiles = ctx.runfiles(files = [bazelrc, extra_flags_bazelrc]),
        ),
        XcodeProjRunnerOutputInfo(
            project_name = project_name,
            runner = runner,
        ),
    ]

xcodeproj_runner = rule(
    implementation = _xcodeproj_runner_impl,
    attrs = {
        "bazel_path": attr.string(
            mandatory = True,
        ),
        "config": attr.string(
            mandatory = True,
        ),
        "project_name": attr.string(
            mandatory = True,
        ),
        "xcodeproj_target": attr.string(
            mandatory = True,
        ),
        "_bazelrc": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal/bazel_integration_files:xcodeproj.bazelrc"),
        ),
        "_extra_build_flags": attr.label(
            default = Label("//xcodeproj:extra_build_flags"),
            providers = [BuildSettingInfo],
        ),
        "_extra_common_flags": attr.label(
            default = Label("//xcodeproj:extra_common_flags"),
            providers = [BuildSettingInfo],
        ),
        "_extra_generator_flags": attr.label(
            default = Label("//xcodeproj:extra_generator_flags"),
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
        "_runner_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:runner.template.sh"),
        ),
    },
    executable = True,
)

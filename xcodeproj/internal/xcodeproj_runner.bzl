"""Implementation of the `xcodeproj_runner` rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":providers.bzl", "XcodeProjRunnerOutputInfo")

def _xcodeproj_runner_impl(ctx):
    runner = ctx.actions.declare_file(
        "{}-runner.sh".format(ctx.attr.name),
    )

    project_name = ctx.attr.project_name

    ctx.actions.expand_template(
        template = ctx.file._runner_template,
        output = runner,
        is_executable = True,
        substitutions = {
            "%bazel_path%": ctx.attr.bazel_path,
            "%bazelrc%": ctx.file._bazelrc.short_path,
            "%extra_flags_bazelrc%": ctx.file._extra_flags_bazelrc.short_path,
            "%extra_generator_flags%": (
                ctx.attr._extra_generator_flags[BuildSettingInfo].value
            ),
            "%generator_label%": ctx.attr.xcodeproj_target,
            "%project_name%": project_name,
        },
    )

    return [
        DefaultInfo(
            executable = runner,
            runfiles = ctx.runfiles(
                files = [
                    ctx.file._bazelrc,
                    ctx.file._extra_flags_bazelrc,
                ],
            ),
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
        "_extra_flags_bazelrc": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:extra_flags_bazelrc"),
        ),
        "_extra_generator_flags": attr.label(
            default = Label("//xcodeproj:extra_generator_flags"),
            providers = [BuildSettingInfo],
        ),
        "_runner_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:runner.template.sh"),
        ),
    },
    executable = True,
)

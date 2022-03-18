"""Functions for updating test fixtures."""

load(
    "//xcodeproj:xcodeproj.bzl",
    "XcodeProjOutputInfo",
    "make_xcodeproj_rule",
    "xcodeproj",
)

# Transition

def _fixtures_transition_impl(_settings, _attr):
    """Rule transition that standardizes command-line options for fixtures."""
    return {
        "//command_line_option:cpu": "darwin_x86_64",
        "//command_line_option:ios_minimum_os": "14.1",
        "//command_line_option:macos_cpus": "x86_64",
        "//command_line_option:macos_minimum_os": "11.0",
        "//command_line_option:tvos_minimum_os": "9.2",
        "//command_line_option:watchos_minimum_os": "7.6.2",
    }

fixtures_transition = transition(
    implementation = _fixtures_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:cpu",
        "//command_line_option:ios_minimum_os",
        "//command_line_option:macos_cpus",
        "//command_line_option:macos_minimum_os",
        "//command_line_option:tvos_minimum_os",
        "//command_line_option:watchos_minimum_os",
    ],
)

# Rule

def _update_fixtures_impl(ctx):
    specs = [target[XcodeProjOutputInfo].spec for target in ctx.attr.targets]
    installers = [
        target[XcodeProjOutputInfo].installer
        for target in ctx.attr.targets
    ]
    xcodeprojs = [
        target[XcodeProjOutputInfo].xcodeproj
        for target in ctx.attr.targets
    ]

    updater = ctx.actions.declare_file(
        "{}-updater.sh".format(ctx.label.name),
    )

    ctx.actions.expand_template(
        template = ctx.file._updater_template,
        output = updater,
        is_executable = True,
        substitutions = {
            "%installers%": "  \n".join(
                [installer.short_path for installer in installers],
            ),
            "%specs%": "  \n".join([spec.short_path for spec in specs]),
        },
    )

    return [
        DefaultInfo(
            executable = updater,
            runfiles = ctx.runfiles(files = specs + xcodeprojs + installers),
        ),
    ]

_update_fixtures = rule(
    implementation = _update_fixtures_impl,
    attrs = {
        "targets": attr.label_list(
            cfg = fixtures_transition,
            mandatory = True,
            providers = [XcodeProjOutputInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            executable = False,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
        "_updater_template": attr.label(
            allow_single_file = True,
            default = ":updater.template.sh",
        ),
    },
    executable = True,
)

def update_fixtures(**kwargs):
    testonly = kwargs.pop("testonly", True)
    _update_fixtures(
        testonly = testonly,
        **kwargs
    )

_fixture_xcodeproj = make_xcodeproj_rule(
    transition = fixtures_transition,
)

def xcodeproj_fixture(*, name = "xcodeproj", project_name = "project", targets):
    native.exports_files([
        "spec.json",
    ])

    xcodeproj(
        name = name,
        external_dir_override = "bazel-rules_xcodeproj/external",
        generated_dir_override = "bazel-out",
        project_name = project_name,
        targets = targets,
        xcodeproj_rule = _fixture_xcodeproj,
        visibility = ["//test:__subpackages__"],
    )

    native.filegroup(
        name = "{}_output".format(name),
        srcs = native.glob(
            ["{}.xcodeproj/**/*".format(project_name)],
            exclude = [
                "{}.xcodeproj/xcshareddata/**/*".format(project_name),
                "{}.xcodeproj/**/xcuserdata/**/*".format(project_name),
                "{}.xcodeproj/*.xcuserdatad/**/*".format(project_name),
            ],
        ),
        visibility = ["//test:__subpackages__"],
    )

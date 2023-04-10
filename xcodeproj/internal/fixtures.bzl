"""Functions for updating test fixtures."""

load(":providers.bzl", "XcodeProjRunnerOutputInfo")
load(":xcodeproj_macro.bzl", "xcodeproj")

_MINIMUM_XCODE_VERSION = "13.0"

# Transition

def _fixtures_transition_impl(_settings, _attr):
    """Rule transition that standardizes command-line options for fixtures."""
    return {
        "//command_line_option:cpu": "darwin_x86_64",
        "//command_line_option:host_cpu": "darwin_x86_64",
        "//command_line_option:ios_minimum_os": "14.1",
        "//command_line_option:macos_cpus": "x86_64",
        "//command_line_option:macos_minimum_os": "12.0",
        "//command_line_option:tvos_minimum_os": "9.2",
        "//command_line_option:watchos_minimum_os": "7.6.2",
    }

# For use in fixture `xcodeproj_runner` generated `defs.bzl` files
fixtures_transition = transition(
    implementation = _fixtures_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:cpu",
        "//command_line_option:host_cpu",
        "//command_line_option:ios_minimum_os",
        "//command_line_option:macos_cpus",
        "//command_line_option:macos_minimum_os",
        "//command_line_option:tvos_minimum_os",
        "//command_line_option:watchos_minimum_os",
    ],
)

# Rule

def _update_fixtures_impl(ctx):
    runner_infos = [
        target[XcodeProjRunnerOutputInfo]
        for target in ctx.attr.targets
    ]

    project_names = [info.project_name for info in runner_infos]
    runners = [info.runner for info in runner_infos]

    updater = ctx.actions.declare_file(
        "{}-updater.sh".format(ctx.label.name),
    )

    if runners:
        runners_str = "\n{}\n".format(
            "  \n".join([runner.short_path for runner in runners]),
        )
    else:
        runners_str = ""

    if project_names:
        project_names_str = "\n{}\n".format("  \n".join(project_names))
    else:
        project_names_str = ""

    ctx.actions.expand_template(
        template = ctx.file._updater_template,
        output = updater,
        is_executable = True,
        substitutions = {
            "%project_names%": project_names_str,
            "%runners%": runners_str,
            "%validate%": json.encode(ctx.attr._validate),
        },
    )

    return [
        DefaultInfo(
            executable = updater,
            runfiles = ctx.runfiles().merge_all([
                target[DefaultInfo].default_runfiles
                for target in ctx.attr.targets
            ]),
        ),
    ]

_update_fixtures = rule(
    implementation = _update_fixtures_impl,
    attrs = {
        "targets": attr.label_list(
            mandatory = True,
            providers = [XcodeProjRunnerOutputInfo],
        ),
        "_updater_template": attr.label(
            allow_single_file = True,
            default = ":updater.template.sh",
        ),
        "_validate": attr.bool(
            default = False,
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

_validate_fixtures = rule(
    implementation = _update_fixtures_impl,
    attrs = {
        "targets": attr.label_list(
            mandatory = True,
            providers = [XcodeProjRunnerOutputInfo],
        ),
        "_updater_template": attr.label(
            allow_single_file = True,
            default = ":updater.template.sh",
        ),
        "_validate": attr.bool(
            default = True,
        ),
    },
    executable = True,
)

def validate_fixtures(**kwargs):
    testonly = kwargs.pop("testonly", True)
    _validate_fixtures(
        testonly = testonly,
        **kwargs
    )

def fixture_output_name(fixture_name):
    return "{}_output".format(fixture_name)

def fixture_spec_name(fixture_name):
    return "{}_spec".format(fixture_name)

def xcodeproj_fixture(
        *,
        name = "xcodeproj",
        modes_and_suffixes = [("xcode", "bwx"), ("bazel", "bwb")],
        associated_extra_files = {},
        bazel_env = None,
        config = "rules_xcodeproj",
        default_xcode_configuration = None,
        extra_files = [],
        fail_for_invalid_extra_files_targets = True,
        top_level_targets = [],
        focused_targets = [],
        unfocused_targets = [],
        post_build = None,
        pre_build = None,
        project_options = None,
        schemes = None,
        scheme_autogeneration_mode = None,
        xcode_configurations = None):
    """Creates the fixture for an existing `xcodeproj` target.

    This will create an `xcodeproj` target for each `build_mode` option.

    Args:
        name: The name of the fixture. This will be the prefix of the .xcodeproj
            and spec files.
        modes_and_suffixes: A `list` of `tuple`s of `build_mode` and `suffix`.
            The `build_mode` will be pass to `xcodeproj.build_mode` and the
            `suffix` will be used as the suffix of the project and spec files.
        associated_extra_files: Maps to `xcodeproj.associated_extra_files`.
        bazel_env: Maps to `xcodeproj.bazel_env`.
        config: Maps to `xcodeproj.config`.
        default_xcode_configuration: Maps to
            `xcodeproj.default_xcode_configuration`.
        extra_files: Maps to `xcodeproj.extra_files`.
        fail_for_invalid_extra_files_targets: Maps to `fail_for_invalid_extra_files_targets`.
        post_build: Maps to `xcodeproj.post_build`.
        pre_build: Maps to `xcodeproj.pre_build`.
        project_options: Maps to `xcodeproj.project_options`.
        top_level_targets: Maps to `xcodeproj.top_level_targets`.
        focused_targets: Maps to `xcodeproj.focused_targets`.
        unfocused_targets: Maps to `xcodeproj.unfocused_targets`.
        schemes: Maps to `xcodeproj.schemes`.
        scheme_autogeneration_mode: Maps to
            `xcodeproj.scheme_autogeneration_mode`.
        xcode_configurations: Maps to `xcodeproj.xcode_configurations`.
    """
    for mode, suffix in modes_and_suffixes:
        fixture_name = "{}_{}".format(name, suffix)
        spec_name = "{}_spec.json".format(suffix)

        native.exports_files([spec_name])

        native.alias(
            name = fixture_spec_name(fixture_name),
            actual = spec_name,
            tags = ["manual"],
            visibility = ["//test:__subpackages__"],
        )

        xcodeproj(
            name = fixture_name,
            associated_extra_files = associated_extra_files,
            bazel_env = bazel_env,
            build_mode = mode,
            config = config,
            default_xcode_configuration = default_xcode_configuration,
            extra_files = extra_files,
            fail_for_invalid_extra_files_targets = fail_for_invalid_extra_files_targets,
            focused_targets = focused_targets,
            is_fixture = True,
            minimum_xcode_version = _MINIMUM_XCODE_VERSION,
            post_build = post_build,
            pre_build = pre_build,
            project_name = suffix,
            project_options = project_options,
            tags = ["manual"],
            top_level_targets = top_level_targets,
            scheme_autogeneration_mode = scheme_autogeneration_mode,
            schemes = schemes,
            unfocused_targets = unfocused_targets,
            xcode_configurations = xcode_configurations,
            visibility = ["//test:__subpackages__"],
        )

        native.filegroup(
            name = fixture_output_name(fixture_name),
            srcs = native.glob(
                ["{}.xcodeproj/**/*".format(suffix)],
                exclude = [
                    "{}.xcodeproj/**/xcuserdata/**/*".format(suffix),
                    "{}.xcodeproj/*.xcuserdatad/**/*".format(suffix),
                ],
                allow_empty = True,
            ),
            tags = ["manual"],
            visibility = ["//test:__subpackages__"],
        )

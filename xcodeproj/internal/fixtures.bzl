"""Functions for updating test fixtures."""

load(":providers.bzl", "XcodeProjOutputInfo")
load(":xcodeproj.bzl", "make_xcodeproj_rule", "xcodeproj")

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
    project_names = [
        target[XcodeProjOutputInfo].project_name
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
            "%project_names%": "  \n".join(project_names),
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

def fixture_output_name(fixture_name):
    return "{}_output".format(fixture_name)

def fixture_spec_name(fixture_name):
    return "{}_spec".format(fixture_name)

def xcodeproj_fixture(
        *,
        name = "xcodeproj",
        archived_bundles_allowed = False,
        modes_and_suffixes = [("xcode", "bwx"), ("bazel", "bwb")],
        targets):
    """Creates the fixture for an existing `xcodeproj` target.

    This will create an `xcodeproj` target for each `build_mode` option.

    Args:
        name: The name of the fixture. This will be the prefix of the .xcodeproj
            and spec files.
        archived_bundles_allowed: Passed to `xcodeproj`.
        modes_and_suffixes: A `list` of `tuple`s of `build_mode` and `suffix`.
            The `build_mode` will be pass to `xcodeproj.build_mode` and the
            `suffix` will be used as the suffix of the project and spec files.
        targets: Maps to `xcodeproj.targets`.
    """
    for mode, suffix in modes_and_suffixes:
        fixture_name = "{}_{}".format(name, suffix)
        spec_name = "{}_spec.json".format(suffix)

        native.exports_files([spec_name])

        native.alias(
            name = fixture_spec_name(fixture_name),
            actual = spec_name,
            visibility = ["//test:__subpackages__"],
        )

        xcodeproj(
            name = fixture_name,
            archived_bundles_allowed = archived_bundles_allowed,
            build_mode = mode,
            project_name = suffix,
            targets = targets,
            xcodeproj_rule = _fixture_xcodeproj,
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
            ),
            visibility = ["//test:__subpackages__"],
        )

"""Implementation of the `xcodeproj_runner` rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":collections.bzl", "uniq")
load(":providers.bzl", "XcodeProjRunnerOutputInfo")

def _get_xcode_product_version(*, xcode_config):
    raw_version = str(xcode_config.xcode_version())
    if not raw_version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")

    version_components = raw_version.split(".")
    if len(version_components) < 4:
        # This will result in analysis cache misses, but it's better than
        # failing
        return raw_version

    return version_components[3]

def _process_extra_flags(*, attr, content, setting, config, config_suffix):
    extra_flags = getattr(attr, setting)[BuildSettingInfo].value
    if extra_flags:
        content.append(
            "build:{}{} {}".format(config, config_suffix, extra_flags),
        )

def _serialize_nullable_string(value):
    if not value:
        return "None"
    return '"' + value + '"'

def _write_xcodeproj_bazelrc(name, actions, config, template):
    output = actions.declare_file("{}.bazelrc".format(name))

    if config != "rules_xcodeproj":
        project_configs = """
# Set `--verbose_failures` on `info` as the closest to a "no-op" config as
# possible, until https://github.com/bazelbuild/bazel/issues/12844 is fixed
info:{config} --verbose_failures

# Inherit from base configs
build:{config}_generator --config=rules_xcodeproj_generator
build:{config}_generator --config={config}
build:{config}_indexbuild --config=rules_xcodeproj_indexbuild
build:{config}_indexbuild --config={config}
build:{config}_swiftuipreviews --config=rules_xcodeproj_swiftuipreviews
build:{config}_swiftuipreviews --config={config}
build:{config}_asan --config=rules_xcodeproj_asan
build:{config}_asan --config={config}
build:{config}_tsan --config=rules_xcodeproj_tsan
build:{config}_tsan --config={config}
build:{config}_ubsan --config=rules_xcodeproj_ubsan
build:{config}_ubsan --config={config}

# Private implementation detail. Don't adjust this config, adjust
# `{config}` instead.
build:_{config}_build --config=_rules_xcodeproj_build
build:_{config}_build --config={config}
""".format(config = config)
    else:
        project_configs = ""

    actions.expand_template(
        template = template,
        output = output,
        substitutions = {
            "%project_configs%": project_configs,
        },
    )

    return output

def _write_extra_flags_bazelrc(name, actions, attr, config):
    output = actions.declare_file("{}-extra-flags.bazelrc".format(name))

    content = []

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

def _write_schemes_json(*, actions, name, schemes_json):
    output = actions.declare_file(
        "{}-custom_xcode_schemes.json".format(name),
    )
    actions.write(output, schemes_json if schemes_json else "[]")
    return output

def _write_generator_defz_bzl(
        *,
        actions,
        attr,
        is_fixture,
        name,
        repo,
        template):
    output = actions.declare_file("{}.generator.defs.bzl".format(name))

    build_mode = attr.build_mode

    loads = [
        """\
# buildifier: disable=bzl-visibility
load(
    "{repo}//xcodeproj/internal:xcodeproj_rule.bzl",
    "make_xcodeproj_rule",
    "make_xcodeproj_target_transitions",
)""".format(repo = repo),
    ]
    if is_fixture:
        loads.append("""\
# buildifier: disable=bzl-visibility
load(
    "{repo}//xcodeproj/internal:fixtures.bzl",
    "fixtures_transition",
)""".format(repo = repo))

    target_transitions = """\
def _target_transition_implementation(_settings, _attr):
    return {xcode_configurations}

_target_transitions = make_xcodeproj_target_transitions(
    implementation = _target_transition_implementation,
    outputs = {flags},
)""".format(
        flags = attr.xcode_configuration_flags,
        xcode_configurations = attr.xcode_configurations,
    )

    actions.expand_template(
        template = template,
        output = output,
        substitutions = {
            "%build_mode%": build_mode,
            "%is_fixture%": str(is_fixture),
            "%loads%": "\n".join(loads),
            "%target_transitions%": target_transitions,
            "%xcodeproj_transitions%": (
                "fixtures_transition" if is_fixture else "None"
            ),
        },
    )

    return output

def _write_generator_build_file(
        *,
        actions,
        attr,
        build_file_path,
        name,
        template):
    output = actions.declare_file("{}.generator.BUILD.bazel".format(name))

    # The generator should always have its config applied, so add `manual` to
    # the tag to prevent accidental building with `//...`
    tags = str(uniq(attr.tags + ["manual"]))

    actions.expand_template(
        template = template,
        output = output,
        substitutions = {
            "%adjust_schemes_for_swiftui_previews%": (
                str(attr.adjust_schemes_for_swiftui_previews)
            ),
            "%build_mode%": attr.build_mode,
            "%bazel_path%": attr.bazel_path,
            "%config%": attr.config,
            "%default_xcode_configuration%": (
                _serialize_nullable_string(attr.default_xcode_configuration)
            ),
            "%focused_targets%": str(attr.focused_targets),
            "%install_directory%": attr.install_directory,
            "%ios_device_cpus%": attr.ios_device_cpus,
            "%ios_simulator_cpus%": attr.ios_simulator_cpus,
            "%minimum_xcode_version%": attr.minimum_xcode_version,
            "%name%": name,
            "%owned_extra_files%": str(attr.owned_extra_files),
            "%post_build%": attr.post_build,
            "%pre_build%": attr.pre_build,
            "%project_name%": attr.project_name,
            "%project_options%": str(attr.project_options),
            "%runner_build_file%": build_file_path,
            "%runner_label%": attr.runner_label,
            "%scheme_autogeneration_mode%": attr.scheme_autogeneration_mode,
            "%tags%": tags,
            "%testonly%": str(attr.testonly),
            "%top_level_device_targets%": str(attr.top_level_device_targets),
            "%top_level_simulator_targets%": str(
                attr.top_level_simulator_targets,
            ),
            "%tvos_device_cpus%": attr.tvos_device_cpus,
            "%tvos_simulator_cpus%": attr.tvos_simulator_cpus,
            "%unfocused_targets%": str(attr.unfocused_targets),
            "%unowned_extra_files%": str(attr.unowned_extra_files),
            "%watchos_device_cpus%": attr.watchos_device_cpus,
            "%watchos_simulator_cpus%": attr.watchos_simulator_cpus,
        },
    )

    return output

def _write_runner(
        *,
        name,
        actions,
        bazel_path,
        config,
        extra_flags_bazelrc,
        extra_generator_flags,
        generator_build_file,
        generator_defs_bzl,
        is_fixture,
        project_name,
        runner_label,
        schemes_json,
        template,
        temporary_directory,
        xcode_version,
        xcodeproj_bazelrc):
    output = actions.declare_file("{}-runner.sh".format(name))

    is_bazel_6 = hasattr(apple_common, "link_multi_arch_static_library")

    temp_package_directory = temporary_directory
    generator_package_directory = paths.join(
        temp_package_directory,
        paths.join(
            paths.dirname(generator_build_file.short_path),
            name,
        ).replace("/", "_"),
    )
    generator_label = "//{}:{}".format(generator_package_directory, name)

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%bazel_path%": bazel_path,
            "%config%": config,
            "%extra_flags_bazelrc%": extra_flags_bazelrc.short_path,
            "%extra_generator_flags%": extra_generator_flags,
            "%generator_label%": generator_label,
            "%generator_build_file%": generator_build_file.short_path,
            "%generator_defs_bzl%": generator_defs_bzl.short_path,
            "%generator_package_directory%": generator_package_directory,
            "%is_bazel_6%": "1" if is_bazel_6 else "0",
            "%is_fixture%": "1" if is_fixture else "0",
            "%project_name%": project_name,
            "%schemes_json%": schemes_json.short_path,
            "%runner_label%": runner_label,
            "%temp_package_directory%": temp_package_directory,
            "%xcode_version%": xcode_version,
            "%xcodeproj_bazelrc%": xcodeproj_bazelrc.short_path,
        },
    )

    return output

def _xcodeproj_runner_impl(ctx):
    actions = ctx.actions
    attr = ctx.attr
    config = ctx.attr.config
    is_fixture = ctx.attr.is_fixture
    name = ctx.attr.name
    project_name = ctx.attr.project_name
    repo = str(ctx.attr._generator_defs_bzl_template.label).split("//", 1)[0]

    xcode_version = _get_xcode_product_version(
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )

    xcodeproj_bazelrc = _write_xcodeproj_bazelrc(
        actions = actions,
        config = config,
        name = name,
        template = ctx.file._bazelrc_template,
    )
    extra_flags_bazelrc = _write_extra_flags_bazelrc(
        actions = actions,
        attr = attr,
        config = config,
        name = name,
    )
    schemes_json = _write_schemes_json(
        actions = actions,
        name = name,
        schemes_json = ctx.attr.schemes_json,
    )
    generator_build_file = _write_generator_build_file(
        actions = actions,
        attr = attr,
        build_file_path = ctx.build_file_path,
        name = name,
        template = ctx.file._generator_package_contents_template,
    )
    generator_defs_bzl = _write_generator_defz_bzl(
        actions = actions,
        attr = attr,
        is_fixture = is_fixture,
        name = name,
        repo = repo,
        template = ctx.file._generator_defs_bzl_template,
    )

    runner = _write_runner(
        name = name,
        actions = actions,
        bazel_path = ctx.attr.bazel_path,
        config = config,
        extra_flags_bazelrc = extra_flags_bazelrc,
        extra_generator_flags = (
            ctx.attr._extra_generator_flags[BuildSettingInfo].value
        ),
        generator_build_file = generator_build_file,
        generator_defs_bzl = generator_defs_bzl,
        is_fixture = is_fixture,
        project_name = project_name,
        runner_label = str(ctx.label),
        schemes_json = schemes_json,
        template = ctx.file._runner_template,
        temporary_directory = ctx.attr.temporary_directory,
        xcode_version = xcode_version,
        xcodeproj_bazelrc = xcodeproj_bazelrc,
    )

    return [
        DefaultInfo(
            executable = runner,
            runfiles = ctx.runfiles(
                files = [
                    extra_flags_bazelrc,
                    generator_build_file,
                    generator_defs_bzl,
                    schemes_json,
                    xcodeproj_bazelrc,
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
        "adjust_schemes_for_swiftui_previews": attr.bool(
            default = False,
            mandatory = True,
        ),
        "build_mode": attr.string(
            mandatory = True,
            values = ["xcode", "bazel"],
        ),
        "bazel_path": attr.string(
            mandatory = True,
        ),
        "config": attr.string(
            mandatory = True,
        ),
        "default_xcode_configuration": attr.string(),
        "focused_targets": attr.string_list(
            default = [],
        ),
        "install_directory": attr.string(
            mandatory = True,
        ),
        "is_fixture": attr.bool(
            mandatory = True,
        ),
        "minimum_xcode_version": attr.string(),
        "owned_extra_files": attr.string_dict(),
        "post_build": attr.string(),
        "pre_build": attr.string(),
        "project_options": attr.string_dict(
            mandatory = True,
        ),
        "project_name": attr.string(
            mandatory = True,
        ),
        "runner_label": attr.string(),
        "scheme_autogeneration_mode": attr.string(
            default = "auto",
            values = ["auto", "none", "all"],
        ),
        "schemes_json": attr.string(),
        "temporary_directory": attr.string(
            mandatory = True,
        ),
        "top_level_device_targets": attr.string_list(),
        "top_level_simulator_targets": attr.string_list(),
        "unfocused_targets": attr.string_list(
            default = [],
        ),
        "unowned_extra_files": attr.string_list(),
        "xcode_configuration_flags": attr.string_list(
            mandatory = True,
        ),
        "xcode_configurations": attr.string(
            mandatory = True,
        ),
        "ios_device_cpus": attr.string(
            mandatory = True,
        ),
        "ios_simulator_cpus": attr.string(),
        "tvos_device_cpus": attr.string(
            mandatory = True,
        ),
        "tvos_simulator_cpus": attr.string(),
        "watchos_device_cpus": attr.string(
            mandatory = True,
        ),
        "watchos_simulator_cpus": attr.string(),
        "_bazelrc_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:xcodeproj.template.bazelrc"),
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
        "_generator_defs_bzl_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal:generator.defs.template.bzl",
            ),
        ),
        "_generator_package_contents_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal:generator.BUILD.template.bazel",
            ),
        ),
        "_runner_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:runner.template.sh"),
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    },
    executable = True,
)

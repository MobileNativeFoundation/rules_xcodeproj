"""Implementation of the `xcodeproj_runner` rule."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
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

def _write_execution_root_file(*, ctx):
    output = ctx.actions.declare_file("{}_execution_root_file".format(ctx.attr.name))

    ctx.actions.run_shell(
        outputs = [output],
        command = """\
bin_dir_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{bin_dir_full}";)"
execution_root="${{bin_dir_full_path%/{bin_dir_full}}}"

echo "$execution_root" > "{out_full}"
""".format(
            bin_dir_full = ctx.bin_dir.path,
            out_full = output.path,
        ),
        mnemonic = "CalculateXcodeProjExecutionRoot",
        # This has to run locally
        execution_requirements = {
            "local": "1",
            "no-remote": "1",
            "no-sandbox": "1",
        },
    )

    return output

def _write_schemes_json(*, actions, name, schemes_json):
    output = actions.declare_file(
        "{}-custom_xcode_schemes.json".format(name),
    )
    actions.write(output, schemes_json if schemes_json else "[]")
    return output

_APPEND_TRANSITION_FLAGS = {
    "//command_line_option:features": None,
}

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
    outputs = attr.xcode_configuration_flags

    inputs = {
        flag: None
        for flag in outputs
        if flag in _APPEND_TRANSITION_FLAGS
    }

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
_INPUTS = {inputs}

_XCODE_CONFIGURATIONS = {xcode_configurations}

def _target_transition_implementation(settings, _attr):
    outputs = {{}}
    for configuration, flags in _XCODE_CONFIGURATIONS.items():
        config_outputs = {{}}
        for key, value in flags.items():
            if key in _INPUTS:
                # Only array settings, like "//command_line_option:features"
                # will hit this path, and we want to append instead of replace
                config_outputs[key] = settings[key] + value
            else:
                config_outputs[key] = value
        outputs[configuration] = config_outputs
    return outputs

_target_transitions = make_xcodeproj_target_transitions(
    implementation = _target_transition_implementation,
    inputs = _INPUTS.keys(),
    outputs = {outputs},
)""".format(
        inputs = str(inputs),
        outputs = outputs,
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
        install_path,
        name,
        runner_label,
        repo,
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
            "%colorize%": str(attr._colorize[BuildSettingInfo].value),
            "%config%": attr.config,
            "%default_xcode_configuration%": (
                _serialize_nullable_string(attr.default_xcode_configuration)
            ),
            "%fail_for_invalid_extra_files_targets%": (
                str(attr.fail_for_invalid_extra_files_targets)
            ),
            "%focused_targets%": str(attr.focused_targets),
            "%install_directory%": attr.install_directory,
            "%install_path%": install_path,
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
            "%runner_label%": runner_label,
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
            "%visibility%": "{repo}//xcodeproj:__pkg__".format(repo = repo),
            "%watchos_device_cpus%": attr.watchos_device_cpus,
            "%watchos_simulator_cpus%": attr.watchos_simulator_cpus,
            "%xcode_configuration_map%": str(attr.xcode_configuration_map),
        },
    )

    return output

def _write_runner(
        *,
        actions,
        bazel_env,
        bazel_path,
        config,
        execution_root_file,
        extra_flags_bazelrc,
        extra_generator_flags,
        generator_build_file,
        generator_defs_bzl,
        install_path,
        is_fixture,
        name,
        package,
        runner_label,
        schemes_json,
        template,
        xcode_version,
        xcodeproj_bazelrc):
    output = actions.declare_file("{}-runner.sh".format(name))

    base_def_env_values = []
    base_envs_values = []
    collect_statements = []
    for key, value in bazel_env.items():
        if value == "\0":
            collect_statements.append("""\
if [[ -n "${{{key}:-}}" ]]; then
  envs+=("{key}=${key}")
  def_env+="  \\"{key}\\": \\"${key}\\",
"
fi
""".format(key = key))
        else:
            base_def_env_values.append('  "{}": """{}""",'.format(
                key,
                (value
                    .replace(
                    # Escape backslashes for bzl
                    "\\",
                    "\\\\",
                )
                    .replace(
                    # Escape double quotes for bzl
                    "\"",
                    "\\\"",
                )
                    .replace(
                    # Escape single quotes for bash
                    "'",
                    "'\"'\"'",
                )),
            ))
            base_envs_values.append("  '{}={}'".format(
                key,
                (value
                    .replace(
                    # Escape single quotes for bash
                    "'",
                    "'\"'\"'",
                )),
            ))

    collect_bazel_env = """\
envs=(
{base_envs_values}
)
def_env='{{
{base_def_env_values}
'

{collect_statements}
def_env+='}}'""".format(
        base_def_env_values = "\n".join(base_def_env_values),
        base_envs_values = "\n".join(base_envs_values),
        collect_statements = "\n".join(collect_statements),
    )

    is_bazel_6 = hasattr(apple_common, "link_multi_arch_static_library")

    generator_package_name = paths.join("generator", package, name)
    generator_label = "{repo}//{package}".format(
        package = generator_package_name,
        repo = (
            str(Label("@rules_xcodeproj_generated//:BUILD")).split("//", 1)[0]
        ),
    )

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%bazel_path%": bazel_path,
            "%collect_bazel_env%": collect_bazel_env,
            "%config%": config,
            "%execution_root_file%": execution_root_file.short_path,
            "%extra_flags_bazelrc%": extra_flags_bazelrc.short_path,
            "%extra_generator_flags%": extra_generator_flags,
            "%generator_label%": generator_label,
            "%generator_build_file%": generator_build_file.short_path,
            "%generator_defs_bzl%": generator_defs_bzl.short_path,
            "%generator_package_name%": generator_package_name,
            "%install_path%": install_path,
            "%is_bazel_6%": "1" if is_bazel_6 else "0",
            "%is_fixture%": "1" if is_fixture else "0",
            "%runner_label%": runner_label,
            "%schemes_json%": schemes_json.short_path,
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
    repo = (
        str(ctx.attr._generator_defs_bzl_template.label).split("//", 1)[0] or
        "@"
    )
    runner_label = str(ctx.label)

    install_path = paths.join(
        ctx.attr.install_directory,
        "{}.xcodeproj".format(project_name),
    )

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
    execution_root_file = _write_execution_root_file(ctx = ctx)
    schemes_json = _write_schemes_json(
        actions = actions,
        name = name,
        schemes_json = ctx.attr.schemes_json,
    )
    generator_build_file = _write_generator_build_file(
        actions = actions,
        attr = attr,
        build_file_path = ctx.build_file_path,
        install_path = install_path,
        name = name,
        runner_label = runner_label,
        repo = repo,
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
        package = ctx.label.package,
        actions = actions,
        bazel_env = ctx.attr.bazel_env,
        bazel_path = ctx.attr.bazel_path,
        config = config,
        execution_root_file = execution_root_file,
        extra_flags_bazelrc = extra_flags_bazelrc,
        extra_generator_flags = (
            ctx.attr._extra_generator_flags[BuildSettingInfo].value
        ),
        generator_build_file = generator_build_file,
        generator_defs_bzl = generator_defs_bzl,
        install_path = install_path,
        is_fixture = is_fixture,
        runner_label = runner_label,
        schemes_json = schemes_json,
        template = ctx.file._runner_template,
        xcode_version = xcode_version,
        xcodeproj_bazelrc = xcodeproj_bazelrc,
    )

    return [
        DefaultInfo(
            executable = runner,
            runfiles = ctx.runfiles(
                files = [
                    execution_root_file,
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
            default = True,
            mandatory = True,
        ),
        "build_mode": attr.string(
            mandatory = True,
            values = ["xcode", "bazel"],
        ),
        "bazel_path": attr.string(
            mandatory = True,
        ),
        "bazel_env": attr.string_dict(
            mandatory = True,
        ),
        "config": attr.string(
            mandatory = True,
        ),
        "default_xcode_configuration": attr.string(),
        "fail_for_invalid_extra_files_targets": attr.bool(
            default = True,
        ),
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
        "scheme_autogeneration_mode": attr.string(
            default = "auto",
            values = ["auto", "none", "all"],
        ),
        "schemes_json": attr.string(),
        "top_level_device_targets": attr.string_list(),
        "top_level_simulator_targets": attr.string_list(),
        "unfocused_targets": attr.string_list(
            default = [],
        ),
        "unowned_extra_files": attr.string_list(),
        "xcode_configuration_flags": attr.string_list(
            mandatory = True,
        ),
        "xcode_configuration_map": attr.string_list_dict(
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
        "_colorize": attr.label(
            default = Label("//xcodeproj:color"),
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

"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")
load(
    "//xcodeproj/internal/bazel_integration_files:actions.bzl",
    "write_bazel_build_script",
)
load(
    "//xcodeproj/internal/files:incremental_input_files.bzl",
    input_files = "incremental_input_files",
)
load(
    "//xcodeproj/internal/files:incremental_output_files.bzl",
    "output_groups",
)
load(
    "//xcodeproj/internal/xcschemes:xcscheme_infos.bzl",
    xcscheme_infos_module = "xcscheme_infos",
)
load(
    "//xcodeproj/internal/xcschemes:xcschemes_execution.bzl",
    "xcschemes_execution",
)
load(":collections.bzl", "uniq")
load(":execution_root.bzl", "write_execution_root_file")
load(
    "extension_point_identifiers.bzl",
    "write_extension_point_identifiers_file",
)
load(":incremental_xcode_targets.bzl", xcode_targets_module = "incremental_xcode_targets")
load(":selected_model_versions.bzl", "write_selected_model_versions_file")
load(":target_id.bzl", "write_target_ids_list")
load(":xcodeprojinfo.bzl", "XcodeProjInfo")

# Utility

def _calculate_infos(
        *,
        targets,
        top_level_deps,
        transition_key,
        xcode_configuration_map):
    infos = [
        _process_dep(dep)
        for dep in targets[transition_key]
    ]

    target_environment_top_level_deps = {
        top_level_focused_deps.label: struct(
            id = top_level_focused_deps.id,
            deps = {d.label: d.id for d in top_level_focused_deps.deps},
        )
        for top_level_focused_deps in depset(
            transitive = [
                info.top_level_focused_deps
                for info in infos
            ],
        ).to_list()
    }

    for xcode_configuration in xcode_configuration_map[transition_key]:
        top_level_deps[xcode_configuration] = target_environment_top_level_deps

    return infos

def _calculate_infos_and_top_level_deps(
        *,
        device_targets,
        simulator_targets,
        xcode_configuration_map):
    infos = []
    infos_per_xcode_configuration = {}
    simulator_top_level_deps = {}
    device_top_level_deps = {}
    for key in uniq(simulator_targets.keys() + device_targets.keys()):
        if simulator_targets:
            simulator_infos = _calculate_infos(
                targets = simulator_targets,
                top_level_deps = simulator_top_level_deps,
                transition_key = key,
                xcode_configuration_map = xcode_configuration_map,
            )
            infos.extend(simulator_infos)
        else:
            simulator_infos = []

        if device_targets:
            device_infos = _calculate_infos(
                targets = device_targets,
                top_level_deps = device_top_level_deps,
                transition_key = key,
                xcode_configuration_map = xcode_configuration_map,
            )
            infos.extend(device_infos)
        else:
            device_infos = []

        configuration_infos = simulator_infos + device_infos
        for xcode_configuration in xcode_configuration_map[key]:
            infos_per_xcode_configuration[xcode_configuration] = (
                configuration_infos
            )

    if not device_top_level_deps:
        device_top_level_deps = simulator_top_level_deps
    elif not simulator_top_level_deps:
        simulator_top_level_deps = device_top_level_deps

    top_level_deps = {
        "device": device_top_level_deps,
        "simulator": simulator_top_level_deps,
    }

    return (infos, infos_per_xcode_configuration, top_level_deps)

def _collect_files(
        *,
        owned_extra_files,
        resource_bundle_xcode_targets,
        unowned_extra_files,
        unsupported_extra_files,
        xcode_targets):
    target_extra_files = {}
    for files_target, target_label_strs_json in owned_extra_files.items():
        for target_label_str in json.decode(target_label_strs_json):
            target_extra_files.setdefault(target_label_str, []).append(
                files_target.files,
            )

    all_targets = xcode_targets.values() + resource_bundle_xcode_targets

    compile_stub_needed = False
    infoplists = []
    transitive_file_paths = []
    transitive_files = [unsupported_extra_files]
    transitive_generated_file_paths = []
    transitive_srcs = []
    for xcode_target in all_targets:
        transitive_file_paths.append(xcode_target.inputs.extra_file_paths)
        transitive_files.append(xcode_target.inputs.extra_files)
        transitive_generated_file_paths.append(
            xcode_target.inputs.extra_generated_file_paths,
        )
        transitive_srcs.append(xcode_target.inputs.non_arc_srcs)
        transitive_srcs.append(xcode_target.inputs.srcs)

        label = xcode_target.label
        if label:
            extra_files_list = target_extra_files.get(str(label))
            if extra_files_list:
                transitive_files.extend(extra_files_list)

        infoplist = xcode_target.inputs.infoplist
        if infoplist:
            infoplists.append(infoplist)

        if xcode_target.compile_stub_needed:
            compile_stub_needed = True

    srcs = depset(transitive = transitive_srcs)
    transitive_files.append(srcs)

    file_paths = depset(transitive = transitive_file_paths)
    files = depset(
        unowned_extra_files,
        transitive = transitive_files,
    )
    generated_file_paths = depset(transitive = transitive_generated_file_paths)

    return (
        compile_stub_needed,
        file_paths,
        files,
        generated_file_paths,
        infoplists,
        srcs,
    )

def _get_minimum_xcode_version(*, xcode_config):
    version = str(xcode_config.xcode_version())
    if not version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")
    return ".".join(version.split(".")[0:3])

def _process_dep(dep):
    info = dep[XcodeProjInfo]

    if info.non_top_level_rule_kind:
        fail(
            """
'{label}' is not a top-level target, but was listed in `top_level_targets`. \
Only list top-level targets (e.g. binaries, apps, tests, or distributable \
frameworks) in `top_level_targets`. Schemes and \
`focused_targets`/`unfocused_targets` can refer to dependencies of targets \
listed in `top_level_targets`, and don't need to be listed in \
`top_level_targets` themselves.

If you feel this is an error, and `{kind}` targets should be recognized as \
top-level targets, file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""".format(label = dep.label, kind = info.non_top_level_rule_kind),
        )

    return info

# Actions

def _write_autogeneration_config_file(
        actions,
        config,
        name):
    autogeneration_config_file = actions.declare_file(
        "{}-autogeneration-config-file".format(name),
    )

    args = actions.args()
    args.set_param_file_format("multiline")

    args.add_all(config.get("test_options", ["", "", False]))
    args.add_all(
        config.get("scheme_name_exclude_patterns", []),
        omit_if_empty = False,
        terminate_with = "",
    )
    actions.write(autogeneration_config_file, args)

    return autogeneration_config_file

def _write_bazel_integration_files(
        *,
        actions,
        bazel_build_script_template,
        bazel_path,
        bazel_env,
        colorize,
        infos_per_xcode_configuration,
        install_path,
        label,
        name,
        static_files,
        swift_debug_settings_generator,
        target_ids_list):
    bazel_build_script = write_bazel_build_script(
        actions = actions,
        bazel_env = bazel_env,
        bazel_path = bazel_path,
        generator_label = label,
        target_ids_list = target_ids_list,
        template = bazel_build_script_template,
    )

    swift_debug_settings = xcode_targets_module.write_swift_debug_settings(
        actions = actions,
        colorize = colorize,
        generator_name = name,
        infos_per_xcode_configuration = infos_per_xcode_configuration,
        install_path = install_path,
        tool = swift_debug_settings_generator,
    )

    return [bazel_build_script] + swift_debug_settings + static_files

def _write_installer(
        *,
        actions,
        bazel_integration_files,
        config,
        contents_xcworkspacedata,
        generated_directories_filelist,
        generated_xcfilelist,
        install_path,
        is_fixture,
        name,
        project_pbxproj,
        template,
        xcschememanagement,
        xcschemes):
    installer = actions.declare_file(
        "{}-installer.sh".format(name),
    )

    actions.expand_template(
        template = template,
        output = installer,
        is_executable = True,
        substitutions = {
            "%bazel_integration_files%": shell.array_literal(
                [f.short_path for f in bazel_integration_files],
            ),
            "%config%": config,
            "%contents_xcworkspacedata%": contents_xcworkspacedata.short_path,
            "%generated_directories_filelist%": (
                generated_directories_filelist.short_path
            ),
            "%generated_xcfilelist%": generated_xcfilelist.short_path,
            "%is_fixture%": "1" if is_fixture else "0",
            "%output_path%": install_path,
            "%project_pbxproj%": project_pbxproj.short_path,
            "%xcschememanagement%": xcschememanagement.short_path,
            "%xcschemes%": xcschemes.short_path,
        },
    )

    runfiles = bazel_integration_files + [
        contents_xcworkspacedata,
        generated_directories_filelist,
        generated_xcfilelist,
        project_pbxproj,
        xcschememanagement,
        xcschemes,
    ]

    return (installer, runfiles)

def _write_project_contents(
        *,
        actions,
        bin_dir_path,
        colorize,
        config,
        default_xcode_configuration,
        files_and_groups_generator,
        generation_shard_count,
        import_index_build_indexstores,
        index_import,
        install_path,
        minimum_xcode_version,
        name,
        owned_extra_files,
        pbxnativetargets_generator,
        pbxproj_prefix_generator,
        pbxtargetdependencies_generator,
        platforms,
        post_build_script,
        pre_build_script,
        project_options,
        resource_bundle_xcode_targets,
        selected_model_versions_generator,
        target_name_mode,
        unique_directories,
        unowned_extra_files,
        unsupported_extra_files,
        workspace_directory,
        xccurrentversions,
        xcode_configurations,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    execution_root_file = write_execution_root_file(
        actions = actions,
        bin_dir_path = bin_dir_path,
        name = name,
    )

    selected_model_versions_file = write_selected_model_versions_file(
        actions = actions,
        name = name,
        tool = selected_model_versions_generator,
        xccurrentversions_files = xccurrentversions,
    )

    target_ids_list = write_target_ids_list(
        actions = actions,
        name = name,
        target_ids = xcode_targets.keys(),
    )

    (
        compile_stub_needed,
        file_paths,
        files,
        generated_file_paths,
        infoplists,
        srcs,
    ) = _collect_files(
        owned_extra_files = owned_extra_files,
        resource_bundle_xcode_targets = resource_bundle_xcode_targets,
        unowned_extra_files = unowned_extra_files,
        unsupported_extra_files = unsupported_extra_files,
        xcode_targets = xcode_targets,
    )

    # PBXProj partials

    (
        pbxtargetdependencies,
        pbxproject_targets,
        pbxproject_target_attributes,
        consolidation_maps,
    ) = pbxproj_partials.write_pbxtargetdependencies(
        actions = actions,
        colorize = colorize,
        generator_name = name,
        install_path = install_path,
        minimum_xcode_version = minimum_xcode_version,
        target_name_mode = target_name_mode,
        shard_count = generation_shard_count,
        xcode_target_configurations = xcode_target_configurations,
        xcode_targets_by_label = xcode_targets_by_label,
        tool = pbxtargetdependencies_generator,
    )

    (
        target_partials,
        buildfile_subidentifiers_files,
    ) = pbxproj_partials.write_targets(
        actions = actions,
        colorize = colorize,
        consolidation_maps = consolidation_maps,
        default_xcode_configuration = default_xcode_configuration,
        generator_name = name,
        install_path = install_path,
        tool = pbxnativetargets_generator,
        xcode_target_configurations = xcode_target_configurations,
        xcode_targets = xcode_targets,
        xcode_targets_by_label = xcode_targets_by_label,
    )

    (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    ) = pbxproj_partials.write_files_and_groups(
        actions = actions,
        buildfile_subidentifiers_files = buildfile_subidentifiers_files,
        colorize = colorize,
        compile_stub_needed = compile_stub_needed,
        execution_root_file = execution_root_file,
        files = files,
        file_paths = file_paths,
        generated_file_paths = generated_file_paths,
        generator_name = name,
        install_path = install_path,
        project_options = project_options,
        selected_model_versions_file = selected_model_versions_file,
        tool = files_and_groups_generator,
        workspace_directory = workspace_directory,
    )

    pbxproj_prefix = pbxproj_partials.write_pbxproj_prefix(
        actions = actions,
        colorize = colorize,
        config = config,
        default_xcode_configuration = default_xcode_configuration,
        execution_root_file = execution_root_file,
        generator_name = name,
        import_index_build_indexstores = import_index_build_indexstores,
        index_import = index_import,
        install_path = install_path,
        minimum_xcode_version = minimum_xcode_version,
        platforms = platforms,
        post_build_script = post_build_script,
        pre_build_script = pre_build_script,
        project_options = project_options,
        resolved_repositories_file = resolved_repositories_file,
        target_ids_list = target_ids_list,
        tool = pbxproj_prefix_generator,
        xcode_configurations = xcode_configurations,
        workspace_directory = workspace_directory,
    )

    # `project.pbxproj`

    project_pbxproj = pbxproj_partials.write_project_pbxproj(
        actions = actions,
        files_and_groups = files_and_groups,
        generator_name = name,
        pbxproj_prefix = pbxproj_prefix,
        pbxproject_known_regions = pbxproject_known_regions,
        pbxproject_target_attributes = pbxproject_target_attributes,
        pbxproject_targets = pbxproject_targets,
        pbxtargetdependencies = pbxtargetdependencies,
        targets = target_partials,
    )

    # `.xcfilelist`s

    (
        generated_directories_filelist
    ) = pbxproj_partials.write_generated_directories_filelist(
        actions = actions,
        generator_name = name,
        infoplists = infoplists,
        install_path = install_path,
        srcs = srcs,
        tool = unique_directories,
    )
    generated_xcfilelist = pbxproj_partials.write_generated_xcfilelist(
        actions = actions,
        generator_name = name,
        infoplists = infoplists,
        srcs = srcs,
    )

    return (
        project_pbxproj,
        generated_directories_filelist,
        generated_xcfilelist,
        consolidation_maps.keys(),
        target_ids_list,
    )

def _write_schemes(
        *,
        actions,
        autogeneration_mode,
        autogeneration_config,
        colorize,
        consolidation_maps,
        default_xcode_configuration,
        extension_point_identifiers_parser,
        infos,
        install_path,
        name,
        top_level_deps,
        workspace_directory,
        xcschemes_generator,
        xcschemes_json):
    extension_point_identifiers_file = write_extension_point_identifiers_file(
        actions = actions,
        extension_infoplists = depset(
            transitive = [
                info.extension_infoplists
                for info in infos
            ],
        ).to_list(),
        name = name,
        tool = extension_point_identifiers_parser,
    )

    xcscheme_infos = xcscheme_infos_module.from_json(
        xcschemes_json,
        default_xcode_configuration = default_xcode_configuration,
        top_level_deps = top_level_deps,
    )

    autogeneration_config_file = _write_autogeneration_config_file(
        actions = actions,
        config = autogeneration_config,
        name = name,
    )

    return xcschemes_execution.write_schemes(
        actions = actions,
        autogeneration_mode = autogeneration_mode,
        autogeneration_config_file = autogeneration_config_file,
        default_xcode_configuration = default_xcode_configuration,
        colorize = colorize,
        consolidation_maps = consolidation_maps,
        extension_point_identifiers_file = extension_point_identifiers_file,
        generator_name = name,
        hosted_targets = depset(
            transitive = [info.hosted_targets for info in infos],
        ),
        install_path = install_path,
        targets_args = {
            s.id: s.args
            for s in depset(
                transitive = [info.args for info in infos],
            ).to_list()
            if s.args
        },
        targets_env = {
            s.id: s.env
            for s in depset(
                transitive = [info.envs for info in infos],
            ).to_list()
            if s.env
        },
        tool = xcschemes_generator,
        workspace_directory = workspace_directory,
        xcscheme_infos = xcscheme_infos,
    )

# Rule

def _xcodeproj_incremental_impl(ctx):
    # `XcodeProjInfo`s and `xcode_target`s

    (
        infos,
        infos_per_xcode_configuration,
        top_level_deps,
    ) = _calculate_infos_and_top_level_deps(
        device_targets = ctx.split_attr.top_level_device_targets,
        simulator_targets = ctx.split_attr.top_level_simulator_targets,
        xcode_configuration_map = ctx.attr.xcode_configuration_map,
    )

    (
        additional_outputs,
        xcode_targets,
        xcode_targets_by_label,
        xcode_target_configurations,
    ) = xcode_targets_module.dicts_from_xcode_configurations(
        infos_per_xcode_configuration = infos_per_xcode_configuration,
        merged_target_ids = {
            dest: srcs
            for dest, srcs in depset(
                transitive = [
                    info.merged_target_ids
                    for info in infos
                ],
            ).to_list()
        },
    )

    if not xcode_targets:
        fail("""\
After removing unfocused targets, no targets remain. Please check your \
`xcodeproj.focused_targets` and `xcodeproj.unfocused_targets` attributes.

Are you using an `alias`? `xcodeproj.focused_targets` and \
`xcodeproj.unfocused_targets` requires labels of the actual targets.
""")

    # Shared values

    actions = ctx.actions
    colorize = ctx.attr.colorize
    config = ctx.attr.config
    index_import = ctx.executable._index_import
    install_path = ctx.attr.install_path
    is_fixture = ctx.attr._is_fixture
    name = ctx.attr.name
    workspace_directory = ctx.attr.workspace_directory

    inputs = input_files.merge(transitive_infos = infos)

    xcode_configurations = sorted(infos_per_xcode_configuration.keys())
    default_xcode_configuration = (
        ctx.attr.default_xcode_configuration or xcode_configurations[0]
    )

    # Project contents

    (
        project_pbxproj,
        generated_directories_filelist,
        generated_xcfilelist,
        consolidation_maps,
        target_ids_list,
    ) = _write_project_contents(
        actions = actions,
        bin_dir_path = ctx.bin_dir.path,
        colorize = colorize,
        config = config,
        default_xcode_configuration = default_xcode_configuration,
        files_and_groups_generator = ctx.executable._files_and_groups_generator,
        generation_shard_count = ctx.attr.generation_shard_count,
        import_index_build_indexstores = (
            ctx.attr.import_index_build_indexstores
        ),
        index_import = index_import,
        install_path = install_path,
        minimum_xcode_version = (
            ctx.attr.minimum_xcode_version or
            _get_minimum_xcode_version(
                xcode_config = (
                    ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
                ),
            )
        ),
        name = name,
        owned_extra_files = ctx.attr.owned_extra_files,
        pbxnativetargets_generator = (
            ctx.executable._pbxnativetargets_generator
        ),
        pbxproj_prefix_generator = ctx.executable._pbxproj_prefix_generator,
        pbxtargetdependencies_generator = (
            ctx.executable._pbxtargetdependencies_generator
        ),
        platforms = depset(transitive = [info.platforms for info in infos]),
        post_build_script = ctx.attr.post_build,
        pre_build_script = ctx.attr.pre_build,
        project_options = ctx.attr.project_options,
        resource_bundle_xcode_targets = (
            xcode_targets_module.from_resource_bundles(
                bundles = inputs.resource_bundles.to_list(),
                resource_bundle_ids = depset(
                    transitive = [
                        info.resource_bundle_ids
                        for info in infos
                    ],
                ).to_list(),
            )
        ),
        selected_model_versions_generator = (
            ctx.executable._selected_model_versions_generator
        ),
        target_name_mode = ctx.attr.target_name_mode,
        unique_directories = ctx.executable._unique_directories,
        unowned_extra_files = ctx.files.unowned_extra_files,
        unsupported_extra_files = inputs.unsupported_extra_files,
        workspace_directory = workspace_directory,
        xcode_target_configurations = xcode_target_configurations,
        xccurrentversions = inputs.xccurrentversions,
        xcode_configurations = xcode_configurations,
        xcode_targets = xcode_targets,
        xcode_targets_by_label = xcode_targets_by_label,
    )

    # Schemes

    (xcschemes, xcschememanagement) = _write_schemes(
        actions = actions,
        autogeneration_mode = ctx.attr.scheme_autogeneration_mode,
        autogeneration_config = ctx.attr.scheme_autogeneration_config,
        default_xcode_configuration = default_xcode_configuration,
        colorize = colorize,
        consolidation_maps = consolidation_maps,
        extension_point_identifiers_parser = (
            ctx.attr._extension_point_identifiers_parser[DefaultInfo].files_to_run
        ),
        infos = infos,
        install_path = install_path,
        name = name,
        top_level_deps = top_level_deps,
        workspace_directory = workspace_directory,
        xcschemes_generator = ctx.executable._xcschemes_generator,
        xcschemes_json = ctx.attr.xcschemes_json,
    )

    # Bazel integration files

    bazel_integration_files = _write_bazel_integration_files(
        actions = actions,
        bazel_build_script_template = ctx.file._bazel_build_script_template,
        bazel_path = ctx.attr.bazel_path,
        bazel_env = ctx.attr.bazel_env,
        colorize = colorize,
        infos_per_xcode_configuration = infos_per_xcode_configuration,
        install_path = install_path,
        label = ctx.label,
        name = name,
        static_files = ctx.files._bazel_integration_files,
        swift_debug_settings_generator = (
            ctx.executable._swift_debug_settings_generator
        ),
        target_ids_list = target_ids_list,
    )

    # Installer

    (installer, runfiles) = _write_installer(
        actions = actions,
        bazel_integration_files = bazel_integration_files,
        config = config,
        contents_xcworkspacedata = ctx.file._contents_xcworkspacedata,
        generated_directories_filelist = generated_directories_filelist,
        generated_xcfilelist = generated_xcfilelist,
        install_path = install_path,
        is_fixture = is_fixture,
        name = name,
        project_pbxproj = project_pbxproj,
        template = ctx.file._installer_template,
        xcschememanagement = xcschememanagement,
        xcschemes = xcschemes,
    )

    # Output Groups

    output_groups_fields = output_groups.to_output_groups_fields(
        additional_outputs = additional_outputs,
        target_output_groups = output_groups.merge(transitive_infos = infos),
    )

    # Providers

    return [
        DefaultInfo(
            executable = installer,
            files = depset(
                transitive = [inputs.important_generated],
            ),
            runfiles = ctx.runfiles(files = runfiles),
        ),
        OutputGroupInfo(
            all_targets = output_groups_fields["all_b"],
            index_import = depset([index_import]),
            target_ids_list = depset([target_ids_list]),
            **output_groups_fields
        ),
    ]

def _xcodeproj_incremental_attrs(
        *,
        is_fixture,
        target_transitions,
        xcodeproj_aspect):
    return {
        "bazel_env": attr.string_dict(mandatory = True),
        "bazel_path": attr.string(mandatory = True),
        "colorize": attr.bool(mandatory = True),
        "config": attr.string(mandatory = True),
        "default_xcode_configuration": attr.string(),
        "generation_shard_count": attr.int(mandatory = True),
        "import_index_build_indexstores": attr.bool(mandatory = True),
        "install_path": attr.string(mandatory = True),
        "minimum_xcode_version": attr.string(mandatory = True),
        "owned_extra_files": attr.label_keyed_string_dict(allow_files = True),
        "post_build": attr.string(mandatory = True),
        "pre_build": attr.string(mandatory = True),
        "project_options": attr.string_dict(mandatory = True),
        "runner_build_file": attr.string(mandatory = True),
        "runner_label": attr.string(mandatory = True),
        "scheme_autogeneration_config": attr.string_list_dict(mandatory = True),
        "scheme_autogeneration_mode": attr.string(mandatory = True),
        "target_name_mode": attr.string(mandatory = True),
        "top_level_device_targets": attr.label_list(
            cfg = target_transitions.device,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
            mandatory = True,
        ),
        "top_level_simulator_targets": attr.label_list(
            cfg = target_transitions.simulator,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
            mandatory = True,
        ),
        "unowned_extra_files": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "workspace_directory": attr.string(mandatory = True),
        "xcode_configuration_map": attr.string_list_dict(mandatory = True),
        "xcschemes_json": attr.string(),
        "_allowlist_function_transition": attr.label(
            default = Label(
                "@bazel_tools//tools/allowlists/function_transition_allowlist",
            ),
        ),
        "_bazel_build_script_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal/templates:bazel_build.sh",
            ),
        ),
        "_bazel_integration_files": attr.label(
            cfg = "exec",
            allow_files = True,
            default = Label(
                "//xcodeproj/internal/bazel_integration_files:bwb_integration_files",
            ),
        ),
        "_contents_xcworkspacedata": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal/templates:contents.xcworkspacedata",
            ),
        ),
        "_create_xcode_overlay_script_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal/templates:create_xcode_overlay.sh",
            ),
        ),
        "_extension_point_identifiers_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/extension_point_identifiers_parser"),
            executable = True,
        ),
        "_files_and_groups_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/files_and_groups:universal_files_and_groups",
            ),
            executable = True,
        ),
        "_index_import": attr.label(
            cfg = "exec",
            default = Label("@rules_xcodeproj_index_import//:index_import"),
            executable = True,
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal/templates:incremental_installer.sh",
            ),
        ),
        "_is_fixture": attr.bool(default = is_fixture),
        "_pbxnativetargets_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/pbxnativetargets:universal_pbxnativetargets",
            ),
            executable = True,
        ),
        "_pbxproj_prefix_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/pbxproj_prefix:universal_pbxproj_prefix",
            ),
            executable = True,
        ),
        "_pbxtargetdependencies_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/pbxtargetdependencies:universal_pbxtargetdependencies",
            ),
            executable = True,
        ),
        "_selected_model_versions_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/selected_model_versions",
            ),
            executable = True,
        ),
        "_swift_debug_settings_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/swift_debug_settings:universal_swift_debug_settings",
            ),
            executable = True,
        ),
        "_unique_directories": attr.label(
            cfg = "exec",
            default = Label("//tools/unique_directories"),
            executable = True,
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
        "_xcschemes_generator": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/generators/xcschemes:universal_xcschemes",
            ),
            executable = True,
        ),
    }

xcodeproj_incremental_rule = struct(
    attrs = _xcodeproj_incremental_attrs,
    impl = _xcodeproj_incremental_impl,
)

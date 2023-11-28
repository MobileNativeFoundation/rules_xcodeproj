"""Actions for creating `PBXProj` partials."""

load(
    ":memory_efficiency.bzl",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "FALSE_ARG",
    "TRUE_ARG",
)
load(":platforms.bzl", "PLATFORM_NAME")

# Utility

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _depset_len(depset):
    return str(len(depset.to_list()))

def _dynamic_framework_path(file_and_is_framework):
    file, is_framework = file_and_is_framework
    if is_framework:
        path = file.path
    else:
        path = file.dirname
    if path.startswith("bazel-out/"):
        return "$(BAZEL_OUT){}".format(path[9:])
    if path.startswith("external/"):
        return "$(BAZEL_EXTERNAL){}".format(path[8:])
    if path.startswith("../"):
        return "$(BAZEL_EXTERNAL){}".format(path[2:])
    if path.startswith("/"):
        return path
    return "$(SRCROOT)/{}".format(path)

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_FLAGS = struct(
    archs = "--archs",
    args_separator = "---",
    build_file_sub_identifiers_files = "--build-file-sub-identifiers-files",
    colorize = "--colorize",
    compile_stub_needed = "--compile-stub-needed",
    consolidation_map_output_paths = "--consolidation-map-output-paths",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    labels = "--labels",
    label_counts = "--label-counts",
    module_names = "--module-names",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    platforms = "--platforms",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    product_basenames = "--product-basenames",
    product_paths = "--product-paths",
    product_types = "--product-types",
    target_and_test_hosts = "--target-and-test-hosts",
    target_and_watch_kit_extensions = "--target-and-watch-kit-extensions",
    target_counts = "--target-counts",
    targets = "--targets",
    use_base_internationalization = "--use-base-internationalization",
    xcode_configuration_counts = "--xcode-configuration-counts",
    xcode_configurations = "--xcode-configurations",
)

def _write_files_and_groups(
        *,
        actions,
        buildfile_subidentifiers_files,
        colorize,
        compile_stub_needed,
        execution_root_file,
        files,
        file_paths,
        folders,
        generator_name,
        install_path,
        project_options,
        selected_model_versions_file,
        tool,
        workspace_directory):
    """Creates `File`s representing files and groups in a `.pbxproj`.

    Args:
        actions: `ctx.actions`.
        buildfile_subidentifiers_files: A `list` of `File`s that contain
            serialized `[Identifiers.BuildFile.SubIdentifier]`s.
        colorize: A `bool` indicating whether to colorize the output.
        compile_stub_needed: A `bool` indicating whether a compile stub is
            needed.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        files: A `depset` of `File`s  to include in the project.
        file_paths: A `depset` of file paths to files to include in the project.
            These are different from `files`, in order to handle normalized
            file paths.
        folders: A `depset` of paths to folders to include in the project.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        project_options: A `dict` as returned by `project_options`.
        selected_model_versions_file: A `File` that contains a JSON
            representation of `[BazelPath: String]`, mapping `.xcdatamodeld`
            file paths to selected `.xcdatamodel` file names.
        tool: The executable that will generate the output files.
        workspace_directory: The absolute path to the Bazel workspace
            directory.

    Returns:
        A tuple with three elements:

        *   `pbxproject_known_regions`: The `File` for the
            `PBXProject.knownRegions` `PBXProj` partial.
        *   `files_and_groups`: The `File` for the files and groups `PBXProj`
            partial.
        *   `resolved_repositories_file`: A `File` containing a string for the
            `RESOLVED_REPOSITORIES` build setting.
    """
    pbxproject_known_regions = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_known_regions".format(
            generator_name,
        ),
    )
    files_and_groups = actions.declare_file(
        "{}_pbxproj_partials/files_and_groups".format(
            generator_name,
        ),
    )
    resolved_repositories_file = actions.declare_file(
        "{}_pbxproj_partials/resolved_repositories_file".format(
            generator_name,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # filePaths

    file_paths_file = actions.declare_file(
        "{}_pbxproj_partials/file_paths_file".format(
            generator_name,
        ),
    )

    file_path_args = actions.args()
    file_path_args.set_param_file_format("multiline")

    file_path_args.add_all(files)

    # TODO: Consider moving normalization into `args.add_all.map_each`
    file_path_args.add_all(file_paths)

    actions.write(file_paths_file, file_path_args)

    # folderPaths

    folder_paths_file = actions.declare_file(
        "{}_pbxproj_partials/folder_paths_file".format(
            generator_name,
        ),
    )

    folder_path_args = actions.args()
    folder_path_args.set_param_file_format("multiline")

    folder_path_args.add_all(folders)

    actions.write(folder_paths_file, folder_path_args)

    # ... the rest

    # knownRegionsOutputPath
    args.add(pbxproject_known_regions)

    # filesAndGroupsOutputPath
    args.add(files_and_groups)

    # resolvedRepositoriesOutputPath
    args.add(resolved_repositories_file)

    # workspace
    args.add(workspace_directory)

    # installPath
    args.add(install_path)

    # executionRootFile
    args.add(execution_root_file)

    # selectedModelVersionsFile
    args.add(selected_model_versions_file)

    # filePathsFile
    args.add(file_paths_file)

    # folderPathsFile
    args.add(folder_paths_file)

    # developmentRegion
    args.add(project_options["development_region"])

    # useBaseInternationalization
    args.add(_FLAGS.use_base_internationalization)

    if compile_stub_needed:
        # compileStubNeeded
        args.add(_FLAGS.compile_stub_needed)

    # buildFileSubIdentifiersFiles
    args.add_all(
        _FLAGS.build_file_sub_identifiers_files,
        buildfile_subidentifiers_files,
    )

    # colorize
    if colorize:
        args.add(_FLAGS.colorize)

    message = "Generating {} files and groups partials".format(install_path)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            file_paths_file,
            folder_paths_file,
            execution_root_file,
            selected_model_versions_file,
        ] + buildfile_subidentifiers_files,
        outputs = [
            files_and_groups,
            pbxproject_known_regions,
            resolved_repositories_file,
        ],
        mnemonic = "WritePBXProjFileAndGroups",
        progress_message = message,
    )

    return (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    )

def _write_pbxproj_prefix(
        *,
        actions,
        apple_platform_to_platform_name = _apple_platform_to_platform_name,
        colorize,
        default_xcode_configuration,
        execution_root_file,
        generator_name,
        index_import,
        install_path,
        minimum_xcode_version,
        platforms,
        post_build_script,
        pre_build_script,
        project_options,
        resolved_repositories_file,
        target_ids_list,
        tool,
        workspace_directory,
        xcode_configurations):
    """Creates a `File` containing a `PBXProject` prefix `PBXProj` partial.

    Args:
        actions: `ctx.actions`.
        apple_platform_to_platform_name: Exposed for testing. Don't set.
        colorize: A `bool` indicating whether to colorize the output.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        generator_name: The name of the `xcodeproj` generator target.
        index_import: The executable `File` for the `index_import` tool.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
        platforms: A `depset` of `apple_platform`s.
        post_build_script: A `string` representing a post build script.
        pre_build_script: A `string` representing a pre build script.
        project_options: A `dict` as returned by `project_options`.
        resolved_repositories_file: A `File` containing containing a string for
            the `RESOLVED_REPOSITORIES` build setting.
        target_ids_list: A `File` containing a list of target IDs.
        tool: The executable that will generate the `PBXProj` partial.
        workspace_directory: The absolute path to the Bazel workspace
            directory.
        xcode_configurations: A sorted sequence of Xcode configuration names.

    Returns:
        The `File` for the `PBXProject` prefix `PBXProj` partial.
    """
    inputs = [execution_root_file, resolved_repositories_file]
    output = actions.declare_file(
        "{}_pbxproj_partials/pbxproj_prefix".format(
            generator_name,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # outputPath
    args.add(output)

    # workspace
    args.add(workspace_directory)

    # executionRootFile
    args.add(execution_root_file)

    # targetIdsFile
    args.add(target_ids_list)

    # indexImport
    args.add(index_import)

    # resolvedRepositoriesFile
    args.add(resolved_repositories_file)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # developmentRegion
    args.add(project_options["development_region"])

    # organizationName
    organization_name = project_options.get("organization_name")
    if organization_name:
        args.add(_FLAGS.organization_name, organization_name)

    # platforms
    args.add_all(
        _FLAGS.platforms,
        platforms,
        map_each = apple_platform_to_platform_name,
    )

    # xcodeConfigurations
    args.add_all(_FLAGS.xcode_configurations, xcode_configurations)

    # preBuildScript
    if pre_build_script:
        pre_build_script_output = actions.declare_file(
            "{}_pbxproj_partials/pre_build_script".format(
                generator_name,
            ),
        )
        actions.write(
            pre_build_script_output,
            pre_build_script,
        )
        inputs.append(pre_build_script_output)
        args.add(_FLAGS.pre_build_script, pre_build_script_output)

    # postBuildScript
    if post_build_script:
        post_build_script_output = actions.declare_file(
            "{}_pbxproj_partials/post_build_script".format(
                generator_name,
            ),
        )
        actions.write(
            post_build_script_output,
            post_build_script,
        )
        inputs.append(post_build_script_output)
        args.add(_FLAGS.post_build_script, post_build_script_output)

    # colorize
    if colorize:
        args.add(_FLAGS.colorize)

    message = "Generating {} PBXProj prefix partial".format(install_path)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = inputs,
        outputs = [output],
        mnemonic = "WritePBXProjPrefix",
        progress_message = message,
    )

    return output

def _write_pbxtargetdependencies(
        *,
        actions,
        apple_platform_to_platform_name = _apple_platform_to_platform_name,
        colorize,
        generator_name,
        install_path,
        minimum_xcode_version,
        shard_count,
        target_name_mode,
        tool,
        xcode_target_configurations,
        xcode_targets_by_label):
    """Creates `File`s representing consolidated target in a `PBXProj`.

    Args:
        actions: `ctx.actions`.
        apple_platform_to_platform_name: Exposed for testing. Don't set.
        colorize: A `bool` indicating whether to colorize the output.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        shard_count: The number of shards to split the computation of
            `PBXNativeTarget`s into.
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
        target_name_mode: How the name of Xcode targets should be generated.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets_by_label:  A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with four elements:

        *   `pbxtargetdependencies`: The `File` for the
            `PBXTargetDependency` and `PBXContainerItemProxy` `PBXProj` partial.
        *   `pbxproject_targets`: The `File` for the `PBXProject.targets`
            `PBXProj` partial.
        *   `pbxproject_target_attributes`: The `File` for the
            `PBXProject.attributes.TargetAttributes` `PBXProj` partial.
        *   `consolidation_maps`: A `dict` mapping `File`s containing
            target consolidation maps to a `list` of `Label`s of the targets
            included in the map.
    """
    pbxtargetdependencies = actions.declare_file(
        "{}_pbxproj_partials/pbxtargetdependencies".format(
            generator_name,
        ),
    )
    pbxproject_targets = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_targets".format(
            generator_name,
        ),
    )
    pbxproject_target_attributes = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_target_attributes".format(
            generator_name,
        ),
    )

    consolidation_maps_inputs_file = actions.declare_file(
        "{}_pbxproj_partials/consolidation_maps_inputs_file".format(
            generator_name,
        ),
    )

    bucketed_labels = {}
    for label in xcode_targets_by_label:
        bucketed_labels.setdefault(
            hash(label.name) % shard_count,
            [],
        ).append(label)

    consolidation_maps = {}

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # targetDependenciesOutputPath
    args.add(pbxtargetdependencies)

    # targetsOutputPath
    args.add(pbxproject_targets)

    # targetAttributesOutputPath
    args.add(pbxproject_target_attributes)

    # consolidationMapsInputsFile
    args.add(consolidation_maps_inputs_file)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    # targetNameMode
    args.add(target_name_mode)

    # Consolidation maps inputs

    for idx, bucket_labels in enumerate(bucketed_labels.values()):
        consolidation_map = actions.declare_file(
            "{}_pbxproj_partials/consolidation_maps/{}".format(
                generator_name,
                idx,
            ),
        )
        consolidation_maps[consolidation_map] = bucket_labels

    consolidation_map_args = actions.args()
    consolidation_map_args.set_param_file_format("multiline")

    consolidation_map_args.add(len(consolidation_maps))
    consolidation_map_args.add_all(
        consolidation_maps.keys(),
    )

    target_and_test_hosts = []
    target_and_watch_kit_extensions = []
    for bucket_labels in consolidation_maps.values():
        # labelCount
        consolidation_map_args.add(len(bucket_labels))

        for label in bucket_labels:
            consolidation_map_args.add(str(label))

            xcode_targets = xcode_targets_by_label[label].values()

            consolidation_map_args.add(len(xcode_targets))

            for xcode_target in xcode_targets:
                consolidation_map_args.add(xcode_target.id)
                consolidation_map_args.add(xcode_target.product.type)
                consolidation_map_args.add(
                    apple_platform_to_platform_name(
                        xcode_target.platform.apple_platform,
                    ),
                )
                consolidation_map_args.add(xcode_target.platform.os_version)
                consolidation_map_args.add(xcode_target.platform.arch)
                consolidation_map_args.add(
                    xcode_target.product.module_name_attribute or EMPTY_STRING,
                )
                consolidation_map_args.add(xcode_target.product.file_path)
                consolidation_map_args.add(xcode_target.product.basename)
                consolidation_map_args.add_all(
                    [xcode_target.dependencies],
                    map_each = _depset_len,
                )
                consolidation_map_args.add_all(xcode_target.dependencies)

                target_xcode_configurations = (
                    xcode_target_configurations[xcode_target.id]
                )
                consolidation_map_args.add(len(target_xcode_configurations))
                consolidation_map_args.add_all(target_xcode_configurations)

                if xcode_target.test_host:
                    target_and_test_hosts.append(xcode_target.id)
                    target_and_test_hosts.append(xcode_target.test_host)

                if xcode_target.watchkit_extension:
                    target_and_watch_kit_extensions.append(xcode_target.id)
                    target_and_watch_kit_extensions.append(
                        xcode_target.watchkit_extension,
                    )

    actions.write(consolidation_maps_inputs_file, consolidation_map_args)

    # targetAndTestHosts
    args.add_all(_FLAGS.target_and_test_hosts, target_and_test_hosts)

    # targetAndWatchKitExtensions
    args.add_all(
        _FLAGS.target_and_watch_kit_extensions,
        target_and_watch_kit_extensions,
    )

    # colorize
    if colorize:
        args.add(_FLAGS.colorize)

    message = "Generating {} PBXTargetDependencies partials".format(
        install_path,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [consolidation_maps_inputs_file],
        outputs = [
            pbxtargetdependencies,
            pbxproject_targets,
            pbxproject_target_attributes,
        ] + consolidation_maps.keys(),
        mnemonic = "WritePBXProjPBXTargetDependencies",
        progress_message = message,
    )

    return (
        pbxtargetdependencies,
        pbxproject_targets,
        pbxproject_target_attributes,
        consolidation_maps,
    )

def _write_target_build_settings(
        *,
        actions,
        apple_generate_dsym,
        certificate_name = None,
        colorize,
        conly_args,
        cxx_args,
        device_family = EMPTY_STRING,
        entitlements = None,
        extension_safe = False,
        generate_build_settings,
        include_self_swift_debug_settings = True,
        infoplist = None,
        is_top_level_target = False,
        name,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        provisioning_profile_is_xcode_managed = False,
        provisioning_profile_name = None,
        skip_codesigning = False,
        swift_args,
        swift_debug_settings_to_merge,
        team_id = None,
        tool):
    """Creates the `OTHER_SWIFT_FLAGS` build setting string file for a target.

    Args:
        actions: `ctx.actions`.
        apple_generate_dsym: `cpp_fragment.apple_generate_dsym`.
        certificate_name: The name of the certificate to use for code signing.
        colorize: A `bool` indicating whether to colorize the output.
        conly_args: A `list` of `Args` for the C compile action for this target.
        cxx_args: A `list` of `Args` for the C++ compile action for this target.
        device_family: A value as returned by `get_targeted_device_family`.
        entitlements: An optional entitlements `File`.
        extension_safe: If `True`, `APPLICATION_EXTENSION_API_ONLY` will be set.
        generate_build_settings: A `bool` indicating whether to generate build
            settings. This is mostly tied to if the target is focused or not.
        include_self_swift_debug_settings: A `bool` indicating whether to
            include the target's own Swift debug settings. Should be false for
            merged top-level targets.
        infoplist: An optional `File` containing the `Info.plist` for the
            target.
        is_top_level_target: A `bool` indicating whether this is a top level
            target.
        name: The name of the target.
        previews_dynamic_frameworks: A `list` of `(File, bool)` `tuple`s. If
            the `bool` is `True`, the file points to a dynamic framework. If
            `False`, the file points to an executable in a dynamic framework.
        previews_include_path: The Swift include path to add when building
            Xcode previews.
        provisioning_profile_is_xcode_managed: A `bool` indicating whether the
            provisioning profile is managed by Xcode.
        provisioning_profile_name: The name of the provisioning profile to use
            for code signing.
        skip_codesigning: If `True`, `CODE_SIGNING_ALLOWED = NO` will be set.
        swift_args: A `list` of `Args` for the `SwiftCompile` action for this
            target.
        swift_debug_settings_to_merge: A `depset` of `Files` containing
            Swift debug settings from dependencies.
        team_id: The team ID to use for code signing.
        tool: The executable that will generate the output files.

    Returns:
        A `tuple` with three elements:

        *   A `File` containing some build settings for the target, or `None`.
        *   A `File` containing Swift debug settings for the target, or `None`.
        *   A `list` of `File`s containing C or C++ compiler arguments. These
            files should be added to compile outputs groups to ensure that Xcode
            has them available for the `Create Compile Dependencies` build
            phase.
    """
    generate_swift_debug_settings = swift_args or is_top_level_target

    if not (generate_build_settings or generate_swift_debug_settings):
        return None, None, EMPTY_LIST

    outputs = []
    params = []

    args = actions.args()

    # colorize
    args.add(TRUE_ARG if colorize else FALSE_ARG)

    if generate_build_settings:
        build_settings_output = actions.declare_file(
            "{}.rules_xcodeproj.build_settings".format(name),
        )
        outputs.append(build_settings_output)

        # buildSettingsOutputPath
        args.add(build_settings_output)
    else:
        build_settings_output = None

        # buildSettingsOutputPath
        args.add("")

    if generate_swift_debug_settings:
        debug_settings_output = actions.declare_file(
            "{}.rules_xcodeproj.debug_settings".format(name),
        )
        outputs.append(debug_settings_output)

        # swiftDebugSettingsOutputPath
        args.add(debug_settings_output)

        # includeSelfSwiftDebugSettings
        args.add(TRUE_ARG if include_self_swift_debug_settings else FALSE_ARG)

        # transitiveSwiftDebugSettingPaths
        args.add_all([swift_debug_settings_to_merge], map_each = _depset_len)
        args.add_all(swift_debug_settings_to_merge)

        inputs = swift_debug_settings_to_merge
    else:
        debug_settings_output = None

        # swiftDebugSettingsOutputPath
        args.add("")

        inputs = []

    # deviceFamily
    args.add(device_family)

    # extensionSafe
    args.add(TRUE_ARG if extension_safe else FALSE_ARG)

    # generatesDsyms
    args.add(TRUE_ARG if apple_generate_dsym else FALSE_ARG)

    # infoPlist
    args.add(infoplist or EMPTY_STRING)

    # entitlements
    args.add(entitlements or EMPTY_STRING)

    # skipCodesigning
    args.add(TRUE_ARG if skip_codesigning else FALSE_ARG)

    # certificateName
    args.add(certificate_name or EMPTY_STRING)

    # provisioningProfileName
    args.add(provisioning_profile_name or EMPTY_STRING)

    # teamID
    args.add(team_id or EMPTY_STRING)

    # provisioningProfileIsXcodeManaged
    args.add(TRUE_ARG if provisioning_profile_is_xcode_managed else FALSE_ARG)

    # previewsFrameworkPaths
    args.add_joined(
        previews_dynamic_frameworks,
        format_each = '"%s"',
        map_each = _dynamic_framework_path,
        omit_if_empty = False,
        join_with = " ",
    )

    # previewsIncludePath
    args.add(previews_include_path)

    c_output_args = actions.args()

    # C argsSeparator
    c_output_args.add(_FLAGS.args_separator)

    if generate_build_settings and conly_args:
        c_params = actions.declare_file(
            "{}.c.compile.params".format(name),
        )
        params.append(c_params)
        outputs.append(c_params)

        # cParams
        c_output_args.add(c_params)

    cxx_output_args = actions.args()

    # Cxx argsSeparator
    cxx_output_args.add(_FLAGS.args_separator)

    if generate_build_settings and cxx_args:
        cxx_params = actions.declare_file(
            "{}.cxx.compile.params".format(name),
        )
        params.append(cxx_params)
        outputs.append(cxx_params)

        # cxxParams
        cxx_output_args.add(cxx_params)

    actions.run(
        arguments = (
            [args] + swift_args + [c_output_args] + conly_args +
            [cxx_output_args] + cxx_args
        ),
        executable = tool,
        inputs = inputs,
        outputs = outputs,
        progress_message = "Generating %{output}",
        mnemonic = "WriteTargetBuildSettings",
        execution_requirements = {
            # This action is very fast, and there are potentially thousands of
            # this action for a project, which results in caching overhead
            # slowing down clean builds. So, we disable remote cache/execution.
            # This also prevents DDoSing the remote cache.
            "no-remote": "1",
        },
    )

    return build_settings_output, debug_settings_output, params

pbxproj_partials = struct(
    write_files_and_groups = _write_files_and_groups,
    write_pbxproj_prefix = _write_pbxproj_prefix,
    write_pbxtargetdependencies = _write_pbxtargetdependencies,
    write_target_build_settings = _write_target_build_settings,
)

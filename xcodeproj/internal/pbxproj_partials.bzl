"""Actions for creating `PBXProj` partials."""

load(":memory_efficiency.bzl", "EMPTY_DEPSET", "EMPTY_STRING")
load(":platforms.bzl", "PLATFORM_NAME")

# Utility

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _depset_len(d):
    return str(len(d.to_list()))

def _depset_to_list(d):
    return d.to_list()

def _identity(seq):
    return seq

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_flags = struct(
    archs = "--archs",
    build_file_sub_identifiers_files = "--build-file-sub-identifiers-files",
    colorize = "--colorize",
    compile_stub_needed = "--compile-stub-needed",
    consolidation_map_output_paths = "--consolidation-map-output-paths",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    files_paths = "--file-paths",
    folder_paths = "--folder-paths",
    labels = "--labels",
    label_counts = "--label-counts",
    module_names = "--module-names",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    platforms = "--platforms",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    product_types = "--product-types",
    target_and_test_hosts = "--target-and-test-hosts",
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

    # developmentRegion
    args.add(project_options["development_region"])

    # useBaseInternationalization
    args.add(_flags.use_base_internationalization)

    if compile_stub_needed:
        # compileStubNeeded
        args.add(_flags.compile_stub_needed)

    # buildFileSubIdentifiersFiles
    args.add_all(
        _flags.build_file_sub_identifiers_files,
        buildfile_subidentifiers_files,
    )

    # filePaths
    if files != EMPTY_DEPSET or file_paths != EMPTY_DEPSET:
        args.add(_flags.files_paths)
        args.add_all(files)

        # TODO: Consider moving normalization into `args.add_all.map_each`
        args.add_all(file_paths)

    # folderPaths
    args.add_all(_flags.folder_paths, folders)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    message = "Generating {} files and groups partials".format(install_path)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
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
        build_mode,
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
        build_mode: `xcodeproj.build_mode`.
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

    # buildMode
    args.add(build_mode)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # developmentRegion
    args.add(project_options["development_region"])

    # organizationName
    organization_name = project_options.get("organization_name")
    if organization_name:
        args.add(_flags.organization_name, organization_name)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = apple_platform_to_platform_name,
    )

    # xcodeConfigurations
    args.add_all(_flags.xcode_configurations, xcode_configurations)

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
        args.add(_flags.pre_build_script, pre_build_script_output)

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
        args.add(_flags.post_build_script, post_build_script_output)

    # colorize
    if colorize:
        args.add(_flags.colorize)

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
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
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

    bucketed_labels = {}
    for label in xcode_targets_by_label:
        # FIXME: Fine-tune this, and make it configurable
        bucketed_labels.setdefault(hash(label.name) % 8, []).append(label)

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

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    archs = []
    dependencies = []
    dependency_counts = []
    label_counts = []
    labels = []
    module_names = []
    os_versions = []
    platforms = []
    product_types = []
    target_and_test_hosts = []
    target_counts = []
    target_ids = []
    xcode_configuration_counts = []
    xcode_configurations = []
    for idx, bucket_labels in enumerate(bucketed_labels.values()):
        consolidation_map = actions.declare_file(
            "{}_pbxproj_partials/consolidation_maps/{}".format(
                generator_name,
                idx,
            ),
        )
        consolidation_maps[consolidation_map] = bucket_labels

        label_counts.append(len(bucket_labels))
        for label in bucket_labels:
            labels.append(str(label))

            xcode_targets = xcode_targets_by_label[label].values()
            target_counts.append(len(xcode_targets))
            for xcode_target in xcode_targets:
                target_ids.append(xcode_target.id)
                product_types.append(xcode_target.product.type)
                platforms.append(xcode_target.platform.platform)
                os_versions.append(xcode_target.platform.os_version)
                archs.append(xcode_target.platform.arch)
                module_names.append(
                    xcode_target.product.module_name_attribute or EMPTY_STRING,
                )
                dependency_counts.append(xcode_target.dependencies)
                dependencies.append(xcode_target.dependencies)

                configurations = xcode_target_configurations[xcode_target.id]
                xcode_configuration_counts.append(len(configurations))
                xcode_configurations.append(configurations)

                if xcode_target.test_host:
                    target_and_test_hosts.append(xcode_target.id)
                    target_and_test_hosts.append(xcode_target.test_host)

    # targetAndTestHosts
    args.add_all(_flags.target_and_test_hosts, target_and_test_hosts)

    # consolidationMapOutputPaths
    args.add_all(
        _flags.consolidation_map_output_paths,
        consolidation_maps.keys(),
    )

    # labelCounts
    args.add_all(_flags.label_counts, label_counts)

    # labels
    args.add_all(_flags.labels, labels)

    # targetCounts
    args.add_all(_flags.target_counts, target_counts)

    # targets
    args.add_all(_flags.targets, target_ids)

    # xcodeConfigurationCounts
    args.add_all(
        _flags.xcode_configuration_counts,
        xcode_configuration_counts,
    )

    # xcodeConfigurations
    args.add_all(
        _flags.xcode_configurations,
        xcode_configurations,
        map_each = _identity,
    )

    # productTypes
    args.add_all(_flags.product_types, product_types)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = apple_platform_to_platform_name,
    )

    # osVersions
    args.add_all(_flags.os_versions, os_versions)

    # archs
    args.add_all(_flags.archs, archs)

    # moduleNames
    args.add_all(_flags.module_names, module_names)

    # dependencyCounts
    args.add_all(
        _flags.dependency_counts,
        dependency_counts,
        map_each = _depset_len,
    )

    # dependencies
    args.add_all(_flags.dependencies, dependencies, map_each = _depset_to_list)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    message = "Generating {} PBXTargetDependencies partials".format(
        install_path,
    )

    actions.run(
        arguments = [args],
        executable = tool,
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

pbxproj_partials = struct(
    write_files_and_groups = _write_files_and_groups,
    write_pbxproj_prefix = _write_pbxproj_prefix,
    write_pbxtargetdependencies = _write_pbxtargetdependencies,
)

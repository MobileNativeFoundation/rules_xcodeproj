"""Actions for creating `PBXProj` partials."""

load(":memory_efficiency.bzl", "EMPTY_DEPSET")
load(":platforms.bzl", "PLATFORM_NAME")

# Utility

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

# Partials

def _write_files_and_groups(
        *,
        actions,
        colorize,
        execution_root_file,
        files,
        file_paths,
        folders,
        generator_name,
        project_options,
        selected_model_versions_file,
        tool,
        workspace_directory):
    """
    Creates `File`s representing files and groups in a `.pbxproj`.

    Args:
        actions: `ctx.actions`.
        colorize: A `bool` indicating whether to colorize the output.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        files: A `depset` of `File`s  to include in the project.
        file_paths: A `depset` of file paths to files to include in the project.
            These are different from `files`, in order to handle normalized
            file paths.
        folders: A `depset` of paths to folders to include in the project.
        generator_name: The name of the `xcodeproj` generator target.
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

    # executionRootFile
    args.add(execution_root_file)

    # selectedModelVersionsFile
    args.add(selected_model_versions_file)

    # developmentRegion
    args.add(project_options["development_region"])

    # useBaseInternationalization
    args.add("--use-base-internationalization")

    # filePaths
    if files != EMPTY_DEPSET or file_paths != EMPTY_DEPSET:
        args.add("--file-paths")
        args.add_all(files)

        # TODO: Consider moving normalization into `args.add_all.map_each`
        args.add_all(file_paths)

    # folderPaths
    args.add_all("--folder-paths", folders)

    # colorize
    if colorize:
        args.add("--colorize")

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            execution_root_file,
            selected_model_versions_file,
        ],
        outputs = [
            pbxproject_known_regions,
            files_and_groups,
            resolved_repositories_file,
        ],
        mnemonic = "WritePBXProjFileAndGroups",
    )

    return (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    )

def _write_pbxproj_prefix(
        *,
        actions,
        build_mode,
        colorize,
        default_xcode_configuration,
        execution_root_file,
        generator_name,
        index_import,
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
    """
    Creates a `File` containing a `PBXProject` prefix `PBXProj` partial.

    Args:
        actions: `ctx.actions`.
        build_mode: `xcodeproj.build_mode`.
        colorize: A `bool` indicating whether to colorize the output.
        default_xcode_configuration: Optional. The name of the the Xcode
            configuration to use when building, if not overridden by custom
            schemes. If not set, the first Xcode configuration alphabetically
            will be used.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        generator_name: The name of the `xcodeproj` generator target.
        index_import: The executable `File` for the `index_import` tool.
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
        xcode_configurations: A sequence of Xcode configuration names.

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

    # developmentRegion
    args.add(project_options["development_region"])

    # organizationName
    organization_name = project_options.get("organization_name")
    if organization_name:
        args.add("--organization-name", organization_name)

    # platforms
    args.add_all(
        "--platforms",
        platforms,
        map_each = _apple_platform_to_platform_name,
    )

    # xcodeConfigurations
    args.add_all(
        "--xcode-configurations",
        xcode_configurations,
    )

    # defaultXcodeConfiguration
    if default_xcode_configuration:
        args.add("--default-xcode-configuration", default_xcode_configuration)

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
        args.add("--pre-build-script", pre_build_script_output)

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
        args.add("--post-build-script", post_build_script_output)

    # colorize
    if colorize:
        args.add("--colorize")

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = inputs,
        outputs = [output],
        mnemonic = "WritePBXProjPrefix",
    )

    return output

pbxproj_partials = struct(
    write_files_and_groups = _write_files_and_groups,
    write_pbxproj_prefix = _write_pbxproj_prefix,
)

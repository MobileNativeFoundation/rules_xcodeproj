"""Actions for creating `PBXProj` partials."""

load("//xcodeproj/internal/files:files.bzl", "join_paths_ignoring_empty")
load(":collections.bzl", "uniq")
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "FALSE_ARG",
    "TRUE_ARG",
)
load(":platforms.bzl", "platforms")

_UNIT_TEST_PRODUCT_TYPE = "u"  # com.apple.product-type.bundle.unit-test

# Utility

def _dsym_files_to_string(dsym_files):
    dsym_paths = []
    for file in dsym_files.to_list():
        file_path = file.path

        # dSYM files contain plist and DWARF.
        if not file_path.endswith("Info.plist"):
            # ../Product.dSYM/Contents/Resources/DWARF/Product
            dsym_path = "/".join(file_path.split("/")[:-4])
            dsym_paths.append("\"{}\"".format(dsym_path))
    return " ".join(dsym_paths)

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

def _keys_and_files(pair):
    key, file = pair
    return [key, file.path]

def _dirname(file):
    return file.dirname

def _generated_dirname(file):
    if file.is_source:
        return None

    return file.dirname

def _xcfilelist_always_generated_file_path(file):
    return "$(BAZEL_OUT){}".format(file.path[9:])

def _xcfilelist_generated_file_path(file):
    if file.is_source:
        return None

    return _xcfilelist_always_generated_file_path(file)

def _source_file(file):
    if not file.is_source:
        return None

    return file.path

def _generated_path(path, owner):
    components = path.split("/", 3)

    # bazel-out/CONFIG/bin/a/generated/file -> CONFIG
    config = components[1]

    repo_name = owner.workspace_name

    if repo_name:
        package = join_paths_ignoring_empty(
            "external",
            repo_name,
            owner.package,
        )
        offset = len(package) + 1
    else:
        package = owner.package
        if package:
            offset = len(package) + 1
        else:
            offset = 0

    # bazel-out/CONFIG/bin/some/package/a/generated/file -> a/generated/file
    path = components[3][offset:]

    return [path, package, config]

def _generated_file(file):
    if file.is_source:
        return None

    return _generated_path(file.path, file.owner)

def _generated_file_path(generated_file_path):
    return _generated_path(
        generated_file_path.path,
        generated_file_path.owner,
    )

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_FLAGS = struct(
    args_separator = "---",
    build_file_sub_identifiers_files = "--build-file-sub-identifiers-files",
    colorize = "--colorize",
    compile_stub_needed = "--compile-stub-needed",
    organization_name = "--organization-name",
    platforms = "--platforms",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    target_and_test_hosts = "--target-and-test-hosts",
    target_and_watch_kit_extensions = "--target-and-watch-kit-extensions",
    use_base_internationalization = "--use-base-internationalization",
    xcode_configurations = "--xcode-configurations",
)

def _write_consolidation_map_targets(
        *,
        actions,
        apple_platform_to_platform_name = (
            platforms.apple_platform_to_platform_name
        ),
        colorize,
        consolidation_map,
        default_xcode_configuration,
        generator_name,
        idx,
        install_path,
        labels,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element, for a \
    given consolidation map

    Args:
        actions: `ctx.actions`.
        apple_platform_to_platform_name: Exposed for testing. Don't set.
        colorize: Whether to colorize the output.
        consolidation_map: A `File` containing a target consolidation maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        idx: The index of the consolidation map.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        labels: A `list` of `Label`s of the targets included in
            `consolidation_map`.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with two elements:

        *   `pbxnativetargets`: A `File` for the `PBNativeTarget` `PBXProj`
            partial.
        *   `buildfile_subidentifiers`: A `File` that contain serialized
            `[Identifiers.BuildFile.SubIdentifier]`.
    """
    pbxnativetargets = actions.declare_file(
        "{}_pbxproj_partials/pbxnativetargets/{}".format(
            generator_name,
            idx,
        ),
    )
    buildfile_subidentifiers = actions.declare_file(
        "{}_pbxproj_partials/buildfile_subidentifiers/{}".format(
            generator_name,
            idx,
        ),
    )

    target_arguments_file = actions.declare_file(
        "{}_pbxproj_partials/target_arguments_files/{}".format(
            generator_name,
            idx,
        ),
    )
    top_level_target_attributes_file = actions.declare_file(
        "{}_pbxproj_partials/top_level_target_attributes_files/{}".format(
            generator_name,
            idx,
        ),
    )
    unit_test_host_attributes_file = actions.declare_file(
        "{}_pbxproj_partials/unit_test_host_attributes_files/{}".format(
            generator_name,
            idx,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # targetsOutputPath
    args.add(pbxnativetargets)

    # buildFileSubIdentifiersOutputPath
    args.add(buildfile_subidentifiers)

    # consolidationMap
    args.add(consolidation_map)

    # targetArgumentsFile
    args.add(target_arguments_file)

    # topLevelTargetAttributesFile
    args.add(top_level_target_attributes_file)

    # unitTestHostAttributesFile
    args.add(unit_test_host_attributes_file)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # Target arguments

    targets_args = actions.args()
    targets_args.set_param_file_format("multiline")

    top_level_targets_args = actions.args()
    top_level_targets_args.set_param_file_format("multiline")

    unit_test_hosts_args = actions.args()
    unit_test_hosts_args.set_param_file_format("multiline")

    target_count = 0
    for label in labels:
        target_count += len(xcode_targets_by_label[label])

    targets_args.add(target_count)

    build_settings_files = []
    unit_test_host_ids = []
    for label in labels:
        for xcode_target in xcode_targets_by_label[label].values():
            targets_args.add(xcode_target.id)
            targets_args.add(xcode_target.product.type)
            targets_args.add(xcode_target.package_bin_dir)
            targets_args.add(xcode_target.product.name)
            targets_args.add(xcode_target.product.basename)

            # TODO: Don't send if it would be the same as
            # `$(PRODUCT_NAME:c99extidentifier)`?
            targets_args.add(xcode_target.module_name)

            targets_args.add(
                apple_platform_to_platform_name(
                    xcode_target.platform.apple_platform,
                ),
            )
            targets_args.add(xcode_target.platform.os_version)
            targets_args.add(xcode_target.platform.arch)
            targets_args.add(
                _dsym_files_to_string(xcode_target.outputs.dsym_files),
            )

            if (xcode_target.test_host and
                xcode_target.product.type == _UNIT_TEST_PRODUCT_TYPE):
                unit_test_host = xcode_target.test_host
                unit_test_host_ids.append(unit_test_host)
            else:
                unit_test_host = EMPTY_STRING

            build_settings_file = (
                xcode_target.build_settings_file
            )
            targets_args.add(build_settings_file or EMPTY_STRING)
            if build_settings_file:
                build_settings_files.append(
                    build_settings_file,
                )

            targets_args.add(
                TRUE_ARG if xcode_target.has_c_params else FALSE_ARG,
            )
            targets_args.add(
                TRUE_ARG if xcode_target.has_cxx_params else FALSE_ARG,
            )

            targets_args.add_all(
                xcode_target.inputs.srcs,
                omit_if_empty = False,
                terminate_with = "",
            )
            targets_args.add_all(
                xcode_target.inputs.non_arc_srcs,
                omit_if_empty = False,
                terminate_with = "",
            )

            targets_args.add_all(
                xcode_target_configurations[xcode_target.id],
                omit_if_empty = False,
                terminate_with = "",
            )

            targets_args.add_all(
                xcode_target.linker_inputs_for_libs_search_paths.to_list(),
                omit_if_empty = False,
                terminate_with = "",
            )

            targets_args.add_all(
                xcode_target.libraries_path_to_link.to_list(),
                omit_if_empty = False,
                terminate_with = "",
            )

            # `outputs.product_path` is only set for top-level targets
            if xcode_target.outputs.product_path:
                top_level_targets_args.add(xcode_target.id)
                top_level_targets_args.add(
                    xcode_target.bundle_id or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    xcode_target.outputs.product_path or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    xcode_target.link_params or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    xcode_target.product.executable_name or EMPTY_STRING,
                )
                top_level_targets_args.add(xcode_target.compile_target_ids)
                top_level_targets_args.add(unit_test_host)

    actions.write(target_arguments_file, targets_args)
    actions.write(top_level_target_attributes_file, top_level_targets_args)

    # FIXME: Add test case for this
    for id in uniq(unit_test_host_ids):
        unit_test_host_target = xcode_targets[id]
        if not unit_test_host_target:
            fail(
                """\
Target ID for unit test host '{}' not found in xcode_targets
""".format(unit_test_host),
            )
        unit_test_hosts_args.add(id)
        unit_test_hosts_args.add(unit_test_host_target.package_bin_dir)

        unit_test_hosts_args.add(
            unit_test_host_target.product.original_basename,
        )
        unit_test_hosts_args.add(
            unit_test_host_target.product.executable_name or
            unit_test_host_target.product.name,
        )

    actions.write(unit_test_host_attributes_file, unit_test_hosts_args)

    # colorize
    if colorize:
        args.add(_FLAGS.colorize)

    message = "Generating {} PBXNativeTargets partials (shard {})".format(
        install_path,
        idx,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            consolidation_map,
            target_arguments_file,
            top_level_target_attributes_file,
            unit_test_host_attributes_file,
        ] + build_settings_files,
        outputs = [
            pbxnativetargets,
            buildfile_subidentifiers,
        ],
        progress_message = message,
        mnemonic = "WritePBXNativeTargets",
        execution_requirements = {
            # Lots of files to read, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return (
        pbxnativetargets,
        buildfile_subidentifiers,
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
        generated_file_paths,
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
        generated_file_paths:  A `depset` of file paths to generated files to
            include in the project.
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

    file_paths_args = actions.args()
    file_paths_args.set_param_file_format("multiline")

    file_paths_args.add_all(files, map_each = _source_file)

    # TODO: Consider moving normalization into `args.add_all.map_each`
    file_paths_args.add_all(file_paths)

    actions.write(file_paths_file, file_paths_args)

    # generatedFilePaths

    generated_file_paths_file = actions.declare_file(
        "{}_pbxproj_partials/generated_file_paths_file".format(
            generator_name,
        ),
    )

    generated_file_paths_args = actions.args()
    generated_file_paths_args.set_param_file_format("multiline")

    generated_file_paths_args.add_all(files, map_each = _generated_file)
    generated_file_paths_args.add_all(
        generated_file_paths,
        map_each = _generated_file_path,
    )

    actions.write(generated_file_paths_file, generated_file_paths_args)

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

    # indentWidth
    args.add(project_options.get("indent_width", EMPTY_STRING))

    # tabWidth
    args.add(project_options.get("tab_width", EMPTY_STRING))

    # usesTabs
    args.add(project_options.get("uses_tabs", EMPTY_STRING))

    # filePathsFile
    args.add(file_paths_file)

    # generatedFilePathsFile
    args.add(generated_file_paths_file)

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
            generated_file_paths_file,
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

def _write_generated_directories_filelist(
        *,
        actions,
        generator_name,
        infoplists,
        install_path,
        srcs,
        tool):
    directories_args = actions.args()
    directories_args.set_param_file_format("multiline")
    directories_args.use_param_file("%s", use_always = True)

    directories_args.add_all(infoplists, map_each = _dirname)
    directories_args.add_all(srcs, map_each = _generated_dirname)

    filelist = actions.declare_file(
        "{}-generated_directories.filelist".format(generator_name),
    )

    args = actions.args()
    args.add(filelist)

    message = (
        "Generating {} generated directories filelist".format(install_path)
    )

    actions.run(
        arguments = [directories_args, args],
        executable = tool,
        outputs = [filelist],
        mnemonic = "WriteGeneratedDirectoriesFilelist",
        progress_message = message,
    )

    return filelist

def _write_generated_xcfilelist(
        *,
        actions,
        generator_name,
        infoplists,
        srcs):
    args = actions.args()
    args.set_param_file_format("multiline")

    # Info.plists are tracked as build files by Xcode, so top-level targets
    # will fail the first time they are built if we don't track them
    args.add_all(infoplists, map_each = _xcfilelist_always_generated_file_path)

    # Source files are tracked as build files by Xcode, so building targets that
    # directly use generated source files will fail the first time they are
    # built if we don't track them
    args.add_all(srcs, map_each = _xcfilelist_generated_file_path)

    xcfilelist = actions.declare_file(
        "{}-generated.xcfilelist".format(generator_name),
    )
    actions.write(xcfilelist, args)

    return xcfilelist

def _write_pbxproj_prefix(
        *,
        actions,
        apple_platform_to_platform_name = (
            platforms.apple_platform_to_platform_name
        ),
        colorize,
        config,
        default_xcode_configuration,
        execution_root_file,
        generator_name,
        import_index_build_indexstores,
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
        config: The name of the `.bazelrc` config.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        generator_name: The name of the `xcodeproj` generator target.
        import_index_build_indexstores: Whether to import index build
            indexstores.
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

    # config
    args.add(config)

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

    # importIndexBuildIndexstores
    args.add("1" if import_index_build_indexstores else "0")

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
        apple_platform_to_platform_name = (
            platforms.apple_platform_to_platform_name
        ),
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

    consolidation_map_args.add_all(
        consolidation_maps.keys(),
        omit_if_empty = False,
        terminate_with = "",
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
                if not xcode_target.product.original_basename:
                    fail("""\
"{}" does not have `product.original_basename` set.
Please file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""".format(xcode_target.label))

                consolidation_map_args.add(xcode_target.id)
                consolidation_map_args.add(xcode_target.product.type)
                consolidation_map_args.add(
                    apple_platform_to_platform_name(
                        xcode_target.platform.apple_platform,
                    ),
                )
                consolidation_map_args.add(xcode_target.platform.os_version)
                consolidation_map_args.add(xcode_target.platform.arch)
                consolidation_map_args.add(xcode_target.module_name_attribute)
                consolidation_map_args.add(xcode_target.product.original_basename)
                consolidation_map_args.add(xcode_target.product.basename)
                consolidation_map_args.add_all(
                    xcode_target.direct_dependencies,
                    omit_if_empty = False,
                    terminate_with = "",
                )
                consolidation_map_args.add_all(
                    xcode_target_configurations[xcode_target.id],
                    omit_if_empty = False,
                    terminate_with = "",
                )

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

def _write_swift_debug_settings(
        *,
        actions,
        colorize,
        generator_name,
        install_path,
        tool,
        top_level_swift_debug_settings,
        xcode_configuration):
    output = actions.declare_file(
        "{}_swift_debug_settings/{}-swift_debug_settings.py".format(
            generator_name,
            xcode_configuration,
        ),
    )

    args = actions.args()

    # colorize
    args.add(TRUE_ARG if colorize else FALSE_ARG)

    # outputPath
    args.add(output)

    # keysAndFiles
    args.add_all(top_level_swift_debug_settings, map_each = _keys_and_files)

    message = "Generating {} {}-swift_debug_settings.py".format(
        install_path,
        xcode_configuration,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            file
            for _, file in top_level_swift_debug_settings
        ],
        outputs = [output],
        progress_message = message,
        mnemonic = "WriteSwiftDebugSettings",
    )

    return output

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
        generate_swift_debug_settings,
        include_self_swift_debug_settings = True,
        infoplist = None,
        name,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        provisioning_profile_is_xcode_managed = False,
        provisioning_profile_name = None,
        swift_args,
        swift_debug_settings_to_merge = EMPTY_DEPSET,
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
        device_family: A value from `get_targeted_device_family`.
        entitlements: An optional entitlements `File`.
        extension_safe: If `True`, `APPLICATION_EXTENSION_API_ONLY` will be set.
        generate_build_settings: A `bool` indicating whether to generate build
            settings. This is mostly tied to if the target is focused or not.
        generate_swift_debug_settings: A `bool` indicating whether to generate
            Swift debug settings.
        include_self_swift_debug_settings: A `bool` indicating whether to
            include the target's own Swift debug settings. Should be false for
            merged top-level targets.
        infoplist: An optional `File` containing the `Info.plist` for the
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
        args.add_all(
            swift_debug_settings_to_merge,
            omit_if_empty = False,
            terminate_with = "",
        )

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

def _write_targets(
        *,
        actions,
        colorize,
        consolidation_maps,
        default_xcode_configuration,
        generator_name,
        install_path,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element.

    Args:
        actions: `ctx.actions`.
        colorize: Whether to colorize the output.
        consolidation_maps: A `dict` mapping `File`s containing target
            consolidation maps to a `list` of `Label`s of the targets included
            in the map.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with two elements:

        *   `pbxnativetargets`: A `list` of `File`s for the `PBNativeTarget`
            `PBXProj` partials.
        *   `buildfile_subidentifiers_files`: A `list` of `File`s that contain
            serialized `[Identifiers.BuildFile.SubIdentifier]`s.
    """
    pbxnativetargets = []
    buildfile_subidentifiers_files = []
    for consolidation_map, labels in consolidation_maps.items():
        (
            label_pbxnativetargets,
            label_buildfile_subidentifiers,
        ) = _write_consolidation_map_targets(
            actions = actions,
            colorize = colorize,
            consolidation_map = consolidation_map,
            default_xcode_configuration = default_xcode_configuration,
            generator_name = generator_name,
            idx = consolidation_map.basename,
            install_path = install_path,
            labels = labels,
            tool = tool,
            xcode_target_configurations = xcode_target_configurations,
            xcode_targets = xcode_targets,
            xcode_targets_by_label = xcode_targets_by_label,
        )

        pbxnativetargets.append(label_pbxnativetargets)
        buildfile_subidentifiers_files.append(label_buildfile_subidentifiers)

    return (
        pbxnativetargets,
        buildfile_subidentifiers_files,
    )

# `project.pbxproj`

def _write_project_pbxproj(
        *,
        actions,
        files_and_groups,
        generator_name,
        pbxproj_prefix,
        pbxproject_targets,
        pbxproject_known_regions,
        pbxproject_target_attributes,
        pbxtargetdependencies,
        targets):
    """Creates a `project.pbxproj` `File`.

    Args:
        actions: `ctx.actions`.
        files_and_groups: The `files_and_groups` `File` returned from
            `pbxproj_partials.write_files_and_groups`.
        generator_name: The name of the `xcodeproj` generator target.
        pbxproj_prefix: The `File` returned from
            `pbxproj_partials.write_pbxproj_prefix`.
        pbxproject_known_regions: The `known_regions` `File` returned from
            `pbxproj_partials.write_known_regions`.
        pbxproject_target_attributes: The `pbxproject_target_attributes` `File`
            returned from `pbxproj_partials.write_pbxproject_targets`.
        pbxproject_targets: The `pbxproject_targets` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        pbxtargetdependencies: The `pbxtargetdependencies` `Files` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        targets: The `targets` `list` of `Files` returned from
            `pbxproj_partials.write_targets`.

    Returns:
        A `project.pbxproj` `File`.
    """
    output = actions.declare_file("{}.project.pbxproj".format(generator_name))

    inputs = [
        pbxproj_prefix,
        pbxproject_target_attributes,
        pbxproject_known_regions,
        pbxproject_targets,
    ] + targets + [
        pbxtargetdependencies,
        files_and_groups,
    ]

    args = actions.args()
    args.use_param_file("%s")
    args.set_param_file_format("multiline")
    args.add_all(inputs)

    actions.run_shell(
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        command = """\
cat "$@" > "{output}"
""".format(output = output.path),
        mnemonic = "WriteXcodeProjPBXProj",
        progress_message = "Generating %{output}",
        execution_requirements = {
            # Running `cat` is faster than looking up and copying from cache
            "no-cache": "1",
            # Absolute paths
            "no-remote": "1",
            # Each file is directly referenced, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

pbxproj_partials = struct(
    write_files_and_groups = _write_files_and_groups,
    write_generated_directories_filelist = (
        _write_generated_directories_filelist
    ),
    write_generated_xcfilelist = _write_generated_xcfilelist,
    write_pbxproj_prefix = _write_pbxproj_prefix,
    write_pbxtargetdependencies = _write_pbxtargetdependencies,
    write_project_pbxproj = _write_project_pbxproj,
    write_swift_debug_settings = _write_swift_debug_settings,
    write_target_build_settings = _write_target_build_settings,
    write_targets = _write_targets,
)

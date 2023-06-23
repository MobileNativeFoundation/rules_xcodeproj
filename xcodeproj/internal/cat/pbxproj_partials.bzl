"""Actions for creating `PBXProj` partials."""

load("//xcodeproj/internal:collections.bzl", "uniq")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_LIST",
    "EMPTY_STRING",
)
load(
    "//xcodeproj/internal:pbxproj_partials.bzl",
    _pbxproj_partials = "pbxproj_partials",
)
load(":platforms.bzl", "PLATFORM_NAME", "platforms")

# Utility

_SWIFTUI_PREVIEW_PRODUCT_TYPES = {
    "e": None,  # com.apple.product-type.app-extension
    "a": None,  # com.apple.product-type.application
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "w": None,  # com.apple.product-type.application.watchapp2
    "B": None,  # com.apple.product-type.bundle
    "u": None,  # com.apple.product-type.bundle.unit-test
    "E": None,  # com.apple.product-type.extensionkit-extension
    "f": None,  # com.apple.product-type.framework
    "T": None,  # com.apple.product-type.tool
    "t": None,  # com.apple.product-type.tv-app-extension
}

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _to_binary_bool(bool):
    return "1" if bool else "0"

def _filter_external_file(file):
    if not file.owner.workspace_name:
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(file.path[8:])

def _filter_external_file_path(file_path):
    if not file_path.startswith("external/"):
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(file_path[8:])

def _filter_generated_file(file):
    if file.is_source:
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(file.path[9:])

def _filter_generated_file_path(file_path):
    if not file_path.startswith("bazel-out/"):
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(file_path[9:])

def _depset_len(d):
    return str(len(d.to_list()))

def _depset_to_list(d):
    return d.to_list()

def _depset_to_paths(d):
    return [file.path for file in d.to_list()]

def _hosted_target(hosted_target):
    return [hosted_target.hosted, hosted_target.host]

def _identity(seq):
    return seq

def _is_same_platform_swiftui_preview_target(*, platform, xcode_target):
    if not xcode_target:
        return False
    if not platforms.is_same_type(platform, xcode_target.platform):
        return False
    return xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_flags = struct(
    additional_target_counts = "--additional-target-counts",
    additional_targets = "--additional-targets",
    archs = "--archs",
    args_separator = "---",
    build_settings_files = "--build-settings-files",
    c_params = "--c-params",
    colorize = "--colorize",
    consolidation_map_output_paths = "--consolidation-map-output-paths",
    consolidation_maps = "--consolidation-maps",
    cxx_params = "--cxx-params",
    default_xcode_configuration = "--default-xcode-configuration",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    dsym_paths = "--dsym-paths",
    files_paths = "--file-paths",
    folder_paths = "--folder-paths",
    folder_resources = "--folder-resources",
    folder_resources_counts = "--folder-resources-counts",
    has_c_params = "--has-c-params",
    has_cxx_params = "--has-cxx-params",
    hdrs = "--hdrs",
    hdrs_counts = "--hdrs-counts",
    labels = "--labels",
    label_counts = "--label-counts",
    module_names = "--module-names",
    non_arc_srcs = "--non-arc-srcs",
    non_arc_srcs_counts = "--non-arc-srcs-counts",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    package_bin_dirs = "--package-bin-dirs",
    platforms = "--platforms",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    product_basenames = "--product-basenames",
    product_names = "--product-names",
    product_paths = "--product-paths",
    product_types = "--product-types",
    resources = "--resources",
    resources_counts = "--resources-counts",
    srcs = "--srcs",
    srcs_counts = "--srcs-counts",
    target_and_extension_hosts = "--target-and-extension-hosts",
    target_counts = "--target-counts",
    targets = "--targets",
    unit_test_hosts = "--unit-test-hosts",
    top_level_targets = "--top-level-targets",
    use_base_internationalization = "--use-base-internationalization",
    xcode_configuration_counts = "--xcode-configuration-counts",
    xcode_configurations = "--xcode-configurations",
)

def _build_setting_dirname(file):
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
        infoplist = None,
        name,
        package_bin_dir,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        provisioning_profile_is_xcode_managed = False,
        provisioning_profile_name = None,
        skip_codesigning = False,
        swift_args,
        team_id = None,
        tool):
    """Creates the `OTHER_SWIFT_FLAGS` build setting string file for a target.

    Args:
        actions: `ctx.actions`.
        apple_generate_dsym: `cpp_fragment.apple_generate_dsym`.
        colorize: A `bool` indicating whether to colorize the output.
        conly_args: A `list` of `Args` for the C compile action for this target.
        cxx_args: A `list` of `Args` for the C++ compile action for this target.
        device_family: A value as returned by `get_targeted_device_family`.
        entitlements: An optional entitlements `File`.
        extension_safe: If `True, `APPLICATION_EXTENSION_API_ONLY` will be set.
        infoplist: An optional `File` containing the `Info.plist` for the
            target.
        name: The name of the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        skip_codesigning: If `True`, `CODE_SIGNING_ALLOWED = NO` will be set.
        swift_args: A `list` of `Args` for the `SwiftCompile` action for this
            target.
        swiftmodule: `target_outputs.direct_outputs.swift.,module.swiftmodule`.
        tool: The executable that will generate the output files.

    Returns:
        A `tuple` with two elements:

        *   A `File` containing the `OTHER_SWIFT_FLAGS` build setting string for
            the target, or `None` if `swift_args` is empty.
        *   A `list` of `File`s containing C or C++ compiler arguments. These
            files should be added to compile outputs groups to ensure that Xcode
            has them available for the `Create Compile Dependencies` build
            phase.
    """
    output = actions.declare_file(
        "{}.rules_xcodeproj.target_build_settings".format(name),
    )
    params = []

    args = actions.args()

    # colorize
    args.add("1" if colorize else "0")

    # outputPath
    args.add(output)

    # deviceFamily
    args.add(device_family)

    # extensionSafe
    args.add("1" if extension_safe else "0")

    # generatesDsyms
    args.add("1" if apple_generate_dsym else "0")

    # infoPlist
    args.add(infoplist or EMPTY_STRING)

    # entitlements
    args.add(entitlements or EMPTY_STRING)

    # skipCodesigning
    args.add("1" if skip_codesigning else "0")

    # certificateName
    args.add(certificate_name or EMPTY_STRING)

    # provisioningProfileName
    args.add(provisioning_profile_name or EMPTY_STRING)

    # teamID
    args.add(team_id or EMPTY_STRING)

    # provisioningProfileIsXcodeManaged
    args.add("1" if provisioning_profile_is_xcode_managed else "0")

    # packageBinDir
    args.add(package_bin_dir)

    # previewFrameworkPaths
    args.add_joined(
        previews_dynamic_frameworks,
        format_each = '"%s"',
        map_each = _build_setting_dirname,
        omit_if_empty = False,
        join_with = " ",
    )

    # previewsIncludePath
    args.add(previews_include_path)

    c_output_args = actions.args()

    # C argsSeparator
    c_output_args.add(_flags.args_separator)

    if conly_args:
        c_params = actions.declare_file(
            "{}.c.compile.params".format(name),
        )
        params.append(c_params)

        # cParams
        c_output_args.add(c_params)

    cxx_output_args = actions.args()

    # Cxx argsSeparator
    cxx_output_args.add(_flags.args_separator)

    if cxx_args:
        cxx_params = actions.declare_file(
            "{}.cxx.compile.params".format(name),
        )
        params.append(cxx_params)

        # cxxParams
        cxx_output_args.add(cxx_params)

    actions.run(
        arguments = (
            [args] + swift_args + [c_output_args] + conly_args +
            [cxx_output_args] + cxx_args
        ),
        executable = tool,
        outputs = [output] + params,
        progress_message = "Generating %{output}",
        mnemonic = "WriteOtherSwiftFlags",
    )

    return output, params

def _write_schemes(
        *,
        actions,
        consolidation_maps,
        default_xcode_configuration,
        extension_point_identifiers_file,
        generator_name,
        hosted_targets,
        include_transitive_previews_targets,
        install_path,
        tool,
        workspace_directory,
        xcode_targets):
    """Creates the `.xcscheme` `File`s for a project.

    Args:
        actions: `ctx.actions`.
        consolidation_maps: A `list` of `File`s containing target consolidation
            maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        extension_point_identifiers_file: A `File` that contains a JSON
            representation of `[TargetID: ExtensionPointIdentifier]`.
        generator_name: The name of the `xcodeproj` generator target.
        hosted_targets: A `depset` of `struct`s with `host` and `hosted` fields.
            The `host` field is the target ID of the hosting target. The
            `hosted` field is the target ID of the hosted target.
        include_transitive_previews_targets: Whether to adjust schemes to
            explicitly include transitive dependencies that are able to run
            SwiftUI Previews.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        tool: The executable that will generate the output files.
        workspace_directory: The absolute path to the Bazel workspace
            directory.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A `File` for the directory containing the `.xcscheme`s.
    """
    additional_targets = []
    additional_target_counts = []
    for xcode_target in xcode_targets.values():
        if (include_transitive_previews_targets and
            xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES):
            ids = [
                id
                for id in xcode_target.transitive_dependencies.to_list()
                if _is_same_platform_swiftui_preview_target(
                    platform = xcode_target.platform,
                    xcode_target = xcode_targets.get(id),
                )
            ]
            if ids:
                additional_targets.append(xcode_target.id)
                additional_targets.extend(ids)
                additional_target_counts.append(len(ids))

    output = actions.declare_directory(
        "{}_pbxproj_partials/xcschemes".format(generator_name),
    )

    args = actions.args()

    # outputDirectory
    args.add(output.path)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # workspace
    args.add(workspace_directory)

    # installPath
    args.add(install_path)

    # extensionPointIdentifiersFile
    args.add(extension_point_identifiers_file)

    # consolidationMaps
    args.add_all(_flags.consolidation_maps, consolidation_maps)

    # targetAndExtensionHosts
    args.add_all(
        _flags.target_and_extension_hosts,
        hosted_targets,
        map_each = _hosted_target,
    )

    if additional_targets:
        args.add_all(_flags.additional_targets, additional_targets)
        args.add_all(
            _flags.additional_target_counts,
            additional_target_counts
        )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [extension_point_identifiers_file] + consolidation_maps,
        outputs = [output],
        progress_message = "Creating '.xcschemes` for {}".format(install_path),
        mnemonic = "WriteXCSchemes",
        execution_requirements = {
            # Lots of files to read and write, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

def _write_targets(
        *,
        actions,
        consolidation_maps,
        default_xcode_configuration,
        generator_name,
        install_path,
        link_params,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element.

    Args:
        actions: `ctx.actions`.
        consolidation_maps: A `dict` mapping `File`s containing target
            consolidation maps to a `list` of `Label`s of the targets included
            in the map.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        link_params: A `dict` mapping `xcode_target.id` to a `link.params` file
            for that target, if one is needed.
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
            consolidation_map = consolidation_map,
            default_xcode_configuration = default_xcode_configuration,
            generator_name = generator_name,
            idx = consolidation_map.basename,
            install_path = install_path,
            labels = labels,
            link_params = link_params,
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

_UNIT_TEST_PRODUCT_TYPE = "u"  # com.apple.product-type.bundle.unit-test

def _write_consolidation_map_targets(
        *,
        actions,
        consolidation_map,
        default_xcode_configuration,
        generator_name,
        idx,
        install_path,
        labels,
        link_params,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element, for a \
    given consolidation map

    Args:
        actions: `ctx.actions`.
        consolidation_map: A `File` containing a target consolidation maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        link_params: A `dict` mapping `xcode_target.id` to a `link.params` file
            for that target, if one is needed.
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

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # targetsOutputPath
    args.add(pbxnativetargets)

    # buildFileSubIdentifiersOutputPath
    args.add(buildfile_subidentifiers)

    # consolidationMap
    args.add(consolidation_map)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    archs = []
    build_settings_files = []
    build_settings_paths = []
    dsym_files = []
    folder_resources = []
    has_c_params = []
    has_cxx_params = []
    hdrs = []
    module_names = []
    non_arc_srcs = []
    os_versions = []
    package_bin_dirs = []
    platforms = []
    product_basenames = []
    product_names = []
    product_types = []
    resources = []
    resources_counts = []
    srcs = []
    target_ids = []
    top_level_target_attributes = []
    unit_test_host_ids = []
    xcode_configuration_counts = []
    xcode_configurations = []
    for label in labels:
        for xcode_target in xcode_targets_by_label[label].values():
            target_ids.append(xcode_target.id)
            product_types.append(xcode_target.product.type)
            package_bin_dirs.append(xcode_target.package_bin_dir)
            product_names.append(xcode_target.product.name)
            product_basenames.append(xcode_target.product.basename)

            # FIXME: Don't send if it would be the same as `$(PRODUCT_NAME:c99extidentifier)`?
            module_names.append(xcode_target.module_name)
            platforms.append(xcode_target.platform.platform)
            os_versions.append(xcode_target.platform.os_version)
            archs.append(xcode_target.platform.arch)
            srcs.append(xcode_target.inputs.srcs)
            non_arc_srcs.append(xcode_target.inputs.non_arc_srcs)
            hdrs.append(xcode_target.inputs.hdrs)
            resources_counts.append(xcode_target.inputs.resources)
            resources.append(xcode_target.inputs.resources)
            folder_resources.append(xcode_target.inputs.folder_resources)
            dsym_files.append(xcode_target.outputs.dsym_files)

            if (xcode_target.test_host and
                xcode_target.product.type == _UNIT_TEST_PRODUCT_TYPE):
                unit_test_host = xcode_target.test_host
                unit_test_host_ids.append(unit_test_host)
            else:
                unit_test_host = EMPTY_STRING

            target_link_params = link_params.get(xcode_target.id, EMPTY_STRING)


            # FIXME: Only set for top level targets
            # FIXME: Extract to a single type, for easier checking/setting?
            if (xcode_target.outputs.product_path):
                top_level_target_attributes.extend([
                    xcode_target.id,
                    xcode_target.bundle_id or EMPTY_STRING,
                    xcode_target.outputs.product_path or EMPTY_STRING,
                    target_link_params,
                    xcode_target.product.executable_name or EMPTY_STRING,
                    xcode_target.compile_target_ids,
                    unit_test_host,
                ])

            build_settings_file = (
                xcode_target.build_settings_file
            )
            build_settings_paths.append(
                build_settings_file or EMPTY_STRING,
            )
            if build_settings_file:
                build_settings_files.append(
                    build_settings_file,
                )

            has_c_params.append(xcode_target.has_c_params)
            has_cxx_params.append(xcode_target.has_cxx_params)

            configurations = xcode_target_configurations[xcode_target.id]
            xcode_configuration_counts.append(len(configurations))
            xcode_configurations.append(configurations)

    # topLevelTargets
    args.add_all(_flags.top_level_targets, top_level_target_attributes)

    # unitTestHosts
    unit_test_hosts = []
    # FIXME: Add test case for this
    for id in uniq(unit_test_host_ids):
        unit_test_host_target = xcode_targets[id]
        if not unit_test_host_target:
            fail("""\
    Target ID for unit test host '{}' not found in xcode_targets
    """.format(unit_test_host)
            )
        unit_test_hosts.extend([
            id,
            # packageBinDir
            unit_test_host_target.package_bin_dir,
            # productPath
            unit_test_host_target.product.file_path,
            # executableName
            (unit_test_host_target.product.executable_name or
                unit_test_host_target.product.name),
        ])

    args.add_all(_flags.unit_test_hosts, unit_test_hosts)

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

    # packageBinDirs
    args.add_all(_flags.package_bin_dirs, package_bin_dirs)

    # productNames
    args.add_all(_flags.product_names, product_names)

    # productBasenames
    args.add_all(_flags.product_basenames, product_basenames)

    # moduleNames
    args.add_all(_flags.module_names, module_names)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = _apple_platform_to_platform_name,
    )

    # osVersions
    args.add_all(_flags.os_versions, os_versions)

    # archs
    args.add_all(_flags.archs, archs)

    # buildSettingsFiles
    args.add_all(
        _flags.build_settings_files,
        build_settings_paths,
    )

    # hasCParams
    args.add_all(_flags.has_c_params, has_c_params, map_each = _to_binary_bool)

    # hasCxxParams
    args.add_all(
        _flags.has_cxx_params,
        has_cxx_params,
        map_each = _to_binary_bool,
    )

    # srcsCounts
    args.add_all(_flags.srcs_counts, srcs, map_each = _depset_len)

    # srcs
    args.add_all(_flags.srcs, srcs, map_each = _depset_to_paths)

    # nonArcSrcsCounts
    args.add_all(
        _flags.non_arc_srcs_counts,
        non_arc_srcs,
        map_each = _depset_len,
    )

    # nonArcSrcs
    args.add_all(_flags.non_arc_srcs, non_arc_srcs, map_each = _depset_to_paths)

    # hdrsCounts
    args.add_all(_flags.hdrs_counts, hdrs, map_each = _depset_len)

    # hdrs
    args.add_all(_flags.hdrs, hdrs, map_each = _depset_to_paths)

    # resourcesCounts
    args.add_all(
        _flags.resources_counts,
        resources,
        map_each = _depset_len,
    )

    # resources
    args.add_all(
        _flags.resources,
        resources,
        map_each = _depset_to_list,
    )

    # folderResourcesCounts
    args.add_all(
        _flags.folder_resources_counts,
        folder_resources,
        map_each = _depset_len,
    )

    # folderResources
    args.add_all(
        _flags.folder_resources,
        folder_resources,
        map_each = _depset_to_list,
    )

    # dsymPaths
    args.add_all(
        _flags.dsym_paths,
        dsym_files,
        map_each = _dsym_files_to_string,
    )

    message = "Generating {} PBXNativeTargets partials (shard {})".format(
        install_path,
        idx,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [consolidation_map] + build_settings_files,
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
        pbxproject_target_attributes: The `pbxproject_target_attributes` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
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
cat "$@" > {output}
""".format(output = output.path),
        mnemonic = "WriteXcodeProjPBXProj",
        progress_message = "Generating %{output}",
        execution_requirements = {
            # Absolute paths
            "no-remote": "1",
            # Each file is directly referenced, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

def _write_xcfilelists(*, actions, files, file_paths, generator_name):
    external_args = actions.args()
    external_args.set_param_file_format("multiline")
    external_args.add_all(
        files,
        map_each = _filter_external_file,
    )
    external_args.add_all(
        file_paths,
        map_each = _filter_external_file_path,
    )

    external = actions.declare_file(
        "{}-xcfilelists/external.xcfilelist".format(generator_name),
    )
    actions.write(external, external_args)

    generated_args = actions.args()
    generated_args.set_param_file_format("multiline")
    generated_args.add_all(
        files,
        map_each = _filter_generated_file,
    )
    generated_args.add_all(
        file_paths,
        map_each = _filter_generated_file_path,
    )

    generated = actions.declare_file(
        "{}-xcfilelists/generated.xcfilelist".format(generator_name),
    )
    actions.write(generated, generated_args)

    return [external, generated]

pbxproj_partials = struct(
    write_files_and_groups = _pbxproj_partials.write_files_and_groups,
    write_target_build_settings = _write_target_build_settings,
    write_project_pbxproj = _write_project_pbxproj,
    write_pbxproj_prefix = _pbxproj_partials.write_pbxproj_prefix,
    write_pbxtargetdependencies = _pbxproj_partials.write_pbxtargetdependencies,
    write_schemes = _write_schemes,
    write_targets = _write_targets,
    write_xcfilelists = _write_xcfilelists,
)

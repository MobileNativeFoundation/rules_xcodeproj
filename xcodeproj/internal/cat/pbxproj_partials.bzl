"""Actions for creating `PBXProj` partials."""

load("//xcodeproj/internal:collections.bzl", "uniq")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_STRING",
    "FALSE_ARG",
    "TRUE_ARG",
)
load(
    "//xcodeproj/internal:pbxproj_partials.bzl",
    _pbxproj_partials = "pbxproj_partials",
)
load("//xcodeproj/internal:platforms.bzl", "PLATFORM_NAME")

# Utility

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _depset_len(depset):
    return str(len(depset.to_list()))

def _filter_external_file(file):
    if not file.owner.workspace_name:
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(_normalize_path(file.path[8:]))

def _filter_external_file_path(file_path):
    if not file_path.startswith("external/"):
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(file_path[8:])

def _filter_generated_file(file):
    if file.is_source:
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(_normalize_path(file.path[9:]))

def _filter_generated_file_path(file_path):
    if not file_path.startswith("bazel-out/"):
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(file_path[9:])

def _keys_and_files(pair):
    key, file = pair
    return [key, file.path]

_RESOURCES_FOLDER_TYPE_EXTENSIONS = [
    ".bundle",
    ".docc",
    ".framework",
    ".scnassets",
    ".xcassets",
]

def _normalize_path(path):
    for extension in _RESOURCES_FOLDER_TYPE_EXTENSIONS:
        if extension not in path:
            continue
        prefix, ext, _ = path.partition(extension)
        return prefix + ext

    return path

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_FLAGS = struct(
    archs = "--archs",
    c_params = "--c-params",
    colorize = "--colorize",
    consolidation_maps = "--consolidation-maps",
    cxx_params = "--cxx-params",
    default_xcode_configuration = "--default-xcode-configuration",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    dsym_paths = "--dsym-paths",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    package_bin_dirs = "--package-bin-dirs",
    resources = "--resources",
    resources_counts = "--resources-counts",
    target_and_extension_hosts = "--target-and-extension-hosts",
    use_base_internationalization = "--use-base-internationalization",
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

def _write_targets(
        *,
        actions,
        colorize,
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
        colorize: Whether to colorize the output.
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
            colorize = colorize,
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
        apple_platform_to_platform_name = _apple_platform_to_platform_name,
        colorize,
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
        apple_platform_to_platform_name: Exposed for testing. Don't set.
        colorize: Whether to colorize the output.
        consolidation_map: A `File` containing a target consolidation maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        idx: The index of the consolidation map.
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

            # FIXME: Don't send if it would be the same as `$(PRODUCT_NAME:c99extidentifier)`?
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
                [xcode_target.inputs.srcs],
                map_each = _depset_len,
            )
            targets_args.add_all(xcode_target.inputs.srcs)
            targets_args.add_all(
                [xcode_target.inputs.non_arc_srcs],
                map_each = _depset_len,
            )
            targets_args.add_all(xcode_target.inputs.non_arc_srcs)
            targets_args.add_all(
                [xcode_target.inputs.resources],
                map_each = _depset_len,
            )
            targets_args.add_all(xcode_target.inputs.resources)
            targets_args.add_all(
                [xcode_target.inputs.folder_resources],
                map_each = _depset_len,
            )
            targets_args.add_all(xcode_target.inputs.folder_resources)

            target_xcode_configurations = (
                xcode_target_configurations[xcode_target.id]
            )
            targets_args.add(len(target_xcode_configurations))
            targets_args.add_all(target_xcode_configurations)

            # FIXME: Only set for top level targets
            if xcode_target.outputs.product_path:
                top_level_targets_args.add(xcode_target.id)
                top_level_targets_args.add(
                    xcode_target.bundle_id or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    xcode_target.outputs.product_path or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    link_params.get(xcode_target.id, EMPTY_STRING),
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
        unit_test_hosts_args.add(unit_test_host_target.product.file_path)
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
            # Running `cat` is faster than looking up and copying from cache
            "no-cache": "1",
            # Absolute paths
            "no-remote": "1",
            # Each file is directly referenced, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

def _write_xcfilelist(*, actions, args, output):
    args.set_param_file_format("multiline")
    args.use_param_file("@%s")

    actions.run_shell(
        arguments = [args],
        command = """\
set -euo pipefail

if [[ $# -eq 1 && "${{1:0:1}}" == "@" ]]; then
    /usr/bin/sort -u "${{1:1}}"
else
    printf "%s\n" "$@" | /usr/bin/sort -u
fi > "{output}"
""".format(output = output.path),
        outputs = [output],
        mnemonic = "WriteXCFileList",
        progress_message = "Generating %{output}",
        execution_requirements = {
            # Command is faster than a cache look up
            "no-cache": "1",
            # Command is faster than a remote execution
            "no-remote": "1",
        },
    )

def _write_xcfilelists(*, actions, files, file_paths, generator_name):
    external_args = actions.args()
    external_args.add_all(
        files,
        map_each = _filter_external_file,
        uniquify = True,
    )
    external_args.add_all(
        file_paths,
        map_each = _filter_external_file_path,
        uniquify = True,
    )

    external = actions.declare_file(
        "{}-xcfilelists/external.xcfilelist".format(generator_name),
    )
    _write_xcfilelist(
        actions = actions,
        args = external_args,
        output = external,
    )

    generated_args = actions.args()
    generated_args.add_all(
        files,
        map_each = _filter_generated_file,
        uniquify = True,
    )
    generated_args.add_all(
        file_paths,
        map_each = _filter_generated_file_path,
        uniquify = True,
    )

    generated = actions.declare_file(
        "{}-xcfilelists/generated.xcfilelist".format(generator_name),
    )
    _write_xcfilelist(
        actions = actions,
        args = generated_args,
        output = generated,
    )

    return [external, generated]

pbxproj_partials = struct(
    write_files_and_groups = _pbxproj_partials.write_files_and_groups,
    write_pbxproj_prefix = _pbxproj_partials.write_pbxproj_prefix,
    write_pbxtargetdependencies = _pbxproj_partials.write_pbxtargetdependencies,
    write_project_pbxproj = _write_project_pbxproj,
    write_swift_debug_settings = _write_swift_debug_settings,
    write_target_build_settings = _pbxproj_partials.write_target_build_settings,
    write_targets = _write_targets,
    write_xcfilelists = _write_xcfilelists,
)

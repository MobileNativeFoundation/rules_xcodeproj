"""Actions for creating `PBXProj` partials."""

def _write_pbxproject_prefix(
        *,
        actions,
        colorize,
        execution_root_file,
        generator_name,
        minimum_xcode_version,
        project_options,
        tool,
        workspace_directory):
    """
    Creates a `File` containing a `PBXProject` prefix `PBXProj` partial.

    Args:
        actions: `ctx.actions`.
        colorize: A `bool` indicating whether to colorize the output.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        generator_name: The name of the `xcodeproj` generator target.
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
        project_options: A `dict` as returned by `project_options`.
        tool: The executable that will generate the pbxproj partial.
        workspace_directory: The absolute path to the Bazel workspace
            directory.

    Returns:
        The `File` for the `PBXProject` prefix `PBXProj` partial.
    """
    output = actions.declare_file(
        "{}_pbxproj_partials/project_prefix".format(
            generator_name,
        ),
    )

    args = actions.args()

    # outputPath
    args.add(output)

    # workspace
    args.add(workspace_directory)

    # executionRootFile
    args.add(execution_root_file)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    # developmentRegion
    args.add(project_options["development_region"])

    # organizationName
    organization_name = project_options.get("organization_name")
    if organization_name:
        args.add("--organization-name", organization_name)

    # colorize
    if colorize:
        args.add("--colorize")

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [execution_root_file],
        outputs = [output],
        mnemonic = "WritePBXProjPBXProjectPrefix",
    )

    return output

pbxproj_partials = struct(
    write_pbxproject_prefix = _write_pbxproject_prefix,
)

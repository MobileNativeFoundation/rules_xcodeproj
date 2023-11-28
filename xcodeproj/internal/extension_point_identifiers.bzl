"""Functions generating the `extension_point_identifiers` file."""

def _id(extension_infoplist):
    return extension_infoplist.id

def write_extension_point_identifiers_file(
        *,
        actions,
        extension_infoplists,
        name,
        tool):
    """Creates a `File` that contains a JSON representation of \
    `[TargetID: ExtensionPointIdentifier]`.

    Args:
        actions: `ctx.actions`.
        extension_infoplists: A `list` of `struct`s with `Info.plist` `File`s
            of application extensions and the `xcode_target.id` of those
            extensions.
        name: The name of the target creating the file.
        tool: The executable to run to generate the file.

    Returns:
        The generated `File`.
    """
    target_ids_args = actions.args()
    target_ids_args.use_param_file("%s", use_always = True)
    target_ids_args.set_param_file_format("multiline")
    target_ids_args.add_all(extension_infoplists, map_each = _id)

    infoplist_files = [s.infoplist for s in extension_infoplists]

    infoplists_args = actions.args()
    infoplists_args.use_param_file("%s", use_always = True)
    infoplists_args.set_param_file_format("multiline")
    infoplists_args.add_all(infoplist_files)

    output = actions.declare_file("{}_extension_point_identifiers".format(name))

    args = actions.args()
    args.add(output)

    actions.run(
        arguments = [args, target_ids_args, infoplists_args],
        executable = tool,
        inputs = infoplist_files,
        outputs = [output],
        mnemonic = "CalculateXcodeProjExtensionPointIdentifiers",
    )

    return output

"""Functions generating the `selected_model_versions` file."""

def write_selected_model_versions_file(
        *,
        actions,
        name,
        tool,
        xccurrentversions_files):
    """Creates a `File` that contains a JSON representation of \
    `[BazelPath: String]`, mapping `.xcdatamodeld` file paths to selected \
    `.xcdatamodel` file names.

    Args:
        actions: `ctx.actions`.
        name: The name of the target creating the file.
        tool: The executable to run to generate the file.
        xccurrentversions_files: A `list` of `File`s containing the
            `xccurrentversion` files to read.

    Returns:
        The generated `File`.
    """
    output = actions.declare_file("{}_selected_model_versions".format(name))

    args = actions.args()
    args.add(output)

    files_args = actions.args()
    files_args.use_param_file("%s", use_always = True)
    files_args.set_param_file_format("multiline")

    files_args.add_all(xccurrentversions_files)

    actions.run(
        arguments = [args, files_args],
        executable = tool,
        inputs = xccurrentversions_files,
        outputs = [output],
        mnemonic = "WriteSelectedModelVersionsFile",
    )

    return output

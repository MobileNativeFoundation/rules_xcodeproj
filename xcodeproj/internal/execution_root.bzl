"""Functions dealing with the Bazel execution root."""

def write_execution_root_file(*, actions, bin_dir_path, name):
    """Creates a `File` containing the absolute path to the Bazel execution \
    root.

    If the execution root is under `/private/`, this prefix is stripped so that
    we don't end up with a different path than what Xcode uses (since we also
    remove this prefix for Xcode).

    Args:
        actions: `ctx.actions`.
        bin_dir_path: `ctx.bin_dir.path`.
        name: The name of the target creating the file.

    Returns:
        A `File` containing the absolute path to the Bazel execution root.
    """
    output = actions.declare_file("{}_execution_root_file".format(name))

    actions.run_shell(
        use_default_shell_env = True,
        outputs = [output],
        command = """\
bin_dir_full="$(perl -MCwd -e 'print Cwd::abs_path shift' "{bin_dir}";)"
execution_root="${{bin_dir_full%/{bin_dir}}}"
if [[ $execution_root == /private/* ]]; then
  execution_root="${{execution_root#/private}}"
fi

echo "$execution_root" > "{output}"
""".format(
            bin_dir = bin_dir_path,
            output = output.path,
        ),
        mnemonic = "CalculateExecutionRoot",
        # This has to run locally
        execution_requirements = {
            "local": "1",
            "no-remote": "1",
            "no-sandbox": "1",
        },
    )

    return output

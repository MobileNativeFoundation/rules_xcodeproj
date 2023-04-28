"""Functions dealing with the Bazel execution root."""

def write_execution_root_file(*, actions, bin_dir_path, name):
    output = actions.declare_file("{}_execution_root_file".format(name))

    actions.run_shell(
        outputs = [output],
        command = """\
bin_dir_full="$(perl -MCwd -e 'print Cwd::abs_path shift' "{bin_dir}";)"
execution_root="${{bin_dir_full%/{bin_dir}}}"

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

"""Module containing functions dealing with file lists."""

def _write(*, ctx, rule_name, name, files):
    if files == None:
        files = depset()

    args = ctx.actions.args()
    args.use_param_file("%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add_all(files, expand_directories = False)

    output = ctx.actions.declare_file("{}-{}.filelist".format(rule_name, name))
    output_args = ctx.actions.args()
    output_args.add(output)

    ctx.actions.run_shell(
        command = """\
if [[ $(stat -f '%d' "$1") == $(stat -f '%d' "${2%/*}") ]]; then
  cp -c "$1" "$2"
else
  cp "$1" "$2"
fi
""",
        arguments = [
            args,
            output_args,
        ],
        mnemonic = "XcodeProjFilelist",
        progress_message = "Generating %{output}",
        # We don't include `files` as `inputs`. This action simply lists the
        # paths to `file`, but relies on another mechanism  (like output groups
        # or `--experimental_remote_download_regex`) to download them.
        outputs = [output],
        execution_requirements = {
            # No need to cache, as it's super ephemeral
            "no-cache": "1",
            # No need for remote, as it takes no time
            "no-remote": "1",
            # Disable sandboxing for speed
            "no-sandbox": "1",
        },
    )

    return output

filelists = struct(
    write = _write,
)

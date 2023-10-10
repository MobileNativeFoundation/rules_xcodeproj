"""Module containing functions dealing with indexstore file lists."""

def _directory_and_target_override(directory_and_target_override):
    directory, target_override = directory_and_target_override
    return [directory.path, target_override]

def _write(
        *,
        actions,
        name,
        rule_name,
        indexstore_and_target_overrides,
        indexstores):
    args = actions.args()
    args.use_param_file("%s", use_always = True)
    args.set_param_file_format("multiline")

    args.add_all(
        indexstore_and_target_overrides,
        map_each = _directory_and_target_override,
    )

    output = actions.declare_file("{}-{}.filelist".format(rule_name, name))

    # We make an action to copy the params file, because we want to force the
    # downloading of `indexstores`. We don't want to directly place the
    # `indexstores` in an output group to prevent the explosion of the BEP.
    actions.run_shell(
        arguments = [args, output.path],
        inputs = indexstores,
        outputs = [output],
        command = """\
if [[ $(stat -f '%d' "$1") == $(stat -f '%d' "${2%/*}") ]]; then
  cp -c "$1" "$2"
else
  cp "$1" "$2"
fi
""",
        mnemonic = "WriteIndexstoreFilelist",
        # The action is simply a file copy, would be slower if remote.
        # Same for caching in any way.  Also no need for sandboxing.
        execution_requirements = {
            "no-cache": "1",
            "no-remote": "1",
            "no-sandbox": "1",
        },
    )

    return output

indexstore_filelists = struct(
    write = _write,
)

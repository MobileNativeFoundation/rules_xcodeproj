"""Module containing functions dealing with indexstore file lists."""

def _directory_and_target_override(directory_and_target_override):
    directory, target_override = directory_and_target_override
    return [directory.path, target_override]

def _write(*, actions, name, rule_name, indexstore_and_target_overrides):
    args = actions.args()
    args.set_param_file_format("multiline")
    args.add_all(
        indexstore_and_target_overrides,
        map_each = _directory_and_target_override,
    )

    output = actions.declare_file("{}-{}.filelist".format(rule_name, name))
    actions.write(output, args)

    return output

indexstore_filelists = struct(
    write = _write,
)

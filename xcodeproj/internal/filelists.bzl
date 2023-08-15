"""Module containing functions dealing with file lists."""

load(":memory_efficiency.bzl", "EMPTY_DEPSET")

def _write(*, actions, rule_name, name, files):
    if files == None:
        files = EMPTY_DEPSET

    args = actions.args()
    args.set_param_file_format("multiline")
    args.add_all(files, expand_directories = False)

    output = actions.declare_file("{}-{}.filelist".format(rule_name, name))
    actions.write(output, args)

    return output

filelists = struct(
    write = _write,
)

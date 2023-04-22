"""Module containing functions dealing with file lists."""

load(":memory_efficiency.bzl", "EMPTY_DEPSET")

def _write(*, ctx, rule_name, name, files):
    if files == None:
        files = EMPTY_DEPSET

    args = ctx.actions.args()
    args.use_param_file("%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add_all(files, expand_directories = False)

    output = ctx.actions.declare_file("{}-{}.filelist".format(rule_name, name))
    ctx.actions.write(output, args)

    return output

filelists = struct(
    write = _write,
)

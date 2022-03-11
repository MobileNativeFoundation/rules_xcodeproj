"""Implementation of the `input_files_aspect` aspect."""

InputFilesInfo = provider(
    "Provides information about input files of a target.",
    fields = {
        "files": """\
A `depset` of `File`s that were used as inputs to this target and its transitive
dependencies.
""",
    },
)

def _handle_dep(dep, transitive_files):
    if dep and InputFilesInfo in dep:
        transitive_files.append(dep[InputFilesInfo].files)

def _handle_file(file, files):
    if file and file.is_source:
        files.append(file)

def _should_ignore_attr(attr):
    # We don't want to include implicit dependencies
    return attr in ("to_json", "to_proto") or attr.startswith("_")

def _input_files_aspect_impl(target, ctx):
    files = []
    transitive_files = []

    for attr in dir(ctx.rule.files):
        if _should_ignore_attr(attr):
            continue
        dep = getattr(ctx.rule.attr, attr)
        if type(dep) == "list":
            for dep in dep:
                _handle_dep(dep, transitive_files)
        else:
            _handle_dep(dep, transitive_files)
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, files)

    for attr in dir(ctx.rule.file):
        if _should_ignore_attr(attr):
            continue
        _handle_dep(getattr(ctx.rule.attr, attr), transitive_files)
        _handle_file(getattr(ctx.rule.file, attr), files)

    return [
        InputFilesInfo(
            files = depset(files, transitive = transitive_files),
        ),
    ]

input_files_aspect = aspect(
    implementation = _input_files_aspect_impl,
    attr_aspects = ["*"],
)

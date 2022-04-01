"""Functions to deal with target input files."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "flatten")
load(":files.bzl", "file_path", "file_path_to_dto")
load(":logging.bzl", "warn")
load(":providers.bzl", "InputFileAttributesInfo")

# Utility

# Extensions that represent built targets. If these are seen in
# `InputFilesInfo.generated`, then it means an attr wasn't properly excluded.
_SUSPECT_GENERATED_EXTENSIONS = (
    ".a",
    ".app",
    ".appex",
    ".bundle",
    ".dylib",
    ".framework",
    ".kext",
    ".mdimporter",
    ".prefPane",
    ".qlgenerator",
    ".swiftdoc",
    ".swiftinterface",
    ".swiftmodule",
    ".xcframework",
    ".xctest",
    ".xpc",
)

def _collect_transitive_extra_files(info):
    inputs = info.inputs
    transitive = [inputs.extra_files]
    if not info.target:
        transitive.append(inputs.srcs)
        transitive.append(inputs.non_arc_srcs)
        transitive.append(inputs.hdrs)
    return transitive

def _should_ignore_attr(attr, *, excluded_attrs):
    return (
        attr in excluded_attrs or
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

# API

def _collect(
        *,
        ctx,
        target,
        additional_files = [],
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        additional_files: A `list` of `File`s to add to the inputs. This can
            be used to add files to the `generated` and `extra_files` fields
            (e.g. modulemaps or BUILD files).
        transitive_infos: A list of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:
        A `struct` with the following fields:

        *   `srcs`: A `depset` of `File`s that are inputs to `target`'s
            `srcs`-like attributes.
        *   `hdrs`: A `depset` of `File`s that are inputs to `target`'s
            `hdrs`-like attributes.
        *   `non_arc_srcs`: A `depset` of `File`s that are inputs to
            `target`'s `non_arc_srcs`-like attributes.
        *   `generated`: A `depset` of generated `File`s that are inputs to
            `target` or its transitive dependencies.
        *   `extra_files`: A `depset` of `File`s that are inputs to `target`
            that didn't fall into one of the more specific (e.g. `srcs`)
            catagories. This also includes files of transitive dependencies
            that didn't create an Xcode target.
    """
    attrs_info = target[InputFileAttributesInfo]
    output_files = target.files.to_list()

    srcs = []
    non_arc_srcs = []
    hdrs = []
    generated = []
    extra_files = []

    # buildifier: disable=uninitialized
    def _handle_file(file, *, attr):
        if file:
            if not file.is_source:
                generated.append(file)

            if attr in attrs_info.srcs:
                srcs.append(file)
            elif attr in attrs_info.non_arc_srcs:
                non_arc_srcs.append(file)
            elif attr in attrs_info.hdrs:
                hdrs.append(file)
            elif file not in output_files:
                extra_files.append(file)

    excluded_attrs = attrs_info.excluded

    for attr in dir(ctx.rule.files):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, attr = attr)

    for attr in dir(ctx.rule.file):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        _handle_file(getattr(ctx.rule.file, attr), attr = attr)

    # Sanity check to insure that we are excluding files correctly
    suspect_files = [
        file
        for file in generated
        if paths.split_extension(file.path)[1] in _SUSPECT_GENERATED_EXTENSIONS
    ]
    if suspect_files:
        warn("""\
Collected generated files for {target} that probably shouldn't have been \
collected:
{files}

If you are providing a custom `InputFileAttributesInfo`, ensure that the \
`excluded_attrs` attribute excludes the correct attributes.
If you think this is a bug, please file a bug report at \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
""".format(target = target.label, files = suspect_files))

    generated.extend([file for file in additional_files if not file.is_source])
    extra_files.extend(additional_files)

    return struct(
        srcs = depset(srcs),
        non_arc_srcs = depset(non_arc_srcs),
        hdrs = depset(hdrs),
        generated = depset(
            generated,
            transitive = [
                info.inputs.generated
                for _, info in transitive_infos
            ],
        ),
        extra_files = depset(
            extra_files,
            transitive = flatten([
                _collect_transitive_extra_files(info)
                for _, info in transitive_infos
            ]),
        ),
    )

def _merge(inputs = None, *, transitive_infos):
    """Creates merged inputs.

    Args:
        inputs: The inputs, as returned by `input_files.collect()`, of the
            current target, or `None`.
        transitive_infos: A list of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to one returned from `input_files.collect()`. The values
        include the ones from `inputs` if it wasn't `None`, and in some cases
        the inputs from the inputs of the transitive dependencies, via
        `transitive_infos` (e.g. `generated` and `extra_files`)
    """
    return struct(
        srcs = inputs.srcs if inputs else depset(),
        non_arc_srcs = inputs.non_arc_srcs if inputs else depset(),
        hdrs = inputs.hdrs if inputs else depset(),
        generated = depset(
            transitive = ([inputs.generated] if inputs else []) + [
                info.inputs.generated
                for _, info in transitive_infos
            ],
        ),
        extra_files = depset(
            transitive = ([inputs.extra_files] if inputs else []) + [
                info.inputs.extra_files
                for _, info in transitive_infos
            ],
        ),
    )

def _to_dto(inputs):
    """Generates a target DTO value for inputs.

    Args:
        inputs: A value returned from `input_files.collect()`.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
    """
    ret = {}

    def _process_attr(attr):
        value = getattr(inputs, attr)
        if value:
            ret[attr] = [
                file_path_to_dto(file_path(file))
                for file in value.to_list()
            ]

    _process_attr("srcs")
    _process_attr("non_arc_srcs")
    _process_attr("hdrs")

    return ret

input_files = struct(
    collect = _collect,
    merge = _merge,
    to_dto = _to_dto,
)

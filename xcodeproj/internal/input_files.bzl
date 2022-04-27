"""Module containing functions dealing with target input files."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "flatten", "set_if_true")
load(":files.bzl", "file_path", "file_path_to_dto", "join_paths_ignoring_empty", "parsed_file_path")
load(":logging.bzl", "warn")
load(":output_group_map.bzl", "output_group_map")

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
        transitive.append(depset([
            file_path(file)
            for file in inputs.srcs.to_list()
        ]))
        transitive.append(depset([
            file_path(file)
            for file in inputs.non_arc_srcs.to_list()
        ]))
        transitive.append(depset([
            file_path(file)
            for file in inputs.hdrs.to_list()
        ]))

    return transitive

def _should_include_transitive_resources(*, attrs_info, attr, info):
    return ((not info.target or not info.target.is_bundle) and
            (not attrs_info or
             info.target_type in attrs_info.resources.get(attr, [None])))

def _should_ignore_attr(attr, *, excluded_attrs):
    return (
        attr in excluded_attrs or
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _folder_resource_file_path(*, target, file):
    package_dir = join_paths_ignoring_empty(
        target.label.workspace_root,
        target.label.package,
    )
    path = file.path

    if not path.startswith(package_dir):
        fail("""\
Structured resources must come from the same package as the target. {} is not \
in {}""".format(file, target.label))

    relative_path = path[len(package_dir) + 1:]
    relative_folder, _, _ = relative_path.partition("/")

    return file_path(
        file,
        path = join_paths_ignoring_empty(package_dir, relative_folder),
        is_folder = True,
    )

def _bundle_import_file_path(*, target, file):
    package_dir = join_paths_ignoring_empty(
        target.label.workspace_root,
        target.label.package,
    )
    path = file.path

    if not path.startswith(package_dir):
        fail("""\
Bundle import paths must come from the same package as the target. {} is not \
in {}""".format(file, target.label))

    relative_path = path[len(package_dir) + 1:]
    prefix, ext, _ = relative_path.rpartition(".bundle")
    if not ext:
        fail("Expected file.path %r to contain .bundle, but it did not" % (
            file,
        ))

    relative_bundle = prefix + ext

    return file_path(
        file,
        path = join_paths_ignoring_empty(package_dir, relative_bundle),
        is_folder = True,
    )

# API

def _collect(
        *,
        ctx,
        target,
        attrs_info,
        owner,
        additional_files = [],
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        owner: An optional string that has a unique identifier for `target`, if
            it owns the resources. Only targets that become Xcode targets should
            own resources.
        attrs_info: The `InputFileAttributesInfo` for `target`.
        additional_files: A `list` of `File`s to add to the inputs. This can
            be used to add files to the `generated` and `extra_files` fields
            (e.g. modulemaps or BUILD files).
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:
        A `struct` with the following fields:

        *   `srcs`: A `depset` of `File`s that are inputs to `target`'s
            `srcs`-like attributes.
        *   `hdrs`: A `depset` of `File`s that are inputs to `target`'s
            `hdrs`-like attributes.
        *   `non_arc_srcs`: A `depset` of `File`s that are inputs to
            `target`'s `non_arc_srcs`-like attributes.
        *   `resources`: A `depset` of `FilePath`s that are inputs to `target`'s
            `resources`-like and `structured_resources`-like attributes.
        *   `generated`: A `depset` of generated `File`s that are inputs to
            `target` or its transitive dependencies.
        *   `extra_files`: A `depset` of `FilePath`s that are inputs to `target`
            that didn't fall into one of the more specific (e.g. `srcs`)
            catagories. This also includes files of transitive dependencies
            that didn't create an Xcode target.
    """
    output_files = target.files.to_list()

    srcs = []
    non_arc_srcs = []
    hdrs = []
    pch = []
    resources = []
    unowned_resources = []
    generated = []
    extra_files = []

    # Include BUILD files for the project but not for external repos
    if not target.label.workspace_root:
        extra_files.append(parsed_file_path(ctx.build_file_path))

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
            elif attr == attrs_info.pch:
                # We use `append` instead of setting a single value because
                # assigning to `pch` creates a new local variable instead of
                # assigning to the existing variable
                pch.append(file)
            elif attrs_info.resources.get(attr):
                fp = file_path(file)
                if owner:
                    resources.append((owner, fp))
                else:
                    unowned_resources.append(fp)
            elif attr in attrs_info.structured_resources:
                fp = _folder_resource_file_path(
                    target = target,
                    file = file,
                )
                if owner:
                    resources.append((owner, fp))
                else:
                    unowned_resources.append(fp)
            elif attr in attrs_info.bundle_imports:
                fp = _bundle_import_file_path(
                    target = target,
                    file = file,
                )
                if owner:
                    resources.append((owner, fp))
                else:
                    unowned_resources.append(fp)
            elif file not in output_files:
                extra_files.append(file_path(file))

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
    for file in additional_files:
        extra_files.append(file_path(file))

    unowned_resources_depset = depset(
        None if owner else unowned_resources,
        transitive = [
            info.inputs._unowned_resources
            for attr, info in transitive_infos
            if _should_include_transitive_resources(
                attrs_info = attrs_info,
                attr = attr,
                info = info,
            )
        ],
    )
    if owner:
        resources.extend([
            (owner, fp)
            for fp in unowned_resources_depset.to_list()
        ])
        unowned_resources_depset = depset()

    return struct(
        _unowned_resources = unowned_resources_depset,
        _resource_owners = depset(
            [owner] if owner else None,
            transitive = [
                info.inputs._resource_owners
                for attr, info in transitive_infos
                if _should_include_transitive_resources(
                    attrs_info = attrs_info,
                    attr = attr,
                    info = info,
                )
            ],
        ),
        srcs = depset(srcs),
        non_arc_srcs = depset(non_arc_srcs),
        hdrs = depset(hdrs),
        pch = pch[0] if pch else None,
        resources = depset(
            resources,
            transitive = [
                info.inputs.resources
                for attr, info in transitive_infos
                if _should_include_transitive_resources(
                    attrs_info = attrs_info,
                    attr = attr,
                    info = info,
                )
            ],
        ),
        contains_generated_files = bool(generated),
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

def _merge(*, attrs_info, transitive_infos):
    """Creates merged inputs.

    Args:
        attrs_info: The `InputFileAttributesInfo` for the target.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    return struct(
        _unowned_resources = depset(
            transitive = [
                info.inputs._unowned_resources
                for attr, info in transitive_infos
                if _should_include_transitive_resources(
                    attrs_info = attrs_info,
                    attr = attr,
                    info = info,
                )
            ],
        ),
        _resource_owners = depset(
            transitive = [
                info.inputs._resource_owners
                for attr, info in transitive_infos
                if _should_include_transitive_resources(
                    attrs_info = attrs_info,
                    attr = attr,
                    info = info,
                )
            ],
        ),
        srcs = depset(),
        non_arc_srcs = depset(),
        hdrs = depset(),
        pch = None,
        resources = depset(
            transitive = [
                info.inputs.resources
                for attr, info in transitive_infos
                if _should_include_transitive_resources(
                    attrs_info = attrs_info,
                    attr = attr,
                    info = info,
                )
            ],
        ),
        generated = depset(
            transitive = [
                info.inputs.generated
                for _, info in transitive_infos
            ],
        ),
        extra_files = depset(
            transitive = [
                info.inputs.extra_files
                for _, info in transitive_infos
            ],
        ),
    )

def _to_dto(inputs, *, is_bundle, avoid_infos):
    """Generates a target DTO value for inputs.

    Args:
        inputs: A value returned from `input_files.collect`.
        is_bundle: Whether the target is a bundle.
        avoid_infos: A list of `XcodeProjInfo`s for the targets that already
            consumed resources, and their resources shouldn't be included in
            the DTO.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
        *   `resources`: A `list` of `FilePath`s for `resources`.
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

    if inputs.pch:
        ret["pch"] = file_path_to_dto(file_path(inputs.pch))

    if is_bundle and inputs.resources:
        avoid_owners = depset(
            transitive = [
                info.inputs._resource_owners
                for _, info in avoid_infos
            ],
        ).to_list()

        set_if_true(
            ret,
            "resources",
            [
                file_path_to_dto(fp)
                for owner, fp in inputs.resources.to_list()
                if owner not in avoid_owners
            ],
        )

    set_if_true(
        ret,
        "contains_generated_files",
        inputs.contains_generated_files,
    )

    return ret

def _to_output_groups_fields(*, ctx, inputs, toplevel_cache_buster):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        ctx: The rule context.
        inputs: A value returned from `input_files.collect`.
        toplevel_cache_buster: A `list` of `File`s that change with each build,
            and are used as inputs to the output map generation, to ensure that
            the files references by the output map are always downloaded from
            the remote cache, even when using `--remote_download_toplevel`.

    Returns:
        A `dict` where the keys are output group names and the values are
        `depset` of `File`s.
    """
    return {
        "generated_inputs": depset([output_group_map.write_map(
            ctx = ctx,
            name = "generated_inputs",
            files = inputs.generated,
            toplevel_cache_buster = toplevel_cache_buster,
        )]),
    }

input_files = struct(
    collect = _collect,
    merge = _merge,
    to_dto = _to_dto,
    to_output_groups_fields = _to_output_groups_fields,
)

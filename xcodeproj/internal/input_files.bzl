"""Module containing functions dealing with target input files."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
    "join_paths_ignoring_empty",
    "parsed_file_path",
)
load(":logging.bzl", "warn")
load(":output_group_map.bzl", "output_group_map")
load(":providers.bzl", "XcodeProjInfo")

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

    return depset(transitive = transitive)

def _collect_transitive_uncategorized(info):
    if info.target:
        return depset()
    return info.inputs.uncategorized

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

_BUNDLE_EXTENSIONS = [
    ".bundle",
    ".framework",
    ".xcframework",
]

def _normalized_file_path(file):
    path = file.path

    for extension in _BUNDLE_EXTENSIONS:
        prefix, ext, _ = path.partition(extension)
        if not ext:
            continue
        return file_path(
            file,
            path = prefix + ext,
        )

    return file_path(file)

def _is_categorized_attr(attr, *, attrs_info):
    if attr in attrs_info.srcs:
        return True
    elif attr in attrs_info.non_arc_srcs:
        return True
    elif attr in attrs_info.hdrs:
        return True
    elif attr == attrs_info.pch:
        return True
    elif attrs_info.resources.get(attr):
        return True
    elif attr in attrs_info.structured_resources:
        return True
    elif attr in attrs_info.infoplists:
        return True
    elif attr == attrs_info.entitlements:
        return True
    elif attr in attrs_info.bundle_imports:
        return True
    else:
        return False

def _process_cc_info_headers(headers, *, pch):
    return [
        header
        for header in headers
        if (header.is_source and
            ".framework" not in header.path and
            header not in pch)
    ]

# API

def _collect(
        *,
        ctx,
        target,
        bundle_resources,
        attrs_info,
        owner,
        additional_files = [],
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        bundle_resources: Whether resources will be bundled in the generated
            project. If this is `False` then all resources will get added to
            `extra_files` instead of `resources`.
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
        *   `xccurrentversions`: A `depset` of `.xccurrentversion` `File`s that
            are in `resources`.
        *   `generated`: A `depset` of generated `File`s that are inputs to
            `target` or its transitive dependencies.
        *   `extra_files`: A `depset` of `FilePath`s that should be included in
            the project, but aren't necessarily inputs to the target. This also
            includes some categorized files of transitive dependencies
            that didn't create an Xcode target.
        *   `uncategorized`: A `depset` of `FilePath`s that are inputs to
            `target` didn't fall into one of the more specific (e.g. `srcs`)
            categories. These will only be included in the Xcode project if this
            target becomes an input to another target's categorized attribute.
    """
    output_files = target.files.to_list()

    srcs = []
    non_arc_srcs = []
    hdrs = []
    pch = []
    resources = []
    unowned_resources = []
    entitlements = []
    xccurrentversions = []
    generated = []
    extra_files = []
    uncategorized = []

    # Include BUILD files for the project but not for external repos
    if not target.label.workspace_root:
        extra_files.append(parsed_file_path(ctx.build_file_path))

    def _process_resource_file_path(fp):
        if bundle_resources:
            if owner:
                resources.append((owner, fp))
            else:
                unowned_resources.append(fp)
        else:
            extra_files.append(fp)

    # buildifier: disable=uninitialized
    def _handle_file(file, *, attr):
        if file == None:
            return

        categorized = True
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
            if (file.basename == ".xccurrentversion" and
                file.dirname.endswith(".xcdatamodeld")):
                xccurrentversions.append(file)
            else:
                _process_resource_file_path(fp)
        elif attr in attrs_info.structured_resources:
            fp = _folder_resource_file_path(
                target = target,
                file = file,
            )
            _process_resource_file_path(fp)
        elif attr in attrs_info.infoplists:
            if file.is_source:
                # We don't need to include a generated one, as we already use
                # the Bazel generated one, which is one step further generated
                extra_files.append(file_path(file))
        elif attr == attrs_info.entitlements:
            # We use `append` instead of setting a single value because
            # assigning to `entitlements` creates a new local variable instead
            # of assigning to the existing variable
            entitlements.append(file)
        elif attr in attrs_info.bundle_imports:
            fp = _bundle_import_file_path(
                target = target,
                file = file,
            )
            _process_resource_file_path(fp)
        else:
            categorized = False

        if file.is_source:
            if not categorized and file not in output_files:
                uncategorized.append(_normalized_file_path(file))
        elif categorized:
            generated.append(file)

            # Sanity check to insure that we are excluding files correctly
            if (paths.split_extension(file.path)[1] in
                _SUSPECT_GENERATED_EXTENSIONS):
                warn("Collecting {} from {} in {}".format(
                    file,
                    attr,
                    target.label,
                ))
                warn("""\
Collected generated file "{file}" for {target} from the "{attr}" attribute \
that probably shouldn't have been collected.

If you are providing a custom `InputFileAttributesInfo`, ensure that the \
`excluded` attribute excludes the correct attributes.

If you think this is a bug, please file a bug report at \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
""".format(attr = attr, file = file.path, target = target.label))

    excluded_attrs = attrs_info.excluded

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep, *, attr):
        if (XcodeProjInfo not in dep or
            not _is_categorized_attr(attr, attrs_info = attrs_info)):
            return
        transitive_extra_files.append(dep[XcodeProjInfo].inputs.uncategorized)

    for attr in dir(ctx.rule.files):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, attr = attr)

    for attr in dir(ctx.rule.file):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        _handle_file(getattr(ctx.rule.file, attr), attr = attr)

    for attr in dir(ctx.rule.attr):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        dep = getattr(ctx.rule.attr, attr, None)
        if type(dep) == "Target":
            _handle_dep(dep, attr = attr)
        elif type(dep) == "list":
            for dep in dep:
                if type(dep) == "Target":
                    _handle_dep(dep, attr = attr)

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

    # Generically handle CcInfo providing rules. This allows us to pick up
    # headers from `objc_import` and the like.
    if CcInfo in target:
        compilation_context = target[CcInfo].compilation_context
        srcs.extend(
            _process_cc_info_headers(
                compilation_context.direct_private_headers,
                pch = pch,
            ),
        )
        hdrs.extend(
            _process_cc_info_headers(
                (compilation_context.direct_public_headers +
                 compilation_context.direct_textual_headers),
                pch = pch,
            ),
        )

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
        entitlements = entitlements[0] if entitlements else None,
        xccurrentversions = depset(
            xccurrentversions,
            transitive = [
                info.inputs.xccurrentversions
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        generated = depset(
            generated,
            transitive = [
                info.inputs.generated
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        extra_files = depset(
            extra_files,
            transitive = [
                _collect_transitive_extra_files(info)
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ] + transitive_extra_files,
        ),
        uncategorized = depset(
            uncategorized,
            transitive = [
                _collect_transitive_uncategorized(info)
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
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
        entitlements = None,
        xccurrentversions = depset(
            transitive = [
                info.inputs.xccurrentversions
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        generated = depset(
            transitive = [
                info.inputs.generated
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        extra_files = depset(
            transitive = [
                info.inputs.extra_files
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
            ],
        ),
        uncategorized = depset(
            transitive = [
                info.inputs.uncategorized
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in
                    attrs_info.xcode_targets.get(attr, [None]))
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
        *   `pch`: An optional `FilePath` for `pch`.
        *   `resources`: A `list` of `FilePath`s for `resources`.
        *   `entitlements`: An optional `FilePath` for `entitlements`.
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

    if inputs.entitlements:
        ret["entitlements"] = file_path_to_dto(file_path(inputs.entitlements))

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

    return ret

def _to_output_groups_fields(
        *,
        ctx,
        inputs,
        toplevel_cache_buster,
        configuration):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        ctx: The rule context.
        inputs: A value returned from `input_files.collect`.
        toplevel_cache_buster: A `list` of `File`s that change with each build,
            and are used as inputs to the output map generation, to ensure that
            the files references by the output map are always downloaded from
            the remote cache, even when using `--remote_download_toplevel`.
        configuration: The configuration identifier (see "configuration.bzl"'s
            `get_configuration`) for the project.

    Returns:
        A `dict` where the keys are output group names and the values are
        `depset` of `File`s.
    """
    name = "generated_inputs {}".format(configuration)
    return {
        name: depset([output_group_map.write_map(
            ctx = ctx,
            name = name,
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

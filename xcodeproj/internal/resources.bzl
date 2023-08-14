""" Functions for collecting resource usage information."""

load("@build_bazel_rules_apple//apple:resources.bzl", "resources_common")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":configuration.bzl", "calculate_configuration")
load(
    ":files.bzl",
    "RESOURCES_FOLDER_TYPE_EXTENSIONS",
    "join_paths_ignoring_empty",
    "normalized_file_path",
)
load(":memory_efficiency.bzl", "memory_efficient_depset")
load(":target_id.bzl", "get_id")

# Utility

def _normalize_resource_path(resource):
    for extension in RESOURCES_FOLDER_TYPE_EXTENSIONS:
        if extension not in resource:
            continue
        prefix, ext, _ = resource.partition(extension)
        return prefix + ext

    return resource

def _update_bundle_owner_resource_tuples(
        *,
        resource,
        owner_resource_tuples,
        resource_to_owners):
    resource_owners = resource_to_owners.get(resource, {})
    if not resource_owners:
        owner_resource_tuples.append((None, resource))
    for resource_owner in resource_owners:
        owner_resource_tuples.append((resource_owner, resource))

def _processed_resource_fields(resources_info):
    return [
        f
        for f in dir(resources_info)
        if f not in [
            "infoplists",
            "owners",
            "processed_origins",
            "unowned_resources",
            "unprocessed",
            "to_json",
            "to_proto",
        ]
    ]

def _process_resource(
        *,
        bundle_path,
        file,
        bundle_metadata,
        generated,
        xccurrentversions):
    if not file.is_source:
        generated.append(file)

    if (file.basename == ".xccurrentversion" and
        file.dirname.endswith(".xcdatamodeld")):
        xccurrentversions.append(file)
        return None

    if not file.is_source:
        generated.append(file)
        if bundle_path and file.basename == "Info.plist":
            fp = file.path
            path_components = fp.split("/")
            label = file.owner
            configuration = calculate_configuration(bin_dir_path = fp)
            bundle_metadata[bundle_path] = struct(
                label = label,
                configuration = configuration,
                infoplist = file,
                id = get_id(label = label, configuration = configuration),
                package_bin_dir = "/".join(path_components[:-3]),
            )

            return None

    return normalized_file_path(
        file,
        folder_type_extensions = RESOURCES_FOLDER_TYPE_EXTENSIONS,
    )

def _add_resources_to_bundle(
        *,
        bundle,
        bundle_path,
        files,
        bundle_metadata,
        generated,
        xccurrentversions,
        resource_to_owners):
    for file in files.to_list():
        fp = _process_resource(
            bundle_path = bundle_path,
            file = file,
            bundle_metadata = bundle_metadata,
            generated = generated,
            xccurrentversions = xccurrentversions,
        )
        if fp:
            _update_bundle_owner_resource_tuples(
                resource = fp,
                owner_resource_tuples = bundle.resources,
                resource_to_owners = resource_to_owners,
            )

def _create_bundle(name = None):
    return struct(
        name = name,
        resources = [],
        folder_resources = [],
        dependency_paths = [],
    )

def _add_structured_resources_to_bundle(
        bundle,
        *,
        nested_path,
        files,
        generated,
        resource_to_owners):
    if nested_path:
        inner_dir = nested_path.split("/")[0]
    else:
        inner_dir = None

    for file in files.to_list():
        if not file.is_source:
            generated.append(file)

        if not inner_dir:
            _update_bundle_owner_resource_tuples(
                resource = file.path,
                owner_resource_tuples = bundle.resources,
                resource_to_owners = resource_to_owners,
            )
            continue

        # Special case for localized
        if inner_dir.endswith(".lproj"):
            _update_bundle_owner_resource_tuples(
                resource = file.path,
                owner_resource_tuples = bundle.resources,
                resource_to_owners = resource_to_owners,
            )
            continue

        if file.is_directory:
            dir = file.path
        else:
            dir = file.dirname

        if not dir.endswith(nested_path):
            continue

        folder_resource = paths.join(dir[:-(1 + len(nested_path))], inner_dir)
        _update_bundle_owner_resource_tuples(
            resource = folder_resource,
            owner_resource_tuples = bundle.folder_resources,
            resource_to_owners = resource_to_owners,
        )

def _add_structured_resources(
        *,
        root_bundle,
        resource_bundle_targets,
        bundle_path,
        nested_path,
        files,
        generated,
        resource_to_owners):
    bundle = resource_bundle_targets.get(bundle_path)

    if bundle:
        if (not bundle.resources and
            not bundle.folder_resources and
            len(bundle_path.split(".bundle")) > 2):
            # This covers a deficiency in rules_apple's `_deduplicate` for
            # nested bundles that should be excluded
            return
        _add_structured_resources_to_bundle(
            bundle,
            nested_path = nested_path,
            files = files,
            generated = generated,
            resource_to_owners = resource_to_owners,
        )
    else:
        _add_structured_resources_to_bundle(
            root_bundle,
            nested_path = join_paths_ignoring_empty(bundle_path, nested_path),
            files = files,
            generated = generated,
            resource_to_owners = resource_to_owners,
        )

def _add_processed_resources(
        *,
        resources,
        root_bundle,
        resource_bundle_targets,
        bundle_metadata,
        generated,
        xccurrentversions,
        resource_to_owners):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_resources_to_bundle(
                bundle = root_bundle,
                bundle_path = None,
                files = files,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
                resource_to_owners = resource_to_owners,
            )
            continue

        prefix, ext, _ = parent_dir.rpartition(".bundle")
        if not ext:
            _add_resources_to_bundle(
                bundle = root_bundle,
                bundle_path = None,
                files = files,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
                resource_to_owners = resource_to_owners,
            )
            continue

        bundle_path = prefix + ext
        bundle = resource_bundle_targets[bundle_path]
        _add_resources_to_bundle(
            bundle = bundle,
            bundle_path = bundle_path,
            files = files,
            bundle_metadata = bundle_metadata,
            generated = generated,
            xccurrentversions = xccurrentversions,
            resource_to_owners = resource_to_owners,
        )

def _add_unprocessed_resources(
        *,
        resources,
        root_bundle,
        resource_bundle_targets,
        parent_bundle_paths,
        bundle_metadata,
        generated,
        xccurrentversions,
        resource_to_owners):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_resources_to_bundle(
                bundle = root_bundle,
                bundle_path = None,
                files = files,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
                resource_to_owners = resource_to_owners,
            )
            continue

        bundle_path = None
        nested_path = parent_dir
        for parent_bundle_path in parent_bundle_paths:
            if parent_dir.startswith(parent_bundle_path):
                bundle_path = parent_bundle_path
                nested_path = parent_dir[len(bundle_path) + 1:]
                break

        _add_structured_resources(
            root_bundle = root_bundle,
            resource_bundle_targets = resource_bundle_targets,
            bundle_path = bundle_path,
            nested_path = nested_path,
            files = files,
            generated = generated,
            resource_to_owners = resource_to_owners,
        )

# API

def collect_resources(
        *,
        platform,
        resource_info,
        avoid_resource_infos):
    """Collects resource information for a target.

    Args:
        platform: A value returned from `platforms.collect`.
        resource_info: The `AppleResourceInfo` provider for the target.
        avoid_resource_infos: A `list` of `AppleResourceInfo` providers from
            targets that should be avoided (e.g. test hosts).

    Returns:
        A `struct` with the following fields:

        *   `bundles`: A `list` of `struct`s that are to be passed to
            `process_resource_bundles`.
        *   `dependencies`: A `list` of `id`s of resource bundle targets that
            this target depends on.
        *   `resources`: A `list` of tuples (`owner, `file_path`) of resources
            that should be added to the target's bundle.
        *   `generated`: A `list` of `file_path`s of generated resources.
        *   `xccurrentversions`: A `list` of `.xccurrentversion` `File`s.
        *   `extra_files`: A `list` of `file_path`s of extra files.
    """
    root_bundle = _create_bundle()
    resource_bundle_targets = {}
    generated = []
    xccurrentversions = []
    extra_files = []
    bundle_metadata = {}
    resource_to_owners = {}

    processed_fields = _processed_resource_fields(resource_info)

    for (resource, owner) in resource_info.owners.to_list():
        resource = _normalize_resource_path(resource)

        # a resource can have multiple owners
        resource_to_owners.setdefault(resource, {})[owner] = None

    # Create the bundles, regardless of avoiding duplicates, to work around
    # a rules_apple bug
    for field in processed_fields:
        for parent_dir, _, _ in getattr(resource_info, field, []):
            if not parent_dir:
                continue

            prefix, ext, _ = parent_dir.rpartition(".bundle")
            if not ext:
                continue

            bundle_path = prefix + ext
            resource_bundle_targets.setdefault(
                bundle_path,
                _create_bundle(paths.basename(prefix)),
            )

    parent_bundle_paths = sorted(resource_bundle_targets, reverse = True)

    # buildifier: disable=uninitialized
    def _deduplicated_field_handler(field, deduplicated):
        if field == "infoplists":
            return
        if field == "unprocessed":
            _add_unprocessed_resources(
                resources = deduplicated,
                root_bundle = root_bundle,
                resource_bundle_targets = resource_bundle_targets,
                parent_bundle_paths = parent_bundle_paths,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
                resource_to_owners = resource_to_owners,
            )
        else:
            _add_processed_resources(
                resources = deduplicated,
                root_bundle = root_bundle,
                resource_bundle_targets = resource_bundle_targets,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
                resource_to_owners = resource_to_owners,
            )

    resources_common.deduplicate(
        resources_provider = resource_info,
        avoid_providers = avoid_resource_infos,
        field_handler = _deduplicated_field_handler,
    )

    for child_bundle_path in parent_bundle_paths:
        bundle = resource_bundle_targets[child_bundle_path]
        if (not bundle.resources and
            not bundle.folder_resources and
            not bundle.dependency_paths):
            resource_bundle_targets.pop(child_bundle_path, None)
            continue

        parent = root_bundle
        for parent_bundle_path in parent_bundle_paths:
            if parent_bundle_path == child_bundle_path:
                continue
            if child_bundle_path.startswith(parent_bundle_path):
                parent = resource_bundle_targets[parent_bundle_path]
                break
        parent.dependency_paths.append(child_bundle_path)

    frozen_bundles = []
    for bundle_path in parent_bundle_paths:
        bundle = resource_bundle_targets.get(bundle_path)
        metadata = bundle_metadata.get(bundle_path)
        if bundle and metadata:
            extra_files.append(metadata.infoplist.path)
            frozen_bundles.append(
                struct(
                    name = bundle.name,
                    label = metadata.label,
                    configuration = metadata.configuration,
                    id = metadata.id,
                    infoplist = metadata.infoplist,
                    package_bin_dir = metadata.package_bin_dir,
                    platform = platform,
                    resources = tuple(bundle.resources),
                    folder_resources = tuple(bundle.folder_resources),
                    dependencies = memory_efficient_depset([
                        bundle_metadata[bundle_path].id
                        for bundle_path in bundle.dependency_paths
                    ]),
                ),
            )

    return struct(
        bundles = frozen_bundles,
        dependencies = [
            bundle.id
            for bundle in [
                bundle_metadata.get(bundle_path)
                for bundle_path in root_bundle.dependency_paths
            ]
            if bundle
        ],
        resources = root_bundle.resources,
        folder_resources = root_bundle.folder_resources,
        generated = generated,
        xccurrentversions = xccurrentversions,
        extra_files = extra_files,
    )

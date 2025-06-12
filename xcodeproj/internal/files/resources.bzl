"""Module that collects resource file usage."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_apple//apple:resources.bzl", "resources_common")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:memory_efficiency.bzl", "memory_efficient_depset")
load("//xcodeproj/internal:target_id.bzl", "get_id")

# Utility

_FOLDER_TYPE_FILE_SUFFIXES = [
    ".bundle/",
    ".docc/",
    ".framework/",
    ".scnassets/",
    ".xcassets/",
]

_IGNORED_RESOURCE_FIELDS = {
    "infoplists": None,
    "owners": None,
    "processed_origins": None,
    "to_json": None,
    "to_proto": None,
    "unowned_resources": None,
    "unprocessed": None,
}

def _processed_resource_fields(resources_info):
    return [
        f
        for f in dir(resources_info)
        if f not in _IGNORED_RESOURCE_FIELDS
    ]

def _create_bundle(name = None):
    return struct(
        name = name,
        resources = [],
        resource_file_paths = [],
        generated_resource_file_paths = [],
        dependency_paths = [],
    )

def _handle_processed_resource(
        *,
        bundle,
        bundle_metadata,
        bundle_path,
        file,
        focused_resource_short_paths,
        processed_origins):
    if not file.is_source:
        if bundle_path and file.basename == "Info.plist":
            path_components = file.path.split("/")
            label = file.owner
            configuration = calculate_configuration(bin_dir_path = file.path)
            bundle_metadata[bundle_path] = struct(
                label = label,
                configuration = configuration,
                id = get_id(label = label, configuration = configuration),
                package_bin_dir = "/".join(path_components[:-3]),
            )

    short_path = file.short_path
    origin_short_paths = processed_origins.get(short_path)
    if not origin_short_paths:
        fail(
            "Processed resource {} not found in processed_origins: {}",
            short_path,
            processed_origins,
        )

    owner = file.owner
    for short_path in origin_short_paths:
        _handle_processed_resource_origin(
            bundle = bundle,
            short_path = short_path,
            focused_resource_short_paths = focused_resource_short_paths,
            owner = owner,
        )

def _handle_processed_resource_origin(
        *,
        bundle,
        short_path,
        focused_resource_short_paths,
        owner):
    if short_path not in focused_resource_short_paths:
        return

    if short_path.startswith("../"):
        file_path = "external" + short_path[2:]
    else:
        file_path = short_path

    is_generated = file_path.startswith("bazel-out/")

    # If a file is a child of a folder-type file, the parent folder-type file
    # should be added to the bundle instead of the child file
    folder_type_prefix = _path_folder_type_prefix(file_path)
    if is_generated:
        bundle.generated_resource_file_paths.append(
            struct(
                owner = owner,
                path = folder_type_prefix or file_path,
            ),
        )
    else:
        bundle.resource_file_paths.append(folder_type_prefix or file_path)

def _handle_unprocessed_resource(
        *,
        bundle,
        bundle_metadata,
        bundle_path,
        file,
        focused_resource_short_paths,
        xccurrentversions):
    if (file.basename == ".xccurrentversion" and
        file.dirname.endswith(".xcdatamodeld")):
        xccurrentversions.append(file)
        return None

    if not file.is_source:
        if bundle_path and file.basename == "Info.plist":
            path_components = file.path.split("/")
            label = file.owner
            configuration = calculate_configuration(bin_dir_path = file.path)
            bundle_metadata[bundle_path] = struct(
                label = label,
                configuration = configuration,
                id = get_id(label = label, configuration = configuration),
                package_bin_dir = "/".join(path_components[:-3]),
            )
            return None

    if file.short_path not in focused_resource_short_paths:
        return None

    # If a file is a child of a folder-type file, the parent folder-type file
    # should be added to the bundle instead of the child file
    folder_type_prefix = _folder_type_prefix(file)
    if folder_type_prefix:
        if file.is_source:
            bundle.resource_file_paths.append(folder_type_prefix)
        else:
            bundle.generated_resource_file_paths.append(
                struct(
                    owner = file.owner,
                    path = folder_type_prefix,
                ),
            )
        return None

    return file

def _add_processed_resources_to_bundle(
        *,
        bundle,
        bundle_metadata,
        bundle_path,
        files,
        focused_resource_short_paths,
        processed_origins):
    for file in files.to_list():
        _handle_processed_resource(
            bundle = bundle,
            bundle_metadata = bundle_metadata,
            bundle_path = bundle_path,
            file = file,
            focused_resource_short_paths = focused_resource_short_paths,
            processed_origins = processed_origins,
        )

def _add_unprocessed_resources_to_bundle(
        *,
        bundle,
        bundle_metadata,
        bundle_path,
        files,
        focused_resource_short_paths,
        xccurrentversions):
    for file in files.to_list():
        file = _handle_unprocessed_resource(
            bundle = bundle,
            bundle_metadata = bundle_metadata,
            bundle_path = bundle_path,
            file = file,
            focused_resource_short_paths = focused_resource_short_paths,
            xccurrentversions = xccurrentversions,
        )
        if file:
            bundle.resources.append(file)

def _add_structured_resources_to_bundle(
        bundle,
        *,
        files,
        focused_resource_short_paths):
    for file in files.to_list():
        if file.short_path not in focused_resource_short_paths:
            continue

        bundle.resources.append(file)

def _add_structured_resources(
        *,
        bundle_path,
        files,
        focused_resource_short_paths,
        resource_bundle_targets,
        root_bundle):
    bundle = resource_bundle_targets.get(bundle_path)

    if bundle:
        if (not bundle.resources and
            not bundle.resource_file_paths and
            not bundle.generated_resource_file_paths and
            len(bundle_path.split(".bundle")) > 2):
            # This covers a deficiency in rules_apple's `_deduplicate` for
            # nested bundles that should be excluded
            return
        _add_structured_resources_to_bundle(
            bundle,
            files = files,
            focused_resource_short_paths = focused_resource_short_paths,
        )
    else:
        _add_structured_resources_to_bundle(
            root_bundle,
            files = files,
            focused_resource_short_paths = focused_resource_short_paths,
        )

def _handle_processable_resources(
        *,
        bundle_metadata,
        focused_resource_short_paths,
        resources,
        resource_bundle_targets,
        root_bundle,
        xccurrentversions):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_unprocessed_resources_to_bundle(
                bundle = root_bundle,
                bundle_metadata = bundle_metadata,
                bundle_path = None,
                files = files,
                focused_resource_short_paths = focused_resource_short_paths,
                xccurrentversions = xccurrentversions,
            )
            continue

        prefix, ext, _ = parent_dir.rpartition(".bundle")
        if not ext:
            _add_unprocessed_resources_to_bundle(
                bundle = root_bundle,
                bundle_metadata = bundle_metadata,
                bundle_path = None,
                files = files,
                focused_resource_short_paths = focused_resource_short_paths,
                xccurrentversions = xccurrentversions,
            )
            continue

        bundle_path = prefix + ext
        bundle = resource_bundle_targets[bundle_path]
        _add_unprocessed_resources_to_bundle(
            bundle = bundle,
            bundle_metadata = bundle_metadata,
            bundle_path = bundle_path,
            files = files,
            focused_resource_short_paths = focused_resource_short_paths,
            xccurrentversions = xccurrentversions,
        )

def _handle_processed_resources(
        *,
        bundle_metadata,
        focused_resource_short_paths,
        resources,
        resource_bundle_targets,
        root_bundle,
        processed_origins):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_processed_resources_to_bundle(
                bundle = root_bundle,
                bundle_metadata = bundle_metadata,
                bundle_path = None,
                files = files,
                focused_resource_short_paths = focused_resource_short_paths,
                processed_origins = processed_origins,
            )
            continue

        prefix, ext, _ = parent_dir.rpartition(".bundle")
        if not ext:
            _add_processed_resources_to_bundle(
                bundle = root_bundle,
                bundle_metadata = bundle_metadata,
                bundle_path = None,
                files = files,
                focused_resource_short_paths = focused_resource_short_paths,
                processed_origins = processed_origins,
            )
            continue

        bundle_path = prefix + ext
        bundle = resource_bundle_targets[bundle_path]
        _add_processed_resources_to_bundle(
            bundle = bundle,
            bundle_metadata = bundle_metadata,
            bundle_path = bundle_path,
            files = files,
            focused_resource_short_paths = focused_resource_short_paths,
            processed_origins = processed_origins,
        )

def _handle_unprocessed_resources(
        *,
        bundle_metadata,
        focused_resource_short_paths,
        parent_bundle_paths,
        resource_bundle_targets,
        resources,
        root_bundle,
        xccurrentversions):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_unprocessed_resources_to_bundle(
                bundle = root_bundle,
                bundle_metadata = bundle_metadata,
                bundle_path = None,
                files = files,
                focused_resource_short_paths = focused_resource_short_paths,
                xccurrentversions = xccurrentversions,
            )
            continue

        bundle_path = None
        for parent_bundle_path in parent_bundle_paths:
            if parent_dir.startswith(parent_bundle_path):
                bundle_path = parent_bundle_path
                break

        _add_structured_resources(
            bundle_path = bundle_path,
            files = files,
            focused_resource_short_paths = focused_resource_short_paths,
            resource_bundle_targets = resource_bundle_targets,
            root_bundle = root_bundle,
        )

# API

def _collect_resources(
        *,
        avoid_resource_infos,
        focused_labels,
        label_str,
        platform,
        resource_info):
    """Collects resource information for a target.

    Args:
        avoid_resource_infos: A `list` of `AppleResourceInfo` providers from
            targets that should be avoided (e.g. test hosts).
        focused_labels: A `depset` of label strings of focused targets. This
            will include the current target (if focused) and any focused
            dependencies of the current target.
        label_str: The label string for the target.
        platform: A value returned from `platforms.collect`.
        resource_info: The `AppleResourceInfo` provider for the target.

    Returns:
        A `struct` with the following fields:

        *   `bundles`: A `list` of `struct`s that are to be passed to
            `process_resource_bundles`.
        *   `resources`:  A `list` of two element `tuple`s. The first
            element is the label of the target that owns the resource. The
            second element is a `File` for a resource.
        *   `resource_file_paths`:  A `list` of two element `tuple`s. The first
            element is the label of the target that owns the resource. The
            second element is a file path string of a non-generated resource.
        *   `generated_resource_file_paths`:   A `list` of two element `tuple`s.
            The first element is the label of the target that owns the resource.
            The second element is a file path string of a generated resource.
        *   `xccurrentversions`: A `list` of `.xccurrentversion` `File`s.
    """
    root_bundle = _create_bundle()
    resource_bundle_targets = {}
    xccurrentversions = []
    bundle_metadata = {}

    focused_labels = {ls: None for ls in focused_labels.to_list()}
    focused_resource_short_paths = {
        f: None
        for f, owner in resource_info.owners.to_list()
        if (owner or label_str) in focused_labels
    }

    processed_fields = _processed_resource_fields(resource_info)
    if resource_info.processed_origins:
        processed_origins = _expand_processed_origins(
            processed_origins = resource_info.processed_origins,
        )
    else:
        processed_origins = {}

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
        if field == "processed":
            _handle_processed_resources(
                bundle_metadata = bundle_metadata,
                focused_resource_short_paths = focused_resource_short_paths,
                processed_origins = processed_origins,
                resource_bundle_targets = resource_bundle_targets,
                resources = deduplicated,
                root_bundle = root_bundle,
            )
        elif field == "unprocessed":
            _handle_unprocessed_resources(
                bundle_metadata = bundle_metadata,
                focused_resource_short_paths = focused_resource_short_paths,
                parent_bundle_paths = parent_bundle_paths,
                resource_bundle_targets = resource_bundle_targets,
                resources = deduplicated,
                root_bundle = root_bundle,
                xccurrentversions = xccurrentversions,
            )
        else:
            _handle_processable_resources(
                bundle_metadata = bundle_metadata,
                focused_resource_short_paths = focused_resource_short_paths,
                resources = deduplicated,
                resource_bundle_targets = resource_bundle_targets,
                root_bundle = root_bundle,
                xccurrentversions = xccurrentversions,
            )

    resources_common.deduplicate(
        resources_provider = resource_info,
        avoid_providers = avoid_resource_infos,
        field_handler = _deduplicated_field_handler,
    )

    for child_bundle_path in parent_bundle_paths:
        bundle = resource_bundle_targets[child_bundle_path]
        if (not bundle.resources and
            not bundle.resource_file_paths and
            not bundle.generated_resource_file_paths and
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
            frozen_bundles.append(
                struct(
                    name = bundle.name,
                    label = metadata.label,
                    configuration = metadata.configuration,
                    id = metadata.id,
                    package_bin_dir = metadata.package_bin_dir,
                    platform = platform,
                    resources = memory_efficient_depset(bundle.resources),
                    resource_file_paths = memory_efficient_depset(
                        bundle.resource_file_paths,
                    ),
                    generated_resource_file_paths = memory_efficient_depset(
                        bundle.generated_resource_file_paths,
                    ),
                ),
            )

    return struct(
        bundles = frozen_bundles,
        resources = root_bundle.resources,
        resource_file_paths = root_bundle.resource_file_paths,
        generated_resource_file_paths = root_bundle.generated_resource_file_paths,
        xccurrentversions = xccurrentversions,
    )

def _expand_processed_origins(*, processed_origins):
    """Converts a depset of (processed_resource, resource) to a dict.

    Args:
      processed_origins: A depset of (processed_resource, resource) pairs.
    """
    processed_origins_dict = {}
    for processed_resource, resource in processed_origins.to_list():
        processed_origins_dict[processed_resource] = resource
    return processed_origins_dict

def _folder_type_prefix(file):
    return _path_folder_type_prefix(file.path)

def _path_folder_type_prefix(path):
    for suffix in _FOLDER_TYPE_FILE_SUFFIXES:
        idx = path.find(suffix)
        if idx != -1:
            return path[:(idx + len(suffix) - 1)]
    return None

resources = struct(
    collect = _collect_resources,
    folder_type_prefix = _folder_type_prefix,
)

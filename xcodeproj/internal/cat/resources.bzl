""" Functions for collecting resource usage information."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_apple//apple:resources.bzl", "resources_common")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "memory_efficient_depset",
)
load("//xcodeproj/internal:target_id.bzl", "get_id")
load(":files.bzl", "join_paths_ignoring_empty")

# Utility

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
    if (file.basename == ".xccurrentversion" and
        file.dirname.endswith(".xcdatamodeld")):
        xccurrentversions.append(file)
        return None

    if not file.is_source:
        generated.append(file)
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

    return file

def _add_resources_to_bundle(
        *,
        bundle,
        bundle_path,
        files,
        bundle_metadata,
        generated,
        xccurrentversions):
    for file in files.to_list():
        file = _process_resource(
            bundle_path = bundle_path,
            file = file,
            bundle_metadata = bundle_metadata,
            generated = generated,
            xccurrentversions = xccurrentversions,
        )
        if file:
            bundle.resources.append(file)

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
        generated):
    if nested_path:
        inner_dir = nested_path.split("/")[0]
    else:
        inner_dir = None

    for file in files.to_list():
        if not file.is_source:
            generated.append(file)

        if not inner_dir:
            bundle.resources.append(file)
            continue

        # Special case for localized
        if inner_dir.endswith(".lproj"):
            bundle.resources.append(file)
            continue

        if file.is_directory:
            dir = file.path
        else:
            dir = file.dirname

        if not dir.endswith(nested_path):
            continue

        bundle.folder_resources.append(
            paths.join(dir[:-(1 + len(nested_path))], inner_dir),
        )

def _add_structured_resources(
        *,
        root_bundle,
        resource_bundle_targets,
        bundle_path,
        nested_path,
        files,
        generated):
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
        )
    else:
        _add_structured_resources_to_bundle(
            root_bundle,
            nested_path = join_paths_ignoring_empty(bundle_path, nested_path),
            files = files,
            generated = generated,
        )

def _add_processed_resources(
        *,
        resources,
        root_bundle,
        resource_bundle_targets,
        bundle_metadata,
        generated,
        xccurrentversions):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_resources_to_bundle(
                bundle = root_bundle,
                bundle_path = None,
                files = files,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
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
        )

def _add_unprocessed_resources(
        *,
        resources,
        root_bundle,
        resource_bundle_targets,
        parent_bundle_paths,
        bundle_metadata,
        generated,
        xccurrentversions):
    for parent_dir, _, files in resources:
        if not parent_dir:
            _add_resources_to_bundle(
                bundle = root_bundle,
                bundle_path = None,
                files = files,
                bundle_metadata = bundle_metadata,
                generated = generated,
                xccurrentversions = xccurrentversions,
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
        )

# API

def collect_resources(
        *,
        build_mode,
        platform,
        resource_info,
        avoid_resource_infos):
    """Collects resource information for a target.

    Args:
        build_mode: See `xcodeproj.build_mode`.
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
        *   `resources`: A `list` of `file_path`s of resources that should be
            added to the target's bundle.
        *   `generated`: A `list` of `file_path`s of generated resources.
        *   `xccurrentversions`: A `list` of `.xccurrentversion` `File`s.
    """
    root_bundle = _create_bundle()
    resource_bundle_targets = {}
    generated = []
    xccurrentversions = []
    bundle_metadata = {}

    processed_fields = _processed_resource_fields(resource_info)

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
            )
        else:
            _add_processed_resources(
                resources = deduplicated,
                root_bundle = root_bundle,
                resource_bundle_targets = resource_bundle_targets,
                bundle_metadata = bundle_metadata,
                generated = generated,
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

    include_dependencies = build_mode != "bazel"

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
                    folder_resources = memory_efficient_depset(
                        bundle.folder_resources,
                    ),
                    dependencies = memory_efficient_depset([
                        bundle_metadata[bundle_path].id
                        for bundle_path in bundle.dependency_paths
                    ]) if include_dependencies else EMPTY_DEPSET,
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
        ] if include_dependencies else None,
        resources = root_bundle.resources,
        folder_resources = root_bundle.folder_resources,
        generated = generated,
        xccurrentversions = xccurrentversions,
    )

"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:shell.bzl", "shell")
load(":bazel_labels.bzl", "bazel_labels")
load(":collections.bzl", "set_if_true", "uniq")
load(":configuration.bzl", "get_configuration")
load(
    ":files.bzl",
    "build_setting_path",
    "file_path",
    "file_path_to_dto",
    "parsed_file_path",
    "raw_file_path",
)
load(":flattened_key_values.bzl", "flattened_key_values")
load(":input_files.bzl", "input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":logging.bzl", "warn")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(":project_options.bzl", "project_options_to_dto")
load(":providers.bzl", "XcodeProjInfo")
load(":resource_target.bzl", "process_resource_bundles")
load(":xcode_targets.bzl", "xcode_targets")
load(":xcodeproj_aspect.bzl", "make_xcodeproj_aspect")

# Utility

_SWIFTUI_PREVIEW_PRODUCT_TYPES = [
    "com.apple.product-type.application",
    "com.apple.product-type.app-extension",
    "com.apple.product-type.bundle",
    "com.apple.product-type.framework",
    "com.apple.product-type.tool",
]

# TODO: Non-test_host applications should be terminal as well
_TERMINAL_PRODUCT_TYPES = {
    "com.apple.product-type.bundle.unit-test": None,
    "com.apple.product-type.bundle.ui-testing": None,
}

# Error Message Strings

_INVALID_EXTRA_FILES_TARGETS_BASE_MESSAGE = """\
Are you using an `alias`? `associated_extra_files` requires labels of the \
actual targets: {}
"""

_INVALID_EXTRA_FILES_TARGETS_HINT = """\
You can turn this error into a warning with `fail_for_invalid_extra_files_targets`
"""

def _calculate_unfocused_dependencies(
        *,
        build_mode,
        targets,
        focused_targets,
        unfocused_libraries,
        unfocused_targets):
    if build_mode != "xcode":
        return {}

    automatic_unfocused_dependencies = []
    transitive_focused_dependencies = []
    if unfocused_targets or unfocused_libraries:
        for xcode_target in focused_targets:
            transitive_focused_dependencies.append(
                xcode_target.transitive_dependencies,
            )
            if xcode_target.product.file_path in unfocused_libraries:
                automatic_unfocused_dependencies.append(xcode_target.id)

    transitive_dependencies = []
    if unfocused_targets:
        focused_dependencies = {
            d: None
            for d in depset(
                transitive = transitive_focused_dependencies,
            ).to_list()
        }
        for xcode_target in unfocused_targets.values():
            automatic_unfocused_dependencies.append(xcode_target.id)
            if xcode_target.id in focused_dependencies:
                transitive_dependencies.append(
                    xcode_target.transitive_dependencies,
                )

    return {
        id: targets[id]
        for id in depset(
            automatic_unfocused_dependencies,
            transitive = transitive_dependencies,
        ).to_list()
    }

def _calculate_swiftui_preview_targets(
        *,
        xcode_target,
        transitive_dependencies,
        targets):
    return [
        id
        for id in transitive_dependencies
        if _is_same_platform_swiftui_preview_target(
            platform = xcode_target.platform,
            xcode_target = targets.get(id),
        )
    ]

def _get_minimum_xcode_version(*, ctx):
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    version = str(xcode_config.xcode_version())
    if not version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")
    return ".".join(version.split(".")[0:3])

def _is_same_platform_swiftui_preview_target(*, platform, xcode_target):
    if not xcode_target:
        return False
    if not platform_info.is_same_type(platform, xcode_target.platform):
        return False
    return xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES

def _process_dep(dep):
    info = dep[XcodeProjInfo]

    if not info.is_top_level_target:
        fail("""
'{label}' is not a top-level target, but was listed in `top_level_targets`. \
Only list top-level targets (e.g. binaries, apps, tests, or distributable \
frameworks) in `top_level_targets`. Schemes and \
`focused_targets`/`unfocused_targets` can refer to dependencies of targets \
listed in `top_level_targets`, and don't need to be listed in \
`top_level_targets` themselves.

If you feel this is an error, and `{kind}` targets should be recognized as \
top-level targets, file a bug report here: \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
""".format(label = dep.label, kind = info.rule_kind))

    return info

def _process_extra_files(
        *,
        ctx,
        configurations_map,
        focused_labels,
        is_fixture,
        unfocused_labels,
        replacement_labels_by_label,
        inputs,
        focused_targets_extra_files,
        focused_targets_extra_folders):
    extra_files = inputs.extra_files.to_list()

    # Add processed owned extra files
    extra_files.extend(focused_targets_extra_files)

    # Apply replacement labels
    extra_files = [
        (
            bazel_labels.normalize_label(
                replacement_labels_by_label.get(label, label),
            ),
            files,
        )
        for label, files in extra_files
    ]
    extra_folders = [
        (
            bazel_labels.normalize_label(
                replacement_labels_by_label.get(label, label),
            ),
            files,
        )
        for label, files in focused_targets_extra_folders
    ]

    # Filter out unfocused labels
    has_focused_labels = bool(focused_labels)
    extra_files = [
        file
        for label, files in extra_files
        for file in files
        if not label or not (
            label in unfocused_labels or
            (has_focused_labels and label not in focused_labels)
        )
    ]
    extra_folders = [
        file
        for label, files in extra_folders
        for file in files
        if not label or not (
            label in unfocused_labels or
            (has_focused_labels and label not in focused_labels)
        )
    ]

    # Add unowned extra files
    extra_files.append(parsed_file_path(ctx.attr.runner_build_file))
    for target in ctx.attr.unowned_extra_files:
        extra_files.extend([
            file_path(file)
            for file in target.files.to_list()
        ])

    extra_files = uniq(extra_files)
    extra_folders = uniq(extra_folders)

    def _normalize_path(path):
        configuration, _, suffix = path.partition("/")
        if not suffix:
            return path
        return (
            configurations_map.get(configuration, configuration) + "/" + suffix
        )

    if is_fixture:
        extra_files = [
            raw_file_path(
                type = fp.type,
                path = _normalize_path(fp.path),
            )
            for fp in extra_files
        ]
        extra_folders = [
            raw_file_path(
                type = fp.type,
                path = _normalize_path(fp.path),
            )
            for fp in extra_folders
        ]
        extra_files = sorted(extra_files, key = lambda fp: fp.type + fp.path)
        extra_folders = sorted(
            extra_folders,
            key = lambda fp: fp.type + fp.path,
        )

    return extra_files, extra_folders

def _process_xccurrentversions(
        *,
        focused_labels,
        unfocused_labels,
        replacement_labels_by_label,
        inputs):
    xccurrentversions_files = inputs.xccurrentversions.to_list()

    # Apply replacement labels
    xccurrentversions_files = [
        (
            bazel_labels.normalize_label(
                replacement_labels_by_label.get(label, label),
            ),
            files,
        )
        for label, files in xccurrentversions_files
    ]

    # Filter out unfocused labels
    has_focused_labels = bool(focused_labels)
    xccurrentversions_files = [
        file
        for label, files in xccurrentversions_files
        for file in files
        if not label or not (
            label in unfocused_labels or
            (has_focused_labels and label not in focused_labels)
        )
    ]

    xccurrentversions_files = uniq(xccurrentversions_files)

    return xccurrentversions_files

def _process_targets(
        *,
        ctx,
        build_mode,
        is_fixture,
        configuration,
        focused_labels,
        unfocused_labels,
        replacement_labels,
        inputs,
        infos,
        infos_per_xcode_configuration,
        owned_extra_files,
        include_swiftui_previews_scheme_targets,
        fail_for_invalid_extra_files_targets):
    resource_bundle_xcode_targets = []
    unprocessed_targets = {}
    xcode_configurations = {}
    for xcode_configuration, i in infos_per_xcode_configuration.items():
        configuration_inputs = input_files.merge(
            transitive_infos = [(None, info) for info in i],
        )
        configuration_resource_bundle_xcode_targets = process_resource_bundles(
            bundles = configuration_inputs.resource_bundles.to_list(),
            resource_bundle_informations = depset(
                transitive = [
                    info.resource_bundle_informations
                    for info in i
                ],
            ).to_list(),
        )
        resource_bundle_xcode_targets.extend(
            configuration_resource_bundle_xcode_targets,
        )

        configuration_unprocessed_targets = {
            xcode_target.id: xcode_target
            for xcode_target in depset(
                configuration_resource_bundle_xcode_targets,
                transitive = [info.xcode_targets for info in i],
            ).to_list()
        }
        unprocessed_targets.update(configuration_unprocessed_targets)

        for id in configuration_unprocessed_targets:
            xcode_configurations.setdefault(id, []).append(xcode_configuration)

    configurations_map = {}
    if is_fixture:
        prefix, sep, _ = configuration.partition("-ST-")
        if sep:
            configurations_map[configuration] = "{}-STABLE-0".format(prefix)

        label_configurations = {}
        for xcode_target in unprocessed_targets.values():
            # Make it stable over labels
            label_configurations.setdefault(
                xcode_target.label,
                {},
            )[xcode_target.configuration] = xcode_target

        configurations = {}
        for label_configs in label_configurations.values():
            for configuration in label_configs:
                configurations[configuration] = None

        for idx, configuration in enumerate(configurations):
            prefix, sep, _ = configuration.partition("-ST-")
            if sep:
                configurations_map[configuration] = "{}-STABLE-{}".format(
                    prefix,
                    idx + 1,
                )

    replacement_labels_by_label = {
        unprocessed_targets[id].label: label
        for id, label in replacement_labels.items()
    }

    xcode_target_labels = {
        t.id: replacement_labels.get(t.id, t.label)
        for t in unprocessed_targets.values()
    }
    xcode_target_label_strs = {
        id: bazel_labels.normalize_label(label)
        for id, label in xcode_target_labels.items()
    }

    # Can't use `xcode_target_label_strs`, as those are only for bazel targets
    # that create Xcode targets
    label_strs = {
        bazel_labels.normalize_label(
            replacement_labels_by_label.get(label, label),
        ): None
        for label in depset(
            transitive = [info.labels for info in infos],
        ).to_list()
    }

    invalid_focused_targets = [
        label
        for label in focused_labels
        if label not in label_strs
    ]
    if invalid_focused_targets:
        fail("""\
`focused_targets` contains target(s) that are not transitive dependencies of \
the targets listed in `top_level_targets`: {}

Are you using an `alias`? `focused_targets` requires labels of the actual \
targets.
""".format(invalid_focused_targets))

    owned_extra_files = {
        key: bazel_labels.normalize_label(Label(label_str))
        for key, label_str in owned_extra_files.items()
    }

    invalid_extra_files_targets = [
        label
        for label in owned_extra_files.values()
        if label not in label_strs
    ]
    if invalid_extra_files_targets:
        message = _INVALID_EXTRA_FILES_TARGETS_BASE_MESSAGE.format(invalid_extra_files_targets)
        if fail_for_invalid_extra_files_targets:
            fail(message + _INVALID_EXTRA_FILES_TARGETS_HINT)
        else:
            warn(message)

    unfocused_libraries = {
        library: None
        for library in inputs.unfocused_libraries.to_list()
    }
    has_focused_labels = bool(focused_labels)

    if build_mode == "xcode":
        transitive_focused_targets = [depset(resource_bundle_xcode_targets)]
    else:
        transitive_focused_targets = []

    exclude_resource_bundles = build_mode != "xcode"

    files_only_targets = {}
    focused_targets_extra_files = []
    focused_targets_extra_folders = []
    linker_products_map = {}
    unfocused_targets = {}
    for xcode_target in unprocessed_targets.values():
        if build_mode == "bazel":
            product = xcode_target.product
            for file in product.framework_files.to_list():
                linker_products_map[build_setting_path(
                    file = file,
                    path = file.dirname,
                )] = build_setting_path(file = product.file)

        label_str = xcode_target_label_strs[xcode_target.id]
        if (label_str in unfocused_labels or
            (has_focused_labels and label_str not in focused_labels)):
            unfocused_targets[xcode_target.id] = xcode_target
            continue

        if not xcode_target.should_create_xcode_target:
            continue

        if xcode_target.product.is_resource_bundle and exclude_resource_bundles:
            # Don't create targets for resource bundles in BwB mode, but still
            # include their files if they aren't unfocused
            focused_targets_extra_files.append(
                (xcode_target.label, xcode_target.inputs.resources.to_list()),
            )
            focused_targets_extra_folders.append(
                (
                    xcode_target.label,
                    xcode_target.inputs.folder_resources.to_list(),
                ),
            )
            files_only_targets[xcode_target.id] = xcode_target
            continue

        transitive_focused_targets.append(
            depset(
                [xcode_target],
                transitive = [
                    xcode_target.xcode_required_targets,
                ] if build_mode == "xcode" else [],
            ),
        )

    focused_targets = {
        xcode_target.id: xcode_target
        for xcode_target in depset(
            transitive = transitive_focused_targets,
        ).to_list()
    }

    infoplists = {}
    for xcode_target in focused_targets.values():
        label = xcode_target_labels[xcode_target.id]
        label_str = xcode_target_label_strs[xcode_target.id]

        # Remove from unfocused (to support `xcode_required_targets`)
        unfocused_targets.pop(xcode_target.id, None)

        # Adjust `{un.}focused_labels` for `extra_files` logic later
        unfocused_labels.pop(label_str, None)
        if has_focused_labels:
            # Add in `xcode_required_targets`
            focused_labels[label_str] = None

        infoplist = xcode_target.outputs.transitive_infoplists
        if infoplist:
            infoplists.setdefault(label, []).append(infoplist)

    potential_target_merges = depset(
        transitive = [info.potential_target_merges for info in infos],
    ).to_list()

    raw_target_merge_dests = {}
    for merge in potential_target_merges:
        src_target = unprocessed_targets[merge.src.id]
        src_label = bazel_labels.normalize_label(src_target.label)
        dest_target = unprocessed_targets[merge.dest]
        dest_label = bazel_labels.normalize_label(dest_target.label)
        if src_label in unfocused_labels or dest_label in unfocused_labels:
            continue

        # Exclude targets not in focused nor unfocused targets from
        # potential merges since they're not possible Xcode targets.
        merge_src_is_xcode_target = (
            merge.src.id in focused_targets or
            merge.src.id in unfocused_targets
        )
        if not merge_src_is_xcode_target:
            continue
        raw_target_merge_dests.setdefault(merge.dest, []).append(merge.src.id)

    target_merge_dests = {}
    for dest, src_ids in raw_target_merge_dests.items():
        if len(src_ids) > 1:
            # We can only merge targets with a single library dependency
            continue
        dest_label_str = xcode_target_label_strs[dest]

        for src in src_ids:
            target_merge_dests.setdefault(dest, []).append(src)

            if dest_label_str not in focused_labels:
                continue

            src_target = unprocessed_targets[src]
            src_label_str = xcode_target_label_strs[src]

            # Always include src of target merge if dest is included
            focused_targets[src] = src_target

            # Remove from unfocused (to support `xcode_required_targets`)
            unfocused_targets.pop(src, None)

            # Adjust `{un,}focused_labels` for `extra_files` logic later
            unfocused_labels.pop(src_label_str, None)
            if has_focused_labels and dest in focused_labels:
                focused_labels[src_label_str] = None

    unfocused_dependencies = _calculate_unfocused_dependencies(
        build_mode = build_mode,
        targets = unprocessed_targets,
        focused_targets = focused_targets.values(),
        unfocused_libraries = unfocused_libraries,
        unfocused_targets = unfocused_targets,
    )

    has_automatic_unfocused_targets = bool(unfocused_libraries)
    has_unfocused_targets = bool(unfocused_targets)
    include_lldb_context = (
        has_unfocused_targets or
        has_automatic_unfocused_targets or
        build_mode != "xcode"
    )

    for xcode_target in focused_targets.values():
        label = xcode_target_labels[xcode_target.id]
        label_str = xcode_target_label_strs[xcode_target.id]

        for file, owner_label in owned_extra_files.items():
            if label_str == owner_label:
                focused_targets_extra_files.append(
                    (
                        label,
                        [file_path(f) for f in file.files.to_list()],
                    ),
                )

    # Filter `target_merge_dests` after processing focused targets
    for dest, srcs in target_merge_dests.items():
        if dest not in focused_targets:
            target_merge_dests.pop(dest)
            continue

        for src in srcs:
            if src not in focused_targets:
                target_merge_dests.pop(dest)
                break

    target_merges = {}
    target_merge_srcs_by_label = {}
    for dest, srcs in target_merge_dests.items():
        for src in srcs:
            src_target = focused_targets[src]
            target_merges.setdefault(src, []).append(dest)
            target_merge_srcs_by_label.setdefault(src_target.label, []).append(src)

    non_mergable_targets = {}
    non_terminal_dests = {}
    for src, dests in target_merges.items():
        src_target = focused_targets[src]

        for dest in dests:
            dest_target = focused_targets[dest]

            if dest_target.product.type not in _TERMINAL_PRODUCT_TYPES:
                non_terminal_dests.setdefault(src, []).append(dest)

            for library in xcode_targets.get_top_level_static_libraries(
                dest_target,
            ):
                if library.owner == src_target.label:
                    continue

                # Other libraries that are not being merged into `dest_target`
                # can't merge into other targets
                non_mergable_targets[file_path(library)] = None

    for src in target_merges.keys():
        src_target = focused_targets[src]
        if (len(non_terminal_dests.get(src, [])) > 1 or
            src_target.product.file_path in non_mergable_targets):
            # Prevent any version of `src` from merging, to prevent odd
            # target consolidation issues
            for id in target_merge_srcs_by_label[src_target.label]:
                target_merges.pop(id, None)

    for src, dests in target_merges.items():
        src_target = focused_targets.pop(src)

        for dest in dests:
            focused_targets[dest] = xcode_targets.merge(
                src = src_target,
                dest = focused_targets[dest],
            )

    (
        xcode_generated_paths,
        xcode_generated_paths_file,
    ) = _process_xcode_generated_paths(
        ctx = ctx,
        build_mode = build_mode,
        focused_targets = focused_targets,
        unfocused_dependencies = unfocused_dependencies,
    )

    excluded_targets = dicts.add(unfocused_targets, files_only_targets)

    lldb_contexts_dtos = {
        xcode_configuration: {}
        for xcode_configuration in infos_per_xcode_configuration.keys()
    }

    target_dtos = {}
    target_dependencies = {}
    target_link_params = {}

    for index, xcode_target in enumerate(focused_targets.values()):
        transitive_dependencies = {
            id: None
            for id in xcode_target.transitive_dependencies.to_list()
        }

        if include_swiftui_previews_scheme_targets:
            additional_scheme_target_ids = _calculate_swiftui_preview_targets(
                xcode_target = xcode_target,
                transitive_dependencies = transitive_dependencies,
                targets = focused_targets,
            )
        else:
            additional_scheme_target_ids = None

        target_xcode_configurations = xcode_configurations[xcode_target.id]

        if include_lldb_context and xcode_target.lldb_context_key:
            for xcode_configuration in target_xcode_configurations:
                set_if_true(
                    lldb_contexts_dtos[xcode_configuration],
                    xcode_target.lldb_context_key,
                    lldb_contexts.to_dto(
                        xcode_target.lldb_context,
                        xcode_generated_paths = xcode_generated_paths,
                    ),
                )

        dto, replaced_dependencies, link_params = xcode_targets.to_dto(
            ctx = ctx,
            xcode_target = xcode_target,
            label = xcode_target_labels[xcode_target.id],
            is_fixture = is_fixture,
            additional_scheme_target_ids = additional_scheme_target_ids,
            build_mode = build_mode,
            xcode_configurations = target_xcode_configurations,
            link_params_processor = ctx.executable._link_params_processor,
            linker_products_map = linker_products_map,
            params_index = index,
            should_include_outputs = should_include_outputs(build_mode),
            excluded_targets = excluded_targets,
            target_merges = target_merges,
            unfocused_dependencies = unfocused_dependencies,
            xcode_generated_paths = xcode_generated_paths,
            xcode_generated_paths_file = xcode_generated_paths_file,
        )
        target_dtos[xcode_target.id] = dto
        target_dependencies[xcode_target.id] = (
            transitive_dependencies,
            replaced_dependencies,
        )
        if link_params:
            target_link_params[xcode_target.id] = depset([link_params])

    additional_generated = {}
    additional_outputs = {}
    for xcode_target in focused_targets.values():
        (
            transitive_dependencies,
            replaced_dependencies,
        ) = target_dependencies[xcode_target.id]

        transitive_link_params = []

        link_params = target_link_params.get(xcode_target.id)
        if link_params:
            transitive_link_params.append(link_params)

        for id in transitive_dependencies:
            merge = target_merges.get(id)
            if merge:
                id = merge[0]
                if id == xcode_target.id:
                    continue
            link_params = target_link_params.get(id)
            if link_params:
                transitive_link_params.append(link_params)

        compiling_output_group_name = (
            xcode_target.inputs.compiling_output_group_name
        )
        indexstores_output_group_name = (
            xcode_target.inputs.indexstores_output_group_name
        )
        linking_output_group_name = (
            xcode_target.inputs.linking_output_group_name
        )
        bwb_linking_output_group_name = (
            xcode_target.outputs.linking_output_group_name
        )

        additional_compiling_files = []
        additional_indexstores_files = []
        additional_linking_files = []

        label = xcode_target_labels[xcode_target.id]
        target_infoplists = infoplists.get(label)
        if target_infoplists:
            additional_linking_files.extend(target_infoplists)
            products_output_group_name = (
                xcode_target.outputs.products_output_group_name
            )
            if products_output_group_name:
                additional_outputs[products_output_group_name] = (
                    target_infoplists
                )

        for dependency in transitive_dependencies:
            unfocused_dependency = unfocused_dependencies.get(dependency)
            if not unfocused_dependency:
                continue
            unfocused_compiling_files = (
                unfocused_dependency.inputs.unfocused_generated_compiling
            )
            unfocused_indexstores_files = (
                unfocused_dependency.inputs.unfocused_generated_indexstores
            )
            unfocused_linking_files = (
                unfocused_dependency.inputs.unfocused_generated_linking
            )
            if unfocused_compiling_files:
                additional_compiling_files.append(
                    depset(unfocused_compiling_files),
                )
            if unfocused_indexstores_files:
                additional_indexstores_files.append(
                    depset(unfocused_indexstores_files),
                )
            if unfocused_linking_files:
                additional_linking_files.append(
                    depset(unfocused_linking_files),
                )

        for id in replaced_dependencies:
            if id in transitive_dependencies:
                continue

            # The replaced dependency is not a transitive dependency, so we
            # need to add its merge in its output groups

            link_params = target_link_params.get(id, None)
            if link_params:
                transitive_link_params.append(link_params)

            dep_target = focused_targets[id]

            dep_compiling_output_group_name = (
                dep_target.inputs.compiling_output_group_name
            )
            dep_indexstores_output_group_name = (
                dep_target.inputs.indexstores_output_group_name
            )
            dep_linking_output_group_name = (
                dep_target.inputs.linking_output_group_name
            )

            if compiling_output_group_name and dep_compiling_output_group_name:
                additional_compiling_files = additional_generated.get(
                    dep_compiling_output_group_name,
                    [],
                )
                additional_compiling_files.append(dep_target.inputs.generated)
            if (indexstores_output_group_name and
                dep_indexstores_output_group_name):
                additional_indexstores_files = additional_generated.get(
                    dep_indexstores_output_group_name,
                    [],
                )
                additional_indexstores_files.append(
                    dep_target.inputs.indexstores,
                )
            if linking_output_group_name and dep_linking_output_group_name:
                additional_linking_files = additional_generated.get(
                    dep_linking_output_group_name,
                    [],
                )

        if transitive_link_params:
            if linking_output_group_name:
                additional_linking_files.extend(transitive_link_params)
            if bwb_linking_output_group_name:
                additional_outputs[bwb_linking_output_group_name] = (
                    transitive_link_params
                )

        if compiling_output_group_name:
            set_if_true(
                additional_generated,
                compiling_output_group_name,
                additional_compiling_files,
            )
        if indexstores_output_group_name:
            set_if_true(
                additional_generated,
                indexstores_output_group_name,
                additional_indexstores_files,
            )
        if linking_output_group_name:
            set_if_true(
                additional_generated,
                linking_output_group_name,
                additional_linking_files,
            )

    return (
        focused_targets,
        target_dtos,
        additional_generated,
        additional_outputs,
        focused_targets_extra_files,
        focused_targets_extra_folders,
        replacement_labels_by_label,
        configurations_map,
        lldb_contexts_dtos,
    )

def _process_xcode_generated_paths(
        *,
        ctx,
        build_mode,
        focused_targets,
        unfocused_dependencies):
    xcode_generated_paths = {}
    xcode_generated_paths_file = ctx.actions.declare_file(
        "{}-xcode_generated_paths.json".format(ctx.attr.name),
    )

    if build_mode != "xcode":
        ctx.actions.write(
            content = json.encode(xcode_generated_paths),
            output = xcode_generated_paths_file,
        )
        return xcode_generated_paths, xcode_generated_paths_file

    for xcode_target in focused_targets.values():
        if xcode_target.id in unfocused_dependencies:
            continue

        product = xcode_target.product
        product_file = product.file
        if not product_file:
            continue

        product_file_path = product_file.path
        xcode_product_path = build_setting_path(
            file = product_file,
            path = product_file_path,
            use_build_dir = True,
        )
        xcode_generated_paths[product_file_path] = (
            xcode_product_path
        )

        executable = product.executable
        if executable and product.type.startswith("com.apple.product-type.app"):
            # Possible test hosts (apps and app extensions)
            executable_name = product.executable_name
            xcode_generated_paths[product.executable.path] = paths.join(
                xcode_product_path,
                executable_name,
            )

        for file in product.additional_product_files:
            path = file.path
            xcode_generated_paths[path] = xcode_product_path

        for file in product.framework_files.to_list():
            xcode_generated_paths[file.dirname] = (
                xcode_product_path
            )

        swiftmodule = xcode_target.outputs.swiftmodule
        if swiftmodule:
            swiftmodule_basename = swiftmodule.basename
            if product.type == "com.apple.product-type.framework":
                path = (
                    product_file.path + "/Modules/" + swiftmodule_basename
                )
            else:
                path = product_file.dirname + "/" + swiftmodule_basename

            xcode_generated_paths[swiftmodule.path] = (
                build_setting_path(
                    file = swiftmodule,
                    path = path,
                    use_build_dir = True,
                )
            )

        generated_header = xcode_target.outputs.swift_generated_header
        if generated_header:
            product_components = product.file.path.split("/", 3)
            header_components = generated_header.path.split("/")
            final_components = (product_components[0:2] +
                                header_components[2:])
            path = "/".join(final_components)

            xcode_generated_paths[generated_header.path] = (
                build_setting_path(
                    file = generated_header,
                    path = path,
                    use_build_dir = True,
                )
            )

    ctx.actions.write(
        content = json.encode(xcode_generated_paths),
        output = xcode_generated_paths_file,
    )

    return xcode_generated_paths, xcode_generated_paths_file

def should_include_outputs(build_mode):
    return build_mode != "bazel_with_proxy"

# Actions

def _write_swift_debug_settings(*, ctx, settings):
    outputs = []
    for xcode_configuration, configuration_settings in settings.items():
        output = ctx.actions.declare_file(
            "{}_bazel_integration_files/{}-swift_debug_settings.py".format(
                ctx.attr.name,
                xcode_configuration,
            ),
        )
        outputs.append(output)

        ctx.actions.expand_template(
            template = ctx.file._swift_debug_settings_template,
            output = output,
            substitutions = {
                "%settings_map%": json.encode_indent(configuration_settings),
            },
        )

    return outputs

def _write_spec(
        *,
        args,
        config,
        ctx,
        is_fixture,
        xcode_configurations,
        default_xcode_configuration,
        envs,
        project_name,
        project_options,
        target_dtos,
        extra_files,
        extra_folders,
        infos,
        minimum_xcode_version,
        target_ids_list):
    # `target_hosts`
    hosted_targets = depset(
        transitive = [info.hosted_targets for info in infos],
    ).to_list()
    target_hosts = {}
    for s in hosted_targets:
        if s.host not in target_dtos or s.hosted not in target_dtos:
            continue
        target_hosts.setdefault(s.hosted, []).append(s.host)

    # TODO: Strip fat frameworks instead of setting `VALIDATE_WORKSPACE`

    spec_dto = {
        "B": config,
        "T": "fixture-target-ids-file" if is_fixture else build_setting_path(
            file = target_ids_list,
        ),
        "i": "fixture-index-import-path" if is_fixture else build_setting_path(
            file = ctx.executable._index_import,
        ),
        "m": minimum_xcode_version,
        "n": project_name,
        "R": ctx.attr.runner_label,
    }

    if xcode_configurations != ["Debug"]:
        spec_dto["x"] = xcode_configurations

    if default_xcode_configuration != "Debug":
        spec_dto["d"] = default_xcode_configuration

    project_options_dto = project_options_to_dto(project_options)
    if project_options_dto:
        spec_dto["o"] = project_options_dto

    if ctx.attr.scheme_autogeneration_mode != "all":
        spec_dto["s"] = ctx.attr.scheme_autogeneration_mode

    set_if_true(
        spec_dto,
        "a",
        flattened_key_values.to_list(args, sort = is_fixture),
    )
    set_if_true(
        spec_dto,
        "e",
        [file_path_to_dto(file) for file in extra_files],
    )
    set_if_true(
        spec_dto,
        "F",
        [file_path_to_dto(file) for file in extra_folders],
    )
    set_if_true(
        spec_dto,
        "E",
        flattened_key_values.to_list(envs, sort = is_fixture),
    )
    set_if_true(
        spec_dto,
        "P",
        ctx.attr.post_build,
    )
    set_if_true(
        spec_dto,
        "p",
        ctx.attr.pre_build,
    )
    set_if_true(
        spec_dto,
        "t",
        flattened_key_values.to_list(target_hosts, sort = is_fixture),
    )

    project_spec_json = json.encode(spec_dto)

    # 8 shards max (lowest number of threads on a Mac)
    max_shard_count = 1 if is_fixture else 8

    target_count = len(target_dtos)
    shard_count = min(target_count, max_shard_count)

    shard_size = target_count // shard_count
    if target_count % shard_count != 0:
        shard_size += 1

        # Adjust down shard_count so we don't have empty shards
        shard_count = target_count // shard_size
        if target_count % shard_size != 0:
            shard_count += 1

    shard_size = shard_size * 2  # Each entry has a key and a value

    flattened_targets = flattened_key_values.to_list(
        target_dtos,
        sort = is_fixture,
    )

    target_shards = []
    for shard in range(shard_count):
        sharded_targets = flattened_targets[shard * shard_size:(shard + 1) * shard_size]

        targets_json = json.encode(sharded_targets)
        targets_output = ctx.actions.declare_file(
            "{}-targets_spec.{}.json".format(ctx.attr.name, shard),
        )
        ctx.actions.write(targets_output, targets_json)

        target_shards.append(targets_output)

    project_spec_output = ctx.actions.declare_file(
        "{}-project_spec.json".format(ctx.attr.name),
    )
    ctx.actions.write(project_spec_output, project_spec_json)

    return [project_spec_output, ctx.file.schemes_json] + target_shards

def _write_xccurrentversions(*, ctx, xccurrentversion_files):
    containers_file = ctx.actions.declare_file(
        "{}_xccurrentversion_containers".format(ctx.attr.name),
    )
    ctx.actions.write(
        containers_file,
        "".join([
            json.encode(
                file_path_to_dto(file_path(file, path = file.dirname)),
            ) + "\n"
            for file in xccurrentversion_files
        ]),
    )

    files_list = ctx.actions.args()
    files_list.use_param_file("%s", use_always = True)
    files_list.set_param_file_format("multiline")
    files_list.add_all(xccurrentversion_files)

    output = ctx.actions.declare_file(
        "{}_xccurrentversions".format(ctx.attr.name),
    )
    ctx.actions.run(
        arguments = [containers_file.path, files_list, output.path],
        executable = (
            ctx.attr._xccurrentversions_parser[DefaultInfo].files_to_run
        ),
        inputs = [containers_file] + xccurrentversion_files,
        outputs = [output],
        mnemonic = "CalculateXcodeProjXCCurrentVersions",
    )

    return output

def _write_extensionpointidentifiers(*, ctx, extension_infoplists):
    targetids_file = ctx.actions.declare_file(
        "{}_extensionpointidentifiers_targetids".format(ctx.attr.name),
    )
    ctx.actions.write(
        targetids_file,
        "".join([s.id + "\n" for s in extension_infoplists]),
    )

    infoplist_files = [s.infoplist for s in extension_infoplists]

    files_list = ctx.actions.args()
    files_list.use_param_file("%s", use_always = True)
    files_list.set_param_file_format("multiline")
    files_list.add_all(infoplist_files)

    output = ctx.actions.declare_file(
        "{}_extensionpointidentifiers".format(ctx.attr.name),
    )

    tool = ctx.attr._extensionpointidentifiers_parser[DefaultInfo].files_to_run
    ctx.actions.run(
        arguments = [targetids_file.path, files_list, output.path],
        executable = tool,
        inputs = [targetids_file] + infoplist_files,
        outputs = [output],
        mnemonic = "CalculateXcodeProjExtensionPointIdentifiers",
    )

    return output

def _write_bazel_build_script(*, ctx, target_ids_list):
    output = ctx.actions.declare_file(
        "{}_bazel_integration_files/bazel_build.sh".format(ctx.attr.name),
    )

    envs = []
    for key, value in ctx.attr.bazel_env.items():
        envs.append("  '{}={}'".format(
            key,
            (value
                .replace(
                # Escape single quotes for bash
                "'",
                "'\"'\"'",
            )),
        ))

    ctx.actions.expand_template(
        template = ctx.file._bazel_build_script_template,
        output = output,
        is_executable = True,
        substitutions = {
            "%bazel_env%": "\n".join(envs),
            "%bazel_path%": ctx.attr.bazel_path,
            "%generator_label%": str(ctx.label),
            "%target_ids_list%": (
                "$PROJECT_DIR/{}".format(target_ids_list.path)
            ),
        },
    )

    return output

def _write_create_xcode_overlay_script(*, ctx, targets):
    output = ctx.actions.declare_file(
        "{}_bazel_integration_files/create_xcode_overlay.sh".format(
            ctx.attr.name,
        ),
    )

    roots = []
    for xcode_target in targets.values():
        generated_header = xcode_target.outputs.swift_generated_header
        if not generated_header:
            continue

        path = generated_header.path
        build_dir = "$BUILD_DIR/{}".format(path)
        bazel_out = "$BAZEL_OUT{}".format(path[9:])

        roots.append("""\
{{"external-contents": "{build_dir}","name": "${{bazel_out_prefix}}{bazel_out}","type": "file"}}\
""".format(bazel_out = bazel_out, build_dir = build_dir))

    ctx.actions.expand_template(
        template = ctx.file._create_xcode_overlay_script_template,
        output = output,
        is_executable = True,
        substitutions = {
            "%roots%": ",".join(sorted(roots)),
        },
    )

    return output

def _write_execution_root_file(*, ctx):
    output = ctx.actions.declare_file("{}_execution_root_file".format(ctx.attr.name))

    ctx.actions.run_shell(
        outputs = [output],
        command = """\
bin_dir_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{bin_dir_full}";)"
execution_root="${{bin_dir_full_path%/{bin_dir_full}}}"

echo "$execution_root" > "{out_full}"
""".format(
            bin_dir_full = ctx.bin_dir.path,
            out_full = output.path,
        ),
        mnemonic = "CalculateXcodeProjExecutionRoot",
        # This has to run locally
        execution_requirements = {
            "local": "1",
            "no-remote": "1",
            "no-sandbox": "1",
        },
    )

    return output

def _write_target_ids_list(*, ctx, target_dtos):
    output = ctx.actions.declare_file(
        "{}_target_ids".format(ctx.attr.name),
    )

    ctx.actions.write(
        output,
        "".join([id + "\n" for id in sorted(target_dtos.keys())]),
    )

    return output

def _write_xcodeproj(
        *,
        ctx,
        build_mode,
        execution_root_file,
        extensionpointidentifiers_file,
        install_path,
        is_fixture,
        colorize,
        spec_files,
        workspace_directory,
        xccurrentversions_file):
    xcodeproj = ctx.actions.declare_directory(
        "{}.xcodeproj".format(ctx.attr.name),
    )

    args = ctx.actions.args()
    args.add(execution_root_file.path)
    args.add(workspace_directory)
    args.add(xccurrentversions_file.path)
    args.add(extensionpointidentifiers_file.path)
    args.add(xcodeproj.path)
    args.add(install_path)
    args.add(build_mode)
    args.add("1" if is_fixture else "0")
    args.add("1" if colorize else "0")
    args.add_all(spec_files)

    ctx.actions.run(
        executable = ctx.attr._generator[DefaultInfo].files_to_run,
        mnemonic = "GenerateXcodeProj",
        progress_message = "Generating \"{}\"".format(install_path),
        arguments = [args],
        inputs = spec_files + [
            execution_root_file,
            xccurrentversions_file,
            extensionpointidentifiers_file,
        ],
        outputs = [xcodeproj],
        tools = [ctx.attr._index_import[DefaultInfo].files_to_run],
        execution_requirements = {
            # Projects can be rather large, and take almost no time to generate
            # This also works around any RBC tree artifact issues
            # (e.g. https://github.com/bazelbuild/bazel/issues/15010)
            "no-remote": "1",
        },
    )

    return xcodeproj

def _write_installer(
        *,
        ctx,
        name = None,
        bazel_integration_files,
        config,
        configurations_map,
        install_path,
        is_fixture,
        spec_files,
        xcodeproj):
    installer = ctx.actions.declare_file(
        "{}-installer.sh".format(name or ctx.attr.name),
    )

    configurations_replacements = "\\n".join([
        "{} {}".format(replacement, configuration)
        for configuration, replacement in configurations_map.items()
    ])

    ctx.actions.expand_template(
        template = ctx.file._installer_template,
        output = installer,
        is_executable = True,
        substitutions = {
            "%bazel_integration_files%": shell.array_literal(
                [f.short_path for f in bazel_integration_files],
            ),
            "%config%": config,
            "%configurations_replacements%": configurations_replacements,
            "%is_fixture%": "1" if is_fixture else "0",
            "%output_path%": install_path,
            "%source_path%": xcodeproj.short_path,
            "%spec_paths%": shell.array_literal(
                [f.short_path for f in spec_files],
            ),
        },
    )

    return installer

# Transition

_BASE_TRANSITION_INPUTS = [
    "//command_line_option:cpu",
]

_BASE_TRANSITION_OUTPUTS = [
    "//command_line_option:ios_multi_cpus",
    "//command_line_option:tvos_cpus",
    "//command_line_option:watchos_cpus",
]

# buildifier: disable=function-docstring
def make_xcodeproj_target_transitions(
        *,
        implementation,
        inputs = [],
        outputs = []):
    merged_inputs = uniq(_BASE_TRANSITION_INPUTS + inputs)
    merged_outputs = uniq(_BASE_TRANSITION_OUTPUTS + outputs)

    def device_impl(settings, attr):
        base_outputs = {
            "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
            "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
            "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
        }

        merged_outputs = {}
        for config, config_outputs in implementation(settings, attr).items():
            o = dict(config_outputs)
            o.update(base_outputs)
            merged_outputs[config] = o

        return merged_outputs

    def simulator_impl(settings, attr):
        cpu_value = settings["//command_line_option:cpu"]

        ios_cpus = attr.ios_simulator_cpus
        if not ios_cpus:
            if cpu_value == "darwin_arm64":
                ios_cpus = "sim_arm64"
            else:
                ios_cpus = "x86_64"

        tvos_cpus = attr.tvos_simulator_cpus
        if not tvos_cpus:
            if cpu_value == "darwin_arm64":
                tvos_cpus = "sim_arm64"
            else:
                tvos_cpus = "x86_64"

        watchos_cpus = attr.watchos_simulator_cpus
        if not watchos_cpus:
            if cpu_value == "darwin_arm64":
                watchos_cpus = "arm64"
            else:
                # rules_apple defaults to i386, but Xcode 13 requires x86_64
                watchos_cpus = "x86_64"

        base_outputs = {
            "//command_line_option:ios_multi_cpus": ios_cpus,
            "//command_line_option:tvos_cpus": tvos_cpus,
            "//command_line_option:watchos_cpus": watchos_cpus,
        }

        merged_outputs = {}
        for config, config_outputs in implementation(settings, attr).items():
            o = dict(config_outputs)
            o.update(base_outputs)
            merged_outputs[config] = o

        return merged_outputs

    simulator_transition = transition(
        implementation = simulator_impl,
        inputs = merged_inputs,
        outputs = merged_outputs,
    )
    device_transition = transition(
        implementation = device_impl,
        inputs = merged_inputs,
        outputs = merged_outputs,
    )
    return struct(
        device = device_transition,
        simulator = simulator_transition,
    )

# Rule

def _xcodeproj_impl(ctx):
    xcode_configuration_map = ctx.attr.xcode_configuration_map
    infos = []
    infos_per_xcode_configuration = {}
    for transition_key in (
        ctx.split_attr.top_level_simulator_targets.keys() +
        ctx.split_attr.top_level_device_targets.keys()
    ):
        targets = []
        if ctx.split_attr.top_level_simulator_targets:
            targets.extend(
                ctx.split_attr.top_level_simulator_targets[transition_key],
            )
        if ctx.split_attr.top_level_device_targets:
            targets.extend(
                ctx.split_attr.top_level_device_targets[transition_key],
            )

        i = [_process_dep(dep) for dep in targets]
        infos.extend(i)
        for xcode_configuration in xcode_configuration_map[transition_key]:
            infos_per_xcode_configuration[xcode_configuration] = i

    xcode_configurations = sorted(infos_per_xcode_configuration.keys())
    default_xcode_configuration = (
        ctx.attr.default_xcode_configuration or
        xcode_configurations[0]
    )
    if default_xcode_configuration not in infos_per_xcode_configuration:
        fail("""\
`default_xcode_configuration` must be `None`, or one of the defined \
configurations: {}""".format(", ".join(xcode_configurations)))

    build_mode = ctx.attr.build_mode
    config = ctx.attr.config
    install_path = ctx.attr.install_path
    is_fixture = ctx.attr._is_fixture
    colorize = ctx.attr.colorize
    project_name = ctx.attr.project_name
    configuration = get_configuration(ctx = ctx)
    minimum_xcode_version = (ctx.attr.minimum_xcode_version or
                             _get_minimum_xcode_version(ctx = ctx))

    outputs = output_files.merge(
        ctx = ctx,
        automatic_target_info = None,
        transitive_infos = [(None, info) for info in infos],
    )

    inputs = input_files.merge(
        transitive_infos = [(None, info) for info in infos],
    )
    focused_labels = {label: None for label in ctx.attr.focused_targets}
    unfocused_labels = {label: None for label in ctx.attr.unfocused_targets}
    replacement_labels = {
        r.id: r.label
        for r in depset(
            transitive = [info.replacement_labels for info in infos],
        ).to_list()
    }

    (
        targets,
        target_dtos,
        additional_generated,
        additional_outputs,
        focused_targets_extra_files,
        focused_targets_extra_folders,
        replacement_labels_by_label,
        configurations_map,
        lldb_contexts_dtos,
    ) = _process_targets(
        ctx = ctx,
        build_mode = build_mode,
        is_fixture = is_fixture,
        configuration = configuration,
        focused_labels = focused_labels,
        unfocused_labels = unfocused_labels,
        replacement_labels = replacement_labels,
        inputs = inputs,
        infos = infos,
        infos_per_xcode_configuration = infos_per_xcode_configuration,
        owned_extra_files = ctx.attr.owned_extra_files,
        include_swiftui_previews_scheme_targets = (
            build_mode == "bazel" and
            ctx.attr.adjust_schemes_for_swiftui_previews
        ),
        fail_for_invalid_extra_files_targets = (
            ctx.attr.fail_for_invalid_extra_files_targets
        ),
    )

    args = {
        s.id: s.args
        for s in depset(
            transitive = [info.args for info in infos],
        ).to_list()
        if s.args and s.id in target_dtos
    }
    envs = {
        s.id: s.env
        for s in depset(
            transitive = [info.envs for info in infos],
        ).to_list()
        if s.env and s.id in target_dtos
    }

    extra_files, extra_folders = _process_extra_files(
        ctx = ctx,
        configurations_map = configurations_map,
        focused_labels = focused_labels,
        is_fixture = is_fixture,
        unfocused_labels = unfocused_labels,
        replacement_labels_by_label = replacement_labels_by_label,
        inputs = inputs,
        focused_targets_extra_files = focused_targets_extra_files,
        focused_targets_extra_folders = focused_targets_extra_folders,
    )
    xccurrentversion_files = _process_xccurrentversions(
        focused_labels = focused_labels,
        unfocused_labels = unfocused_labels,
        replacement_labels_by_label = replacement_labels_by_label,
        inputs = inputs,
    )
    target_ids_list = _write_target_ids_list(
        ctx = ctx,
        target_dtos = target_dtos,
    )

    extension_infoplists = [
        s
        for s in depset(
            transitive = [
                info.extension_infoplists
                for info in infos
            ],
        ).to_list()
        if s.id in targets
    ]

    spec_files = _write_spec(
        ctx = ctx,
        args = args,
        is_fixture = is_fixture,
        project_name = project_name,
        project_options = ctx.attr.project_options,
        config = config,
        xcode_configurations = xcode_configurations,
        default_xcode_configuration = default_xcode_configuration,
        envs = envs,
        target_dtos = target_dtos,
        extra_files = extra_files,
        extra_folders = extra_folders,
        infos = infos,
        minimum_xcode_version = minimum_xcode_version,
        target_ids_list = target_ids_list,
    )
    execution_root_file = _write_execution_root_file(ctx = ctx)
    xccurrentversions_file = _write_xccurrentversions(
        ctx = ctx,
        xccurrentversion_files = xccurrentversion_files,
    )
    extensionpointidentifiers_file = _write_extensionpointidentifiers(
        ctx = ctx,
        extension_infoplists = extension_infoplists,
    )
    swift_debug_settings = _write_swift_debug_settings(
        ctx = ctx,
        settings = lldb_contexts_dtos,
    )

    if configurations_map:
        flags = " ".join([
            "-e \'s/{}/{}/g\'".format(configuration, replacement)
            for configuration, replacement in configurations_map.items()
        ])

        normalized_specs = [
            ctx.actions.declare_file(
                "{}-normalized/spec.{}.json".format(ctx.attr.name, idx),
            )
            for idx, file in enumerate(spec_files)
        ]
        normalized_extensionpointidentifiers = ctx.actions.declare_file(
            "{}_normalized/extensionpointidentifiers_targetids".format(
                ctx.attr.name,
            ),
        )
        normalized_swift_debug_settings = [
            ctx.actions.declare_file(
                "{}_normalized/{}-swift_debug_settings.py".format(
                    ctx.attr.name,
                    xcode_configuration,
                ),
            )
            for xcode_configuration in lldb_contexts_dtos
        ]

        unstable_files = (
            spec_files +
            swift_debug_settings +
            [extensionpointidentifiers_file]
        )
        normalized_files = (
            normalized_specs +
            normalized_swift_debug_settings +
            [normalized_extensionpointidentifiers]
        )
        ctx.actions.run_shell(
            inputs = unstable_files,
            outputs = normalized_files,
            command = """\
readonly inputs={inputs}
readonly outputs={outputs}

for ((i = 0; i < ${{#inputs[@]}}; i++)); do
sed {flags} ${{inputs[$i]}} > ${{outputs[$i]}}
done
""".format(
                inputs = shell.array_literal([f.path for f in unstable_files]),
                outputs = shell.array_literal(
                    [f.path for f in normalized_files],
                ),
                flags = flags,
            ),
        )

        spec_files = normalized_specs
        extensionpointidentifiers_file = normalized_extensionpointidentifiers
        swift_debug_settings = normalized_swift_debug_settings

    bazel_integration_files = (
        list(ctx.files._base_integration_files) +
        swift_debug_settings
    ) + [
        _write_bazel_build_script(ctx = ctx, target_ids_list = target_ids_list),
    ]
    if build_mode == "xcode":
        bazel_integration_files.append(
            _write_create_xcode_overlay_script(ctx = ctx, targets = targets),
        )
    else:
        bazel_integration_files.extend(ctx.files._bazel_integration_files)

    xcodeproj = _write_xcodeproj(
        ctx = ctx,
        execution_root_file = execution_root_file,
        install_path = install_path,
        workspace_directory = ctx.attr.workspace_directory,
        spec_files = spec_files,
        xccurrentversions_file = xccurrentversions_file,
        extensionpointidentifiers_file = extensionpointidentifiers_file,
        build_mode = build_mode,
        is_fixture = is_fixture,
        colorize = colorize,
    )
    installer = _write_installer(
        ctx = ctx,
        bazel_integration_files = bazel_integration_files,
        config = config,
        configurations_map = configurations_map,
        install_path = install_path,
        is_fixture = is_fixture,
        spec_files = spec_files,
        xcodeproj = xcodeproj,
    )

    if build_mode == "xcode":
        input_files_output_groups = input_files.to_output_groups_fields(
            inputs = inputs,
            additional_generated = additional_generated,
            index_import = ctx.executable._index_import,
        )
        output_files_output_groups = {}
        all_targets_files = [
            input_files_output_groups["all_xc"],
            input_files_output_groups["all_xi"],
            input_files_output_groups["all_xl"],
        ]
    else:
        input_files_output_groups = {}
        output_files_output_groups = output_files.to_output_groups_fields(
            outputs = outputs,
            additional_outputs = additional_outputs,
            index_import = ctx.executable._index_import,
        )
        all_targets_files = [output_files_output_groups["all_b"]]

    return [
        DefaultInfo(
            executable = installer,
            files = depset(
                spec_files + [xcodeproj],
                transitive = [inputs.important_generated],
            ),
            runfiles = ctx.runfiles(
                files = spec_files + [xcodeproj] + bazel_integration_files,
            ),
        ),
        OutputGroupInfo(
            all_targets = depset(
                transitive = all_targets_files,
            ),
            target_ids_list = depset([target_ids_list]),
            **dicts.add(
                input_files_output_groups,
                output_files_output_groups,
            )
        ),
    ]

bwx_xcodeproj_aspect = make_xcodeproj_aspect(build_mode = "xcode")
bwb_xcodeproj_aspect = make_xcodeproj_aspect(build_mode = "bazel")

# buildifier: disable=function-docstring
def make_xcodeproj_rule(
        *,
        build_mode,
        is_fixture = False,
        target_transitions = None,
        xcodeproj_transition = None):
    if build_mode == "bazel":
        xcodeproj_aspect = bwb_xcodeproj_aspect
    else:
        xcodeproj_aspect = bwx_xcodeproj_aspect

    attrs = {
        "adjust_schemes_for_swiftui_previews": attr.bool(
            mandatory = True,
        ),
        "bazel_path": attr.string(
            mandatory = True,
        ),
        "bazel_env": attr.string_dict(
            mandatory = True,
        ),
        "build_mode": attr.string(
            mandatory = True,
        ),
        "colorize": attr.bool(mandatory = True),
        "config": attr.string(
            mandatory = True,
        ),
        "default_xcode_configuration": attr.string(),
        "fail_for_invalid_extra_files_targets": attr.bool(
            mandatory = True,
        ),
        "focused_targets": attr.string_list(
            mandatory = True,
        ),
        "install_path": attr.string(
            mandatory = True,
        ),
        "minimum_xcode_version": attr.string(
            mandatory = True,
        ),
        "owned_extra_files": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
        ),
        "post_build": attr.string(
            mandatory = True,
        ),
        "pre_build": attr.string(
            mandatory = True,
        ),
        "project_name": attr.string(
            mandatory = True,
        ),
        "project_options": attr.string_dict(
            mandatory = True,
        ),
        "runner_build_file": attr.string(
            mandatory = True,
        ),
        "runner_label": attr.string(
            mandatory = True,
        ),
        "scheme_autogeneration_mode": attr.string(
            mandatory = True,
        ),
        "schemes_json": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "top_level_device_targets": attr.label_list(
            cfg = target_transitions.device,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
            mandatory = True,
        ),
        "top_level_simulator_targets": attr.label_list(
            cfg = target_transitions.simulator,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
            mandatory = True,
        ),
        "unfocused_targets": attr.string_list(
            mandatory = True,
        ),
        "unowned_extra_files": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "workspace_directory": attr.string(
            mandatory = True,
        ),
        "xcode_configuration_map": attr.string_list_dict(
            mandatory = True,
        ),
        "ios_device_cpus": attr.string(
            mandatory = True,
        ),
        "ios_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "tvos_device_cpus": attr.string(
            mandatory = True,
        ),
        "tvos_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "watchos_device_cpus": attr.string(
            mandatory = True,
        ),
        "watchos_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = Label(
                "@bazel_tools//tools/allowlists/function_transition_allowlist",
            ),
        ),
        "_base_integration_files": attr.label(
            cfg = "exec",
            allow_files = True,
            default = Label(
                "//xcodeproj/internal/bazel_integration_files:base_integration_files",
            ),
        ),
        "_bazel_build_script_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal:bazel_build.template.sh",
            ),
        ),
        "_bazel_integration_files": attr.label(
            cfg = "exec",
            allow_files = True,
            default = Label("//xcodeproj/internal/bazel_integration_files"),
        ),
        "_create_xcode_overlay_script_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal:create_xcode_overlay.template.sh",
            ),
        ),
        "_extensionpointidentifiers_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/extensionpointidentifiers_parser"),
            executable = True,
        ),
        "_generator": attr.label(
            cfg = "exec",
            default = Label("//tools/generator:universal_generator"),
            executable = True,
        ),
        "_index_import": attr.label(
            cfg = "exec",
            default = Label("@rules_xcodeproj_index_import//:index_import"),
            executable = True,
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
        "_is_fixture": attr.bool(default = is_fixture),
        "_link_params_processor": attr.label(
            cfg = "exec",
            default = Label("//tools/params_processors:link_params_processor"),
            executable = True,
        ),
        "_swift_debug_settings_template": attr.label(
            allow_single_file = True,
            default = Label(
                "//xcodeproj/internal:swift_debug_settings.template.py",
            ),
        ),
        "_xccurrentversions_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/xccurrentversions_parser"),
            executable = True,
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    }

    return rule(
        doc = "Creates an `.xcodeproj` file in the workspace when run.",
        cfg = xcodeproj_transition,
        implementation = _xcodeproj_impl,
        attrs = attrs,
        executable = True,
    )

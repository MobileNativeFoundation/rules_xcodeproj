"""Implementation of the `xcodeproj` rule."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:shell.bzl", "shell")
load(
    "//xcodeproj/internal/bazel_integration_files:actions.bzl",
    "write_bazel_build_script",
    "write_create_xcode_overlay_script",
)
load(":bazel_labels.bzl", "bazel_labels")
load(":collections.bzl", "set_if_true", "uniq")
load(":configuration.bzl", "calculate_configuration")
load(":execution_root.bzl", "write_execution_root_file")
load(
    ":extension_point_identifiers.bzl",
    "write_extension_point_identifiers_file",
)
load(":files.bzl", "build_setting_path")
load(":flattened_key_values.bzl", "flattened_key_values")
load(":input_files.bzl", "input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":logging.bzl", "warn")
load(":memory_efficiency.bzl", "FALSE_ARG", "TRUE_ARG")
load(":output_files.bzl", "output_files")
load(":platforms.bzl", "platforms")
load(":project_options.bzl", "project_options_to_dto")
load(":providers.bzl", "XcodeProjInfo")
load(":resource_target.bzl", "process_resource_bundles")
load(":target_id.bzl", "write_target_ids_list")
load(":xcode_targets.bzl", "xcode_targets")

# Utility

_SWIFTUI_PREVIEW_PRODUCT_TYPES = {
    "com.apple.product-type.app-extension": None,
    "com.apple.product-type.application": None,
    "com.apple.product-type.application.on-demand-install-capable": None,
    "com.apple.product-type.application.watchapp2": None,
    "com.apple.product-type.bundle": None,
    "com.apple.product-type.bundle.unit-test": None,
    "com.apple.product-type.extensionkit-extension": None,
    "com.apple.product-type.framework": None,
    "com.apple.product-type.tool": None,
    "com.apple.product-type.tv-app-extension": None,
}

# TODO: Non-test_host applications should be terminal as well
_TERMINAL_PRODUCT_TYPES = {
    "com.apple.product-type.bundle.ui-testing": None,
    "com.apple.product-type.bundle.unit-test": None,
}

# Error Message Strings

_INVALID_EXTRA_FILES_TARGETS_BASE_MESSAGE = """\
Are you using an `alias`? `associated_extra_files` requires labels of the \
actual targets: {}
"""

_INVALID_EXTRA_FILES_TARGETS_HINT = """\
You can turn this error into a warning with `fail_for_invalid_extra_files_targets`
"""

def _calculate_bwx_unfocused_dependencies(
        *,
        build_mode,
        bwx_unfocused_libraries,
        focused_targets,
        targets,
        unfocused_targets):
    if build_mode != "xcode":
        return {}

    automatic_unfocused_dependencies = []
    transitive_focused_dependencies = []
    if unfocused_targets or bwx_unfocused_libraries:
        for xcode_target in focused_targets:
            transitive_focused_dependencies.append(
                xcode_target.transitive_dependencies,
            )
            if xcode_target.product.file_path in bwx_unfocused_libraries:
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
        targets,
        transitive_dependencies,
        xcode_target):
    return [
        id
        for id in transitive_dependencies
        if _is_same_platform_swiftui_preview_target(
            platform = xcode_target.platform,
            xcode_target = targets.get(id),
        )
    ]

def _get_minimum_xcode_version(*, xcode_config):
    version = str(xcode_config.xcode_version())
    if not version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")
    return ".".join(version.split(".")[0:3])

def _is_same_platform_swiftui_preview_target(*, platform, xcode_target):
    if not xcode_target:
        return False
    if not platforms.is_same_type(platform, xcode_target.platform):
        return False
    return xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES

def _process_dep(dep):
    info = dep[XcodeProjInfo]

    if info.non_top_level_rule_kind:
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
""".format(label = dep.label, kind = info.non_top_level_rule_kind))

    return info

def _process_extra_files(
        *,
        configurations_map,
        focused_labels,
        focused_targets_extra_files,
        focused_targets_extra_folders,
        inputs,
        is_fixture,
        replacement_labels_by_label,
        runner_build_file,
        unfocused_labels,
        unowned_extra_files):
    # Apply replacement labels
    extra_files_depsets_by_label = [
        (
            bazel_labels.normalize_label(
                replacement_labels_by_label.get(label, label),
            ),
            d,
        )
        for label, d in depset(
            # Processed owned extra files
            focused_targets_extra_files,
            transitive = [inputs.extra_files],
        ).to_list()
    ]
    extra_folders_depsets_by_label = [
        (
            bazel_labels.normalize_label(
                replacement_labels_by_label.get(label, label),
            ),
            d,
        )
        for label, d in focused_targets_extra_folders
    ]

    # Filter out unfocused labels
    has_focused_labels = bool(focused_labels)
    extra_files_depsets = [
        d
        for label, d in extra_files_depsets_by_label
        if not label or not (
            label in unfocused_labels or
            (has_focused_labels and label not in focused_labels)
        )
    ]
    extra_folders_depsets = [
        d
        for label, d in extra_folders_depsets_by_label
        if not label or not (
            label in unfocused_labels or
            (has_focused_labels and label not in focused_labels)
        )
    ]

    # Unowned extra files
    all_unowned_extra_files = [runner_build_file]
    for target in unowned_extra_files:
        all_unowned_extra_files.extend(
            [file.path for file in target.files.to_list()],
        )

    extra_files = depset(
        all_unowned_extra_files,
        transitive = extra_files_depsets,
    ).to_list()
    extra_folders = depset(
        transitive = extra_folders_depsets,
    ).to_list()

    if is_fixture:
        def _normalize_path(path):
            # bazel-out/darwin_x86_64-dbg-ST-deadbeaf/bin -> bazel-out/darwin_x86_64-dbg-STABLE-1/bin
            if not path.startswith("bazel-out/"):
                return path

            configuration, _, suffix = path[10:].partition("/")
            if not suffix:
                return path

            return (
                "bazel-out/" +
                configurations_map.get(configuration, configuration) + "/" +
                suffix
            )

        extra_files = [
            _normalize_path(path)
            for path in extra_files
        ]
        extra_folders = [
            _normalize_path(path)
            for path in extra_folders
        ]
        extra_files = sorted(extra_files)
        extra_folders = sorted(extra_folders)

    return extra_files, extra_folders

def _process_xccurrentversions(
        *,
        focused_labels,
        inputs,
        replacement_labels_by_label,
        unfocused_labels):
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
        actions,
        build_mode,
        is_fixture,
        configuration,
        focused_labels,
        link_params_processor,
        unfocused_labels,
        replacement_labels,
        inputs,
        infos,
        infos_per_xcode_configuration,
        name,
        owned_extra_files,
        include_swiftui_previews_scheme_targets,
        fail_for_invalid_extra_files_targets):
    resource_bundle_xcode_targets = []
    unprocessed_targets = {}
    xcode_configurations = {}
    for xcode_configuration, i in infos_per_xcode_configuration.items():
        configuration_inputs = input_files.merge(
            transitive_infos = i,
        )
        configuration_resource_bundle_xcode_targets = process_resource_bundles(
            bundles = configuration_inputs.resource_bundles.to_list(),
            resource_bundle_ids = depset(
                transitive = [
                    info.resource_bundle_ids
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
        label_configurations = {}
        for xcode_target in unprocessed_targets.values():
            # Make it stable over labels
            label_configurations.setdefault(
                xcode_target.label,
                {},
            )[xcode_target.configuration] = xcode_target

        configurations = {configuration: None}
        for label_configs in label_configurations.values():
            for configuration in label_configs:
                configurations[configuration] = None

        for idx, configuration in enumerate(configurations):
            configurations_map[configuration] = (
                "CONFIGURATION-STABLE-{}".format(idx)
            )

    replacement_labels_by_label = {
        unprocessed_targets[id].label: label
        for id, label in replacement_labels.items()
    }

    xcode_target_labels = {
        t.id: t.label
        for t in unprocessed_targets.values()
    }

    # `replacement_labels` are rare, so we iterate it and update
    # `xcode_target_labels` instead of looking into it for each label
    for id, label in replacement_labels.items():
        xcode_target_labels[id] = label

    xcode_target_label_strs = {
        id: bazel_labels.normalize_label(label)
        for id, label in xcode_target_labels.items()
    }

    owned_extra_files = {
        key: bazel_labels.normalize_label(Label(label_str))
        for key, label_str in owned_extra_files.items()
    }

    if focused_labels or owned_extra_files:
        # Can't use `xcode_target_label_strs`, as those are only for bazel
        # targets that create Xcode targets
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

        invalid_extra_files_targets = [
            label
            for label in owned_extra_files.values()
            if label not in label_strs
        ]
        if invalid_extra_files_targets:
            message = _INVALID_EXTRA_FILES_TARGETS_BASE_MESSAGE.format(
                invalid_extra_files_targets,
            )
            if fail_for_invalid_extra_files_targets:
                fail(message + _INVALID_EXTRA_FILES_TARGETS_HINT)
            else:
                warn(message)

    bwx_unfocused_libraries = {
        library: None
        for library in inputs.bwx_unfocused_libraries.to_list()
    }
    has_focused_labels = bool(focused_labels)

    if build_mode == "xcode" and resource_bundle_xcode_targets:
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
            focused_targets_extra_files.extend(
                xcode_target.inputs.resources.to_list(),
            )
            focused_targets_extra_folders.extend(
                xcode_target.inputs.folder_resources.to_list(),
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
        src_target = unprocessed_targets[merge.src]
        src_label = bazel_labels.normalize_label(src_target.label)
        dest_target = unprocessed_targets[merge.dest]
        dest_label = bazel_labels.normalize_label(dest_target.label)
        if src_label in unfocused_labels or dest_label in unfocused_labels:
            continue

        # Exclude targets not in focused nor unfocused targets from
        # potential merges since they're not possible Xcode targets.
        merge_src_is_xcode_target = (
            merge.src in focused_targets or
            merge.src in unfocused_targets
        )
        if not merge_src_is_xcode_target:
            continue
        raw_target_merge_dests.setdefault(merge.dest, []).append(merge.src)

    target_merge_dests = {}
    for dest, src_ids in raw_target_merge_dests.items():
        if len(src_ids) == 1:
            # We can always add merge targets of a single library dependency
            pass
        elif len(src_ids) == 2:
            # Only merge if one src is swift and the other isn't.
            src_1 = src_ids[0]
            src_2 = src_ids[1]
            src_1_is_swift = unprocessed_targets[src_1].swift_params
            src_2_is_swift = unprocessed_targets[src_2].swift_params

            # Only merge 1 Swift and 1 non-Swift target for now.
            if (src_1_is_swift and src_2_is_swift) or (not src_1_is_swift and not src_2_is_swift):
                continue
        else:
            # Unmergable source target count
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

    bwx_unfocused_dependencies = _calculate_bwx_unfocused_dependencies(
        build_mode = build_mode,
        bwx_unfocused_libraries = bwx_unfocused_libraries,
        focused_targets = focused_targets.values(),
        targets = unprocessed_targets,
        unfocused_targets = unfocused_targets,
    )

    has_automatic_unfocused_targets = bool(bwx_unfocused_libraries)
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
                        depset([file.path for file in file.files.to_list()]),
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
    for dest, srcs in target_merge_dests.items():
        dest_target = focused_targets[dest]
        src_labels = [focused_targets[src].label for src in srcs]

        if dest_target.product.type not in _TERMINAL_PRODUCT_TYPES:
            for src in srcs:
                non_terminal_dests.setdefault(src, []).append(dest)

        # Process all libraries that cannot be merged into `dest_target`
        for library in xcode_targets.get_top_level_static_libraries(
            dest_target,
        ):
            if library.owner in src_labels:
                continue

            # Other libraries that are not being merged into `dest_target`
            # can't merge into other targets
            non_mergable_targets[library.path] = None

    for src in target_merges.keys():
        src_target = focused_targets[src]
        if (len(non_terminal_dests.get(src, [])) > 1 or
            src_target.product.file_path in non_mergable_targets):
            # Prevent any version of `src` from merging, to prevent odd
            # target consolidation issues
            for id in target_merge_srcs_by_label[src_target.label]:
                target_merges.pop(id, None)

    # Remap 'target_merge_dests' after popping invalid merges.
    target_merge_dests = {}
    target_merge_src_targets = {}
    for src, dests in target_merges.items():
        # Pop all merge srcs from focused_targets since they will be merged into
        # the merge destination(s).
        target_merge_src_targets[src] = focused_targets.pop(src)
        for dest in dests:
            target_merge_dests.setdefault(dest, []).append(src)

    for dest, srcs in target_merge_dests.items():
        src_targets = [target_merge_src_targets[src] for src in srcs]

        # This functionality assumes that 2 or less sources are present in the
        # potential merge. If that changes, this will need updated.
        src_target_swift = None
        src_target_non_swift = None

        for src_target in src_targets:
            if src_target.swift_params:
                src_target_swift = src_target
            else:
                src_target_non_swift = src_target

        focused_targets[dest] = xcode_targets.merge(
            src_swift = src_target_swift,
            src_non_swift = src_target_non_swift,
            dest = focused_targets[dest],
        )

    (
        xcode_generated_paths,
        xcode_generated_paths_file,
    ) = _process_xcode_generated_paths(
        actions = actions,
        build_mode = build_mode,
        bwx_unfocused_dependencies = bwx_unfocused_dependencies,
        focused_targets = focused_targets,
        name = name,
    )

    excluded_targets = dicts.add(unfocused_targets, files_only_targets)

    lldb_contexts = {
        xcode_configuration: {}
        for xcode_configuration in infos_per_xcode_configuration.keys()
    }

    target_dtos = {}
    target_dependencies = {}
    target_compile_params = {}
    target_link_params = {}
    for index, xcode_target in enumerate(focused_targets.values()):
        transitive_dependencies = {
            id: None
            for id in xcode_target.transitive_dependencies.to_list()
        }

        if (include_swiftui_previews_scheme_targets and
            xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES):
            additional_scheme_target_ids = _calculate_swiftui_preview_targets(
                targets = focused_targets,
                transitive_dependencies = transitive_dependencies,
                xcode_target = xcode_target,
            )
        else:
            additional_scheme_target_ids = None

        label = xcode_target_labels[xcode_target.id]
        target_xcode_configurations = xcode_configurations[xcode_target.id]

        if include_lldb_context and xcode_target.lldb_context_key:
            for xcode_configuration in target_xcode_configurations:
                set_if_true(
                    lldb_contexts[xcode_configuration],
                    xcode_target.lldb_context_key,
                    xcode_target.lldb_context,
                )

        (
            dto,
            replaced_dependencies,
            link_params,
        ) = xcode_targets.to_dto(
            xcode_target,
            actions = actions,
            additional_scheme_target_ids = additional_scheme_target_ids,
            build_mode = build_mode,
            bwx_unfocused_dependencies = bwx_unfocused_dependencies,
            excluded_targets = excluded_targets,
            focused_labels = focused_labels,
            label = label,
            link_params_processor = link_params_processor,
            linker_products_map = linker_products_map,
            params_index = index,
            rule_name = name,
            should_include_outputs = should_include_outputs(build_mode),
            target_merges = target_merges,
            unfocused_labels = unfocused_labels,
            xcode_configurations = target_xcode_configurations,
            xcode_generated_paths = xcode_generated_paths,
            xcode_generated_paths_file = xcode_generated_paths_file,
        )
        target_dtos[xcode_target.id] = dto
        target_dependencies[xcode_target.id] = (
            transitive_dependencies,
            replaced_dependencies,
        )

        compile_params = []
        if xcode_target.c_params:
            compile_params.append(xcode_target.c_params)
        if xcode_target.cxx_params:
            compile_params.append(xcode_target.cxx_params)
        if xcode_target.swift_params:
            compile_params.append(xcode_target.swift_params)

        if compile_params:
            target_compile_params[xcode_target.id] = depset(compile_params)
        if link_params:
            target_link_params[xcode_target.id] = depset([link_params])

    additional_bwx_generated = {}
    additional_bwb_outputs = {}
    for xcode_target in focused_targets.values():
        (
            transitive_dependencies,
            replaced_dependencies,
        ) = target_dependencies[xcode_target.id]

        transitive_compile_params = []
        transitive_link_params = []

        compile_params = target_compile_params.get(xcode_target.id)
        if compile_params:
            transitive_compile_params.append(compile_params)
        link_params = target_link_params.get(xcode_target.id)
        if link_params:
            transitive_link_params.append(link_params)

        for id in transitive_dependencies:
            merge = target_merges.get(id)
            if merge:
                id = merge[0]
                if id == xcode_target.id:
                    continue
            compile_params = target_compile_params.get(id)
            if compile_params:
                transitive_compile_params.append(compile_params)
            link_params = target_link_params.get(id)
            if link_params:
                transitive_link_params.append(link_params)

        bwx_compiling_output_group_name = (
            xcode_target.inputs.compiling_output_group_name
        )
        bwb_generated_output_group_name = (
            xcode_target.outputs.generated_output_group_name
        )
        bwx_indexstores_output_group_name = (
            xcode_target.inputs.indexstores_output_group_name
        )
        bwx_linking_output_group_name = (
            xcode_target.inputs.linking_output_group_name
        )
        bwb_linking_output_group_name = (
            xcode_target.outputs.linking_output_group_name
        )

        additional_bwx_compiling_files = []
        additional_bwx_indexstores_files = []
        additional_bwx_linking_files = []

        label = xcode_target_labels[xcode_target.id]
        target_infoplists = infoplists.get(label)
        if target_infoplists:
            additional_bwx_linking_files.extend(target_infoplists)
            bwb_products_output_group_name = (
                xcode_target.outputs.products_output_group_name
            )
            if bwb_products_output_group_name:
                additional_bwb_outputs[bwb_products_output_group_name] = (
                    target_infoplists
                )

        if bwx_unfocused_dependencies:
            for dependency in transitive_dependencies:
                unfocused_dependency = bwx_unfocused_dependencies.get(
                    dependency,
                )
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
                    additional_bwx_compiling_files.append(
                        depset(unfocused_compiling_files),
                    )
                if unfocused_indexstores_files:
                    additional_bwx_indexstores_files.append(
                        depset(unfocused_indexstores_files),
                    )
                if unfocused_linking_files:
                    additional_bwx_linking_files.append(
                        depset(unfocused_linking_files),
                    )

        # We only check for one output group name, because the others are also
        # set if this one is
        if bwx_compiling_output_group_name:
            for id in replaced_dependencies:
                if id in transitive_dependencies:
                    continue

                # The replaced dependency is not a transitive dependency, so we
                # need to add its merge in its output groups

                compile_params = target_compile_params.get(id, None)
                if compile_params:
                    transitive_compile_params.append(compile_params)
                link_params = target_link_params.get(id, None)
                if link_params:
                    transitive_link_params.append(link_params)

                dep_target = focused_targets[id]

                dep_bwx_compiling_output_group_name = (
                    dep_target.inputs.compiling_output_group_name
                )
                dep_bwx_indexstores_output_group_name = (
                    dep_target.inputs.indexstores_output_group_name
                )
                dep_bwx_linking_output_group_name = (
                    dep_target.inputs.linking_output_group_name
                )

                # We only check for one output group name, because the others
                # are also set if this one is
                if dep_bwx_compiling_output_group_name:
                    additional_bwx_compiling_files.extend(
                        additional_bwx_generated.get(
                            dep_bwx_compiling_output_group_name,
                            [],
                        ),
                    )
                    additional_bwx_compiling_files.append(
                        dep_target.inputs.generated,
                    )

                    additional_bwx_indexstores_files.extend(
                        additional_bwx_generated.get(
                            dep_bwx_indexstores_output_group_name,
                            [],
                        ),
                    )
                    additional_bwx_indexstores_files.append(
                        dep_target.inputs.indexstores,
                    )

                    additional_bwx_linking_files.extend(
                        additional_bwx_generated.get(
                            dep_bwx_linking_output_group_name,
                            [],
                        ),
                    )

        if transitive_compile_params:
            additional_bwx_compiling_files.extend(transitive_compile_params)
            if bwb_generated_output_group_name:
                additional_bwb_outputs[bwb_generated_output_group_name] = (
                    transitive_compile_params
                )
        if transitive_link_params:
            if bwx_linking_output_group_name:
                additional_bwx_linking_files.extend(transitive_link_params)
            if bwb_linking_output_group_name:
                additional_bwb_outputs[bwb_linking_output_group_name] = (
                    transitive_link_params
                )

        # We only check for one output group name, because the others are also
        # set if this one is
        if bwx_compiling_output_group_name:
            set_if_true(
                additional_bwx_generated,
                bwx_compiling_output_group_name,
                additional_bwx_compiling_files,
            )
            set_if_true(
                additional_bwx_generated,
                bwx_indexstores_output_group_name,
                additional_bwx_indexstores_files,
            )
            set_if_true(
                additional_bwx_generated,
                bwx_linking_output_group_name,
                additional_bwx_linking_files,
            )

    return (
        focused_targets,
        target_dtos,
        additional_bwx_generated,
        additional_bwb_outputs,
        focused_targets_extra_files,
        focused_targets_extra_folders,
        replacement_labels_by_label,
        configurations_map,
        lldb_contexts,
        xcode_generated_paths_file,
    )

def _process_xcode_generated_paths(
        *,
        actions,
        build_mode,
        bwx_unfocused_dependencies,
        focused_targets,
        name):
    xcode_generated_paths = {}
    xcode_generated_paths_file = actions.declare_file(
        "{}-xcode_generated_paths.json".format(name),
    )

    if build_mode != "xcode":
        actions.write(
            content = json.encode(xcode_generated_paths),
            output = xcode_generated_paths_file,
        )
        return xcode_generated_paths, xcode_generated_paths_file

    for xcode_target in focused_targets.values():
        if xcode_target.id in bwx_unfocused_dependencies:
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

    actions.write(
        content = json.encode(xcode_generated_paths),
        output = xcode_generated_paths_file,
    )

    return xcode_generated_paths, xcode_generated_paths_file

def should_include_outputs(build_mode):
    return build_mode != "bazel_with_proxy"

# Actions

def _labelless_swift_sub_params(swift_sub_params_with_label):
    _, swift_sub_params = swift_sub_params_with_label
    return [file.path for file in swift_sub_params] + [""]

def _write_swift_debug_settings(
        *,
        actions,
        lldb_contexts,
        name,
        swift_debug_settings_processor,
        xcode_generated_paths_file):
    inputs = depset(
        [xcode_generated_paths_file],
        transitive = [
            lldb_context._swift_sub_params
            for config_lldb_contexts in lldb_contexts.values()
            for lldb_context in config_lldb_contexts.values()
        ],
    )

    outputs = []
    for (xcode_configuration, config_lldb_contexts) in lldb_contexts.items():
        output = actions.declare_file(
            "{}_bazel_integration_files/{}-swift_debug_settings.py".format(
                name,
                xcode_configuration,
            ),
        )
        outputs.append(output)

        args = actions.args()
        args.use_param_file("@%s", use_always = True)
        args.set_param_file_format(format = "multiline")
        args.add(output)
        args.add(xcode_generated_paths_file)

        for key, lldb_context in config_lldb_contexts.items():
            args.add(key)
            args.add_all(lldb_context._swiftmodules)
            args.add("")
            args.add_all(
                lldb_context._labelled_swift_sub_params,
                map_each = _labelless_swift_sub_params,
            )
            args.add("")

        actions.run(
            executable = swift_debug_settings_processor,
            arguments = [args],
            mnemonic = "SwiftDebugSettings",
            progress_message = "Generating %{output}",
            inputs = inputs,
            outputs = [output],
            execution_requirements = {
                # Lots (lots...) of input files, so avoid sandbox for speed
                "no-sandbox": "1",
            },
        )

    return outputs

def _write_spec(
        *,
        actions,
        args,
        config,
        default_xcode_configuration,
        envs,
        extra_files,
        extra_folders,
        infos,
        index_import,
        is_fixture,
        minimum_xcode_version,
        name,
        post_build,
        pre_build,
        project_name,
        project_options,
        runner_label,
        scheme_autogeneration_mode,
        schemes_json,
        target_dtos,
        target_ids_list,
        target_name_mode,
        xcode_configurations):
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
        "R": runner_label,
        "T": "fixture-target-ids-file" if is_fixture else build_setting_path(
            file = target_ids_list,
        ),
        "i": "fixture-index-import-path" if is_fixture else build_setting_path(
            file = index_import,
        ),
        "m": minimum_xcode_version,
        "n": project_name,
    }

    if xcode_configurations != ["Debug"]:
        spec_dto["x"] = xcode_configurations

    if default_xcode_configuration != "Debug":
        spec_dto["d"] = default_xcode_configuration

    project_options_dto = project_options_to_dto(project_options)
    if project_options_dto:
        spec_dto["o"] = project_options_dto

    if scheme_autogeneration_mode != "all":
        spec_dto["s"] = scheme_autogeneration_mode

    if target_name_mode != "auto":
        spec_dto["N"] = target_name_mode

    set_if_true(
        spec_dto,
        "a",
        flattened_key_values.to_list(args, sort = is_fixture),
    )
    set_if_true(
        spec_dto,
        "e",
        extra_files,
    )
    set_if_true(
        spec_dto,
        "F",
        extra_folders,
    )
    set_if_true(
        spec_dto,
        "E",
        flattened_key_values.to_list(envs, sort = is_fixture),
    )
    set_if_true(
        spec_dto,
        "P",
        post_build,
    )
    set_if_true(
        spec_dto,
        "p",
        pre_build,
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
        sort = False,
    )

    target_shards = []
    for shard in range(shard_count):
        sharded_targets = flattened_targets[shard * shard_size:(shard + 1) * shard_size]
        targets_json = json.encode(sharded_targets)
        targets_output = actions.declare_file(
            "{}-targets_spec.{}.json".format(name, shard),
        )
        actions.write(targets_output, targets_json)

        target_shards.append(targets_output)

    project_spec_output = actions.declare_file(
        "{}-project_spec.json".format(name),
    )
    actions.write(project_spec_output, project_spec_json)

    return [project_spec_output, schemes_json] + target_shards

def _write_xccurrentversions(
        *,
        actions,
        name,
        xccurrentversion_files,
        xccurrentversions_parser):
    containers_file = actions.declare_file(
        "{}_xccurrentversion_containers".format(name),
    )
    actions.write(
        containers_file,
        "".join([
            file.dirname + "\n"
            for file in xccurrentversion_files
        ]),
    )

    files_list = actions.args()
    files_list.use_param_file("%s", use_always = True)
    files_list.set_param_file_format("multiline")
    files_list.add_all(xccurrentversion_files)

    output = actions.declare_file(
        "{}_xccurrentversions".format(name),
    )
    actions.run(
        arguments = [containers_file.path, files_list, output.path],
        executable = xccurrentversions_parser,
        inputs = [containers_file] + xccurrentversion_files,
        outputs = [output],
        mnemonic = "CalculateXcodeProjXCCurrentVersions",
    )

    return output

def _write_xcodeproj(
        *,
        actions,
        build_mode,
        colorize,
        execution_root_file,
        extension_point_identifiers_file,
        generator,
        index_import,
        install_path,
        is_fixture,
        name,
        spec_files,
        workspace_directory,
        xccurrentversions_file):
    xcodeproj = actions.declare_directory(
        "{}.xcodeproj".format(name),
    )

    args = actions.args()
    args.add(execution_root_file.path)
    args.add(workspace_directory)
    args.add(xccurrentversions_file.path)
    args.add(extension_point_identifiers_file.path)
    args.add(xcodeproj.path)
    args.add(install_path)
    args.add(build_mode)
    args.add(TRUE_ARG if is_fixture else FALSE_ARG)
    args.add(TRUE_ARG if colorize else FALSE_ARG)
    args.add_all(spec_files)

    actions.run(
        executable = generator,
        mnemonic = "GenerateXcodeProj",
        progress_message = "Generating \"{}\"".format(install_path),
        arguments = [args],
        inputs = spec_files + [
            execution_root_file,
            xccurrentversions_file,
            extension_point_identifiers_file,
        ],
        outputs = [xcodeproj],
        tools = [index_import],
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
        actions,
        bazel_integration_files,
        config,
        configurations_map,
        install_path,
        is_fixture,
        name,
        spec_files,
        template,
        xcodeproj):
    installer = actions.declare_file(
        "{}-installer.sh".format(name),
    )

    configurations_replacements = "\\n".join([
        "{} {}".format(replacement, configuration)
        for configuration, replacement in configurations_map.items()
    ])

    actions.expand_template(
        template = template,
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

    actions = ctx.actions
    bin_dir_path = ctx.bin_dir.path
    build_mode = ctx.attr.build_mode
    colorize = ctx.attr.colorize
    config = ctx.attr.config
    configuration = calculate_configuration(bin_dir_path = bin_dir_path)
    install_path = ctx.attr.install_path
    is_fixture = ctx.attr._is_fixture
    minimum_xcode_version = (
        ctx.attr.minimum_xcode_version or
        _get_minimum_xcode_version(
            xcode_config = (
                ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
            ),
        )
    )
    name = ctx.attr.name
    project_name = ctx.attr.project_name

    if build_mode == "xcode" and bazel_features.cc.objc_linking_info_migrated:
        fail("""\
`build_mode = "xcode"` is currently not supported with Bazel 7+.
""")

    provider_outputs = output_files.merge(
        transitive_infos = infos,
    )

    inputs = input_files.merge(
        transitive_infos = infos,
    )
    focused_labels = {label: None for label in ctx.attr._focused_labels}
    unfocused_labels = {label: None for label in ctx.attr._unfocused_labels}
    replacement_labels = {
        r.id: r.label
        for r in depset(
            transitive = [info.replacement_labels for info in infos],
        ).to_list()
    }

    (
        targets,
        target_dtos,
        additional_bwx_generated,
        additional_bwb_outputs,
        focused_targets_extra_files,
        focused_targets_extra_folders,
        replacement_labels_by_label,
        configurations_map,
        lldb_contexts,
        xcode_generated_paths_file,
    ) = _process_targets(
        actions = actions,
        build_mode = build_mode,
        configuration = configuration,
        fail_for_invalid_extra_files_targets = (
            ctx.attr.fail_for_invalid_extra_files_targets
        ),
        focused_labels = focused_labels,
        include_swiftui_previews_scheme_targets = (
            build_mode == "bazel" and
            ctx.attr.adjust_schemes_for_swiftui_previews
        ),
        infos = infos,
        infos_per_xcode_configuration = infos_per_xcode_configuration,
        inputs = inputs,
        is_fixture = is_fixture,
        link_params_processor = ctx.executable._link_params_processor,
        name = name,
        owned_extra_files = ctx.attr._owned_extra_files,
        replacement_labels = replacement_labels,
        unfocused_labels = unfocused_labels,
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
        configurations_map = configurations_map,
        focused_labels = focused_labels,
        focused_targets_extra_files = focused_targets_extra_files,
        focused_targets_extra_folders = focused_targets_extra_folders,
        inputs = inputs,
        is_fixture = is_fixture,
        replacement_labels_by_label = replacement_labels_by_label,
        runner_build_file = ctx.attr.runner_build_file,
        unfocused_labels = unfocused_labels,
        unowned_extra_files = ctx.attr.unowned_extra_files,
    )
    xccurrentversion_files = _process_xccurrentversions(
        inputs = inputs,
        focused_labels = focused_labels,
        replacement_labels_by_label = replacement_labels_by_label,
        unfocused_labels = unfocused_labels,
    )
    target_ids_list = write_target_ids_list(
        actions = actions,
        name = name,
        target_ids = target_dtos.keys(),
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
        actions = actions,
        args = args,
        config = config,
        default_xcode_configuration = default_xcode_configuration,
        envs = envs,
        extra_files = extra_files,
        extra_folders = extra_folders,
        index_import = ctx.executable._index_import,
        infos = infos,
        is_fixture = is_fixture,
        minimum_xcode_version = minimum_xcode_version,
        name = name,
        post_build = ctx.attr.post_build,
        pre_build = ctx.attr.pre_build,
        project_name = project_name,
        project_options = ctx.attr.project_options,
        runner_label = ctx.attr.runner_label,
        scheme_autogeneration_mode = ctx.attr.scheme_autogeneration_mode,
        schemes_json = ctx.file.schemes_json,
        target_dtos = target_dtos,
        target_ids_list = target_ids_list,
        target_name_mode = ctx.attr.target_name_mode,
        xcode_configurations = xcode_configurations,
    )
    execution_root_file = write_execution_root_file(
        actions = actions,
        bin_dir_path = bin_dir_path,
        name = name,
    )
    xccurrentversions_file = _write_xccurrentversions(
        actions = actions,
        name = name,
        xccurrentversion_files = xccurrentversion_files,
        xccurrentversions_parser = (
            ctx.attr._xccurrentversions_parser[DefaultInfo].files_to_run
        ),
    )
    extension_point_identifiers_file = write_extension_point_identifiers_file(
        actions = actions,
        extension_infoplists = extension_infoplists,
        tool = (
            ctx.attr._extension_point_identifiers_parser[DefaultInfo].files_to_run
        ),
        name = name,
    )
    swift_debug_settings = _write_swift_debug_settings(
        actions = actions,
        lldb_contexts = lldb_contexts,
        name = name,
        swift_debug_settings_processor = (
            ctx.executable._swift_debug_settings_processor
        ),
        xcode_generated_paths_file = xcode_generated_paths_file,
    )

    if configurations_map:
        flags = " ".join([
            "-e \'s/{}/{}/g\'".format(configuration, replacement)
            for configuration, replacement in configurations_map.items()
        ])

        normalized_specs = [
            actions.declare_file(
                "{}-normalized/spec.{}.json".format(name, idx),
            )
            for idx, file in enumerate(spec_files)
        ]
        normalized_extensionpointidentifiers = actions.declare_file(
            "{}_normalized/extensionpointidentifiers_targetids".format(name),
        )
        normalized_swift_debug_settings = [
            actions.declare_file(
                "{}_normalized/{}-swift_debug_settings.py".format(
                    name,
                    xcode_configuration,
                ),
            )
            for xcode_configuration in lldb_contexts
        ]
        normalized_xccurrentversions = actions.declare_file(
            "{}_normalized/xccurrentversions".format(name),
        )

        unstable_files = (
            spec_files +
            swift_debug_settings +
            [extension_point_identifiers_file, xccurrentversions_file]
        )
        normalized_files = (
            normalized_specs +
            normalized_swift_debug_settings +
            [normalized_extensionpointidentifiers, normalized_xccurrentversions]
        )
        actions.run_shell(
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
        extension_point_identifiers_file = normalized_extensionpointidentifiers
        swift_debug_settings = normalized_swift_debug_settings
        xccurrentversions_file = normalized_xccurrentversions

    bazel_integration_files = (
        list(ctx.files._base_integration_files) +
        swift_debug_settings
    ) + [
        write_bazel_build_script(
            actions = actions,
            bazel_env = ctx.attr.bazel_env,
            bazel_path = ctx.attr.bazel_path,
            generator_label = ctx.label,
            target_ids_list = target_ids_list,
            template = ctx.file._bazel_build_script_template,
        ),
    ]
    if build_mode == "xcode":
        bazel_integration_files.append(
            write_create_xcode_overlay_script(
                actions = actions,
                generator_name = name,
                targets = targets,
                template = ctx.file._create_xcode_overlay_script_template,
            ),
        )
    else:
        bazel_integration_files.extend(ctx.files._bazel_integration_files)

    xcodeproj = _write_xcodeproj(
        actions = actions,
        build_mode = build_mode,
        colorize = colorize,
        execution_root_file = execution_root_file,
        extension_point_identifiers_file = extension_point_identifiers_file,
        generator = ctx.attr._generator[DefaultInfo].files_to_run,
        index_import = ctx.attr._index_import[DefaultInfo].files_to_run,
        install_path = install_path,
        is_fixture = is_fixture,
        name = name,
        spec_files = spec_files,
        workspace_directory = ctx.attr.workspace_directory,
        xccurrentversions_file = xccurrentversions_file,
    )
    installer = _write_installer(
        actions = actions,
        bazel_integration_files = bazel_integration_files,
        config = config,
        configurations_map = configurations_map,
        install_path = install_path,
        is_fixture = is_fixture,
        name = name,
        spec_files = spec_files,
        template = ctx.file._installer_template,
        xcodeproj = xcodeproj,
    )

    if build_mode == "xcode":
        input_files_output_groups = input_files.to_output_groups_fields(
            inputs = inputs,
            additional_bwx_generated = additional_bwx_generated,
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
            outputs = provider_outputs,
            additional_bwb_outputs = additional_bwb_outputs,
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

# buildifier: disable=function-docstring
def make_xcodeproj_rule(
        *,
        xcodeproj_aspect,
        focused_labels,
        is_fixture = False,
        owned_extra_files,
        target_transitions = None,
        unfocused_labels,
        xcodeproj_transition = None):
    attrs = {
        "adjust_schemes_for_swiftui_previews": attr.bool(
            mandatory = True,
        ),
        "bazel_env": attr.string_dict(
            mandatory = True,
        ),
        "bazel_path": attr.string(
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
        "generation_shard_count": attr.int(
            mandatory = True,
        ),
        "install_path": attr.string(
            mandatory = True,
        ),
        "ios_device_cpus": attr.string(
            mandatory = True,
        ),
        "ios_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "minimum_xcode_version": attr.string(
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
        "target_name_mode": attr.string(
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
        "tvos_device_cpus": attr.string(
            mandatory = True,
        ),
        "tvos_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "unowned_extra_files": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "watchos_device_cpus": attr.string(
            mandatory = True,
        ),
        "watchos_simulator_cpus": attr.string(
            mandatory = True,
        ),
        "workspace_directory": attr.string(
            mandatory = True,
        ),
        "xcode_configuration_map": attr.string_list_dict(
            mandatory = True,
        ),
        "xcschemes_json": attr.string(),
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
                "//xcodeproj/internal/templates:bazel_build.sh",
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
                "//xcodeproj/internal/templates:create_xcode_overlay.sh",
            ),
        ),
        "_extension_point_identifiers_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/extension_point_identifiers_parser"),
            executable = True,
        ),
        "_focused_labels": attr.string_list(default = focused_labels),
        "_generator": attr.label(
            cfg = "exec",
            default = Label("//tools/generators/legacy:universal_generator"),
            executable = True,
        ),
        "_index_import": attr.label(
            cfg = "exec",
            default = Label("@rules_xcodeproj_index_import//:index_import"),
            executable = True,
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal/templates:installer.sh"),
        ),
        "_is_fixture": attr.bool(default = is_fixture),
        "_link_params_processor": attr.label(
            cfg = "exec",
            default = Label("//tools/params_processors:link_params_processor"),
            executable = True,
        ),
        "_owned_extra_files": attr.label_keyed_string_dict(
            allow_files = True,
            default = owned_extra_files,
        ),
        "_swift_debug_settings_processor": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/params_processors:swift_debug_settings_processor",
            ),
            executable = True,
        ),
        "_unfocused_labels": attr.string_list(default = unfocused_labels),
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

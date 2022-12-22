"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
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
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
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
    if unfocused_targets or sets.length(unfocused_libraries) > 0:
        for xcode_target in focused_targets:
            transitive_focused_dependencies.append(
                xcode_target.transitive_dependencies,
            )
            if sets.contains(
                unfocused_libraries,
                xcode_target.product.file_path,
            ):
                automatic_unfocused_dependencies.append(xcode_target.id)

    transitive_dependencies = []
    if unfocused_targets:
        focused_dependencies = sets.make(
            depset(transitive = transitive_focused_dependencies).to_list(),
        )
        for xcode_target in unfocused_targets.values():
            automatic_unfocused_dependencies.append(xcode_target.id)
            if sets.contains(focused_dependencies, xcode_target.id):
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
    return ".".join(str(xcode_config.xcode_version()).split(".")[0:3])

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
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
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
        focused_targets_extra_files):
    extra_files = inputs.extra_files.to_list()

    # Add processed owned extra files
    extra_files.extend(focused_targets_extra_files)

    # Apply replacement labels
    extra_files = [
        (
            bazel_labels.normalize(
                replacement_labels_by_label.get(label, label),
            ),
            files,
        )
        for label, files in extra_files
    ]

    # Filter out unfocused labels
    has_focused_labels = sets.length(focused_labels) > 0
    extra_files = [
        file
        for label, files in extra_files
        for file in files
        if not label or not (
            sets.contains(unfocused_labels, label) or
            (has_focused_labels and not sets.contains(focused_labels, label))
        )
    ]

    # Add unowned extra files
    extra_files.append(parsed_file_path(ctx.build_file_path))
    for target in ctx.attr.unowned_extra_files:
        extra_files.extend([
            file_path(file)
            for file in target.files.to_list()
        ])

    extra_files = uniq(extra_files)

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
                is_folder = fp.is_folder,
                include_in_navigator = fp.include_in_navigator,
                force_group_creation = fp.force_group_creation,
            )
            for fp in extra_files
        ]
        extra_files = sorted(extra_files, key = lambda fp: fp.type + fp.path)

    return extra_files

def _process_targets(
        *,
        build_mode,
        is_fixture,
        configuration,
        focused_labels,
        unfocused_labels,
        replacement_labels,
        inputs,
        infos,
        owned_extra_files,
        include_swiftui_previews_scheme_targets):
    # TODO: Do this at the `top_level_targets` level, to allow marking as
    # required for BwX
    resource_bundle_xcode_targets = process_resource_bundles(
        bundles = inputs.resource_bundles.to_list(),
        resource_bundle_informations = depset(
            transitive = [info.resource_bundle_informations for info in infos],
        ).to_list(),
    )

    unprocessed_targets = {
        xcode_target.id: xcode_target
        for xcode_target in depset(
            resource_bundle_xcode_targets,
            transitive = [info.xcode_targets for info in infos],
        ).to_list()
    }

    configurations_map = {}
    if is_fixture:
        prefix, sep, _ = configuration.partition("-ST-")
        if sep:
            configurations_map[configuration] = "{}-STABLE-0".format(prefix)

        label_configurations = {}
        for xcode_target in unprocessed_targets.values():
            # Make it stable over labels
            label_configurations.setdefault(xcode_target.label, {})[xcode_target.configuration] = xcode_target

        configurations = {}
        for label_configs in label_configurations.values():
            for configuration in label_configs:
                configurations[configuration] = None

        for idx, configuration in enumerate(configurations):
            prefix, sep, _ = configuration.partition("-ST-")
            if sep:
                configurations_map[configuration] = "{}-STABLE-{}".format(prefix, idx + 1)

    replacement_labels_by_label = {
        unprocessed_targets[id].label: label
        for id, label in replacement_labels.items()
    }

    targets_labels = sets.make([
        bazel_labels.normalize(replacement_labels.get(t.id, t.label))
        for t in unprocessed_targets.values()
    ])

    invalid_focused_targets = sets.to_list(
        sets.difference(focused_labels, targets_labels),
    )
    if invalid_focused_targets:
        fail("""\
`focused_targets` contains target(s) that are not transitive dependencies of \
the targets listed in `top_level_targets`: {}

Are you using an `alias`? `focused_targets` requires labels of the actual \
targets.
""".format(invalid_focused_targets))

    unfocused_libraries = sets.make(inputs.unfocused_libraries.to_list())
    has_focused_labels = sets.length(focused_labels) > 0

    linker_products_map = {}
    transitive_focused_targets = []
    unfocused_targets = {}
    for xcode_target in unprocessed_targets.values():
        if build_mode == "bazel":
            product = xcode_target.product
            for file in product.framework_files.to_list():
                linker_products_map[build_setting_path(
                    file = file,
                    path = file.dirname,
                )] = build_setting_path(file = product.file)

        label = replacement_labels.get(
            xcode_target.id,
            xcode_target.label,
        )
        label_str = bazel_labels.normalize(label)
        if (sets.contains(unfocused_labels, label_str) or
            (has_focused_labels and
             not sets.contains(focused_labels, label_str))):
            unfocused_targets[xcode_target.id] = xcode_target
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
        label = replacement_labels.get(
            xcode_target.id,
            xcode_target.label,
        )
        label_str = bazel_labels.normalize(label)

        # Remove from unfocused (to support `xcode_required_targets`)
        unfocused_targets.pop(xcode_target.id, default = None)

        # Adjust `unfocused_labels` for `extra_files` logic later
        if sets.contains(unfocused_labels, label_str):
            sets.remove(unfocused_labels, label_str)

        infoplist = xcode_target.outputs.transitive_infoplists
        if infoplist:
            infoplists.setdefault(label, []).append(infoplist)

    potential_target_merges = depset(
        transitive = [info.potential_target_merges for info in infos],
    ).to_list()

    target_merge_dests = {}
    for merge in potential_target_merges:
        src_target = unprocessed_targets[merge.src.id]
        src_label = bazel_labels.normalize(src_target.label)
        dest_target = unprocessed_targets[merge.dest]
        dest_label = bazel_labels.normalize(dest_target.label)
        if (sets.contains(unfocused_labels, src_label) or
            sets.contains(unfocused_labels, dest_label)):
            continue
        target_merge_dests.setdefault(merge.dest, []).append(merge.src.id)

    for dest, src_ids in target_merge_dests.items():
        if len(src_ids) > 1:
            # We can only merge targets with a single library dependency
            continue
        dest_target = unprocessed_targets[dest]
        dest_label = bazel_labels.normalize(
            replacement_labels.get(dest, dest_target.label),
        )
        if not sets.contains(focused_labels, dest_label):
            continue
        src = src_ids[0]
        src_target = unprocessed_targets[src]
        src_label = bazel_labels.normalize(
            replacement_labels.get(src, src_target.label),
        )

        # Always include src of target merge if dest is included
        focused_targets[src] = src_target

        # Remove from unfocused (to support `xcode_required_targets`)
        unfocused_targets.pop(src, default = None)

        # Adjust `unfocused_labels` for `extra_files` logic later
        if sets.contains(unfocused_labels, src_label):
            sets.remove(unfocused_labels, src_label)

    unfocused_dependencies = _calculate_unfocused_dependencies(
        build_mode = build_mode,
        targets = unprocessed_targets,
        focused_targets = focused_targets.values(),
        unfocused_libraries = unfocused_libraries,
        unfocused_targets = unfocused_targets,
    )

    focused_targets_extra_files = []

    has_automatic_unfocused_targets = sets.length(unfocused_libraries) > 0
    has_unfocused_targets = bool(unfocused_targets)
    include_lldb_context = (
        has_unfocused_targets or
        has_automatic_unfocused_targets or
        build_mode != "xcode"
    )

    additional_generated = {}
    additional_outputs = {}
    target_transitive_dependencies = {}
    for xcode_target in focused_targets.values():
        transitive_dependencies = {
            id: None
            for id in xcode_target.transitive_dependencies.to_list()
        }
        target_transitive_dependencies[xcode_target.id] = (
            transitive_dependencies
        )

        additional_compiling_files = []
        additional_indexstores_files = []
        additional_linking_files = []
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

        compiling_output_group_name = (
            xcode_target.inputs.compiling_output_group_name
        )
        indexstores_output_group_name = (
            xcode_target.inputs.indexstores_output_group_name
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

        label = replacement_labels.get(
            xcode_target.id,
            xcode_target.label,
        )
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

        linking_output_group_name = (
            xcode_target.inputs.linking_output_group_name
        )
        if linking_output_group_name:
            set_if_true(
                additional_generated,
                linking_output_group_name,
                additional_linking_files,
            )

        invalid_extra_files_targets = sets.to_list(
            sets.difference(
                sets.make(owned_extra_files.values()),
                targets_labels,
            ),
        )
        if invalid_extra_files_targets:
            fail("""\
Are you using an `alias`? `associated_extra_files` requires labels of the \
actual targets: {}
""".format(invalid_extra_files_targets))

        label_str = bazel_labels.normalize(label)
        for file, owner_label in owned_extra_files.items():
            if label_str == owner_label:
                for f in file.files.to_list():
                    focused_targets_extra_files.append((label, [file_path(f)]))

    # Filter `target_merge_dests` after processing focused targets
    if has_unfocused_targets:
        for dest, src_ids in target_merge_dests.items():
            if dest not in focused_targets:
                target_merge_dests.pop(dest)
                continue
            new_srcs_ids = [
                id
                for id in src_ids
                if id in focused_targets
            ]
            if not new_srcs_ids:
                target_merge_dests.pop(dest)
                continue
            target_merge_dests[dest] = new_srcs_ids

    target_merges = {}
    target_merge_srcs_by_label = {}
    for dest, src_ids in target_merge_dests.items():
        if len(src_ids) > 1:
            # We can only merge targets with a single library dependency
            continue
        src = src_ids[0]
        src_target = focused_targets[src]
        target_merges.setdefault(src, []).append(dest)
        target_merge_srcs_by_label.setdefault(src_target.label, []).append(src)

    non_mergable_targets = sets.make()
    non_terminal_dests = {}
    for src, dests in target_merges.items():
        src_target = focused_targets[src]

        if not src_target.is_swift:
            # Only swiftmodule search paths are an issue for target merging.
            # If the target isn't Swift, merge away!
            continue

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
                sets.insert(non_mergable_targets, file_path(library))

    for src in target_merges.keys():
        src_target = focused_targets[src]
        if (len(non_terminal_dests.get(src, [])) > 1 or
            sets.contains(non_mergable_targets, src_target.product.file_path)):
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

    xcode_generated_paths = {}
    for xcode_target in focused_targets.values():
        if build_mode != "xcode" or xcode_target.id in unfocused_dependencies:
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
        for file in product.additional_product_files:
            xcode_generated_paths[file.path] = xcode_product_path
        for file in product.framework_files.to_list():
            xcode_generated_paths[file.path] = (
                xcode_product_path
            )

        swiftmodule = xcode_target.outputs.swiftmodule
        if swiftmodule:
            swiftmodule_basename = swiftmodule.basename
            if product.type == "com.apple.product-type.framework":
                path = product_file.path + "/Modules/" + swiftmodule_basename
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

    target_dtos = {}
    for xcode_target in focused_targets.values():
        transitive_dependencies = (
            target_transitive_dependencies[xcode_target.id]
        )

        if include_swiftui_previews_scheme_targets:
            additional_scheme_target_ids = _calculate_swiftui_preview_targets(
                xcode_target = xcode_target,
                transitive_dependencies = transitive_dependencies,
                targets = focused_targets,
            )
        else:
            additional_scheme_target_ids = None

        dto, replaced_dependencies = xcode_targets.to_dto(
            xcode_target = xcode_target,
            is_fixture = is_fixture,
            additional_scheme_target_ids = additional_scheme_target_ids,
            build_mode = build_mode,
            include_lldb_context = include_lldb_context,
            is_unfocused_dependency = xcode_target.id in unfocused_dependencies,
            linker_products_map = linker_products_map,
            should_include_outputs = should_include_outputs(build_mode),
            unfocused_targets = unfocused_targets,
            target_merges = target_merges,
            xcode_generated_paths = xcode_generated_paths,
        )
        target_dtos[xcode_target.id] = dto

        for id in replaced_dependencies:
            if id in transitive_dependencies:
                continue

            # The replaced dependency is not a transitive dependency, so we
            # need to add its merge in its output groups

            compiling_output_group_name = (
                xcode_target.inputs.compiling_output_group_name
            )
            indexstores_output_group_name = (
                xcode_target.inputs.indexstores_output_group_name
            )
            linking_output_group_name = (
                xcode_target.inputs.linking_output_group_name
            )

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
                set_if_true(
                    additional_generated,
                    compiling_output_group_name,
                    additional_compiling_files,
                )
            if (indexstores_output_group_name and
                dep_indexstores_output_group_name):
                additional_indexstores_files = additional_generated.get(
                    dep_indexstores_output_group_name,
                    [],
                )
                additional_indexstores_files.append(
                    dep_target.inputs.indexstores,
                )
                set_if_true(
                    additional_generated,
                    indexstores_output_group_name,
                    additional_indexstores_files,
                )
            if linking_output_group_name and dep_linking_output_group_name:
                additional_linking_files = additional_generated.get(
                    dep_linking_output_group_name,
                    [],
                )
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
        has_unfocused_targets,
        focused_targets_extra_files,
        replacement_labels_by_label,
        configurations_map,
    )

def should_include_outputs(build_mode):
    return build_mode != "bazel_via_proxy"

# Actions

def _write_spec(
        *,
        config,
        configuration,
        ctx,
        is_fixture,
        envs,
        project_name,
        target_dtos,
        targets,
        has_unfocused_targets,
        replacement_labels,
        inputs,
        extra_files,
        infos,
        minimum_xcode_version):
    # `target_hosts`
    hosted_targets = depset(
        transitive = [info.hosted_targets for info in infos],
    ).to_list()
    target_hosts = {}
    for s in hosted_targets:
        if s.host not in targets or s.hosted not in targets:
            continue
        target_hosts.setdefault(s.hosted, []).append(s.host)

    # `custom_xcode_schemes`
    if ctx.attr.schemes_json == "":
        custom_xcode_schemes_json = "[]"
    else:
        custom_xcode_schemes_json = ctx.attr.schemes_json

    # Have to do this dance because attr.string's default is ""
    post_build_script = (
        json.encode(ctx.attr.post_build) if ctx.attr.post_build else "null"
    )
    pre_build_script = (
        json.encode(ctx.attr.pre_build) if ctx.attr.pre_build else "null"
    )

    # TODO: Strip fat frameworks instead of setting `VALIDATE_WORKSPACE`
    project_spec_json = """\
{{\
"bazel_config":"{bazel_config}",\
"bazel_workspace_name":"{bazel_workspace_name}",\
"build_settings":{{\
"ALWAYS_SEARCH_USER_PATHS":false,\
"BAZEL_PATH":"{bazel_path}",\
"CLANG_ENABLE_OBJC_ARC":true,\
"CLANG_MODULES_AUTOLINK":false,\
"COPY_PHASE_STRIP":false,\
"ONLY_ACTIVE_ARCH":true,\
"USE_HEADERMAP":false,\
"VALIDATE_WORKSPACE":false\
}},\
"configuration":"{configuration}",\
"custom_xcode_schemes":{custom_xcode_schemes},\
"envs": {envs},\
"extra_files":{extra_files},\
"force_bazel_dependencies":{force_bazel_dependencies},\
"generator_label":"{generator_label}",\
"index_import":"{index_import}",\
"minimum_xcode_version":"{minimum_xcode_version}",\
"name":"{name}",\
"post_build_script":{post_build_script},\
"pre_build_script":{pre_build_script},\
"replacement_labels":{replacement_labels},\
"runner_label":"{runner_label}",\
"scheme_autogeneration_mode":"{scheme_autogeneration_mode}",\
"target_hosts":{target_hosts}
}}
""".format(
        bazel_config = config,
        bazel_path = ctx.attr.bazel_path,
        bazel_workspace_name = ctx.workspace_name,
        configuration = configuration,
        custom_xcode_schemes = custom_xcode_schemes_json,
        extra_files = json.encode(
            [file_path_to_dto(file) for file in extra_files],
        ),
        force_bazel_dependencies = json.encode(
            has_unfocused_targets or inputs.has_generated_files,
        ),
        generator_label = ctx.label,
        index_import = "fixture-index-import-path" if is_fixture else build_setting_path(
            file = ctx.executable._index_import,
        ),
        minimum_xcode_version = minimum_xcode_version,
        name = project_name,
        post_build_script = post_build_script,
        pre_build_script = pre_build_script,
        replacement_labels = json.encode(
            flattened_key_values.to_list(
                {
                    id: bazel_labels.normalize(label)
                    for id, label in replacement_labels.items()
                    if id in targets
                },
                sort = is_fixture,
            ),
        ),
        runner_label = ctx.attr.runner_label,
        scheme_autogeneration_mode = ctx.attr.scheme_autogeneration_mode,
        target_hosts = json.encode(
            flattened_key_values.to_list(target_hosts, sort = is_fixture),
        ),
        envs = json.encode(
            flattened_key_values.to_list(envs, sort = is_fixture),
        ),
    )

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

    return [project_spec_output] + target_shards

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

def _write_root_dirs(*, ctx):
    if ctx.label.workspace_root:
        fail("""\
Can't generate a project into an external repository: {}\
""".format(ctx.label.workspace_root))

    output = ctx.actions.declare_file("{}_root_dirs".format(ctx.attr.name))

    ctx.actions.run_shell(
        outputs = [output],
        command = """\
project_full="{project_full}"
remove_suffix="/${{project_full#*/*}}"
workspace_root_element="${{project_full%$remove_suffix}}"

execroot_workspace_dir="$(perl -MCwd -e 'print Cwd::abs_path' "{project_full}";)"
resolved_workspace_root_element="$(readlink $execroot_workspace_dir/$workspace_root_element)"
workspace_dir="${{resolved_workspace_root_element%/*}}"

bazel_out_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{bazel_out_full}";)"
bazel_out_full_path="${{bazel_out_full_path#/private}}"
bazel_out="${{bazel_out_full_path%/{bazel_out_full}}}/bazel-out"
external="${{bazel_out%/*/*/*}}/external"

echo "$workspace_dir" > "{out_full}"
echo "${{external#$workspace_dir/}}" >> "{out_full}"
echo "${{bazel_out#$workspace_dir/}}" >> "{out_full}"
""".format(
            project_full = ctx.build_file_path,
            bazel_out_full = ctx.bin_dir.path,
            out_full = output.path,
        ),
        mnemonic = "CalculateXcodeProjRootDirs",
        # This has to run locally
        execution_requirements = {
            "local": "1",
            "no-remote": "1",
            "no-sandbox": "1",
        },
    )

    return output

def _write_xcodeproj(
        *,
        ctx,
        project_name,
        spec_files,
        root_dirs_file,
        xccurrentversions_file,
        extensionpointidentifiers_file,
        build_mode,
        is_fixture):
    xcodeproj = ctx.actions.declare_directory(
        "{}.xcodeproj".format(ctx.attr.name),
    )

    install_path = paths.join(
        paths.dirname(xcodeproj.short_path),
        "{}.xcodeproj".format(project_name),
    )

    args = ctx.actions.args()
    args.add(root_dirs_file.path)
    args.add(xccurrentversions_file.path)
    args.add(extensionpointidentifiers_file.path)
    args.add(xcodeproj.path)
    args.add(install_path)
    args.add(build_mode)
    args.add("1" if is_fixture else "0")
    args.add_all(spec_files)

    ctx.actions.run(
        executable = ctx.attr._generator[DefaultInfo].files_to_run,
        mnemonic = "GenerateXcodeProj",
        arguments = [args],
        inputs = spec_files + [
            root_dirs_file,
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

    return xcodeproj, install_path

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

def _device_transition_impl(_settings, attr):
    outputs = {
        "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
        "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
        "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
    }

    return outputs

def _simulator_transition_impl(settings, attr):
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

    outputs = {
        "//command_line_option:ios_multi_cpus": ios_cpus,
        "//command_line_option:tvos_cpus": tvos_cpus,
        "//command_line_option:watchos_cpus": watchos_cpus,
    }

    return outputs

_TRANSITION_ATTR = {
    "inputs": [
        # Simulator and Device support
        "//command_line_option:cpu",
    ],
    "outputs": [
        # Simulator and Device support
        "//command_line_option:ios_multi_cpus",
        "//command_line_option:tvos_cpus",
        "//command_line_option:watchos_cpus",
    ],
}

_simulator_transition = transition(
    implementation = _simulator_transition_impl,
    **_TRANSITION_ATTR
)

_device_transition = transition(
    implementation = _device_transition_impl,
    **_TRANSITION_ATTR
)

# Rule

def _xcodeproj_impl(ctx):
    build_mode = ctx.attr.build_mode
    config = ctx.attr.config
    is_fixture = ctx.attr._is_fixture
    project_name = ctx.attr.project_name
    infos = [
        _process_dep(dep)
        for dep in (
            ctx.attr.top_level_simulator_targets +
            ctx.attr.top_level_device_targets
        )
    ]
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
    focused_labels = sets.make(ctx.attr.focused_targets)
    unfocused_labels = sets.make(ctx.attr.unfocused_targets)
    replacement_labels = {
        r.id: r.label
        for r in depset(
            transitive = [info.replacement_labels for info in infos],
        ).to_list()
    }
    envs = {
        s.id: s.env
        for s in depset(
            transitive = [info.envs for info in infos],
        ).to_list()
        if s.env
    }

    (
        targets,
        target_dtos,
        additional_generated,
        additional_outputs,
        has_unfocused_targets,
        focused_targets_extra_files,
        replacement_labels_by_label,
        configurations_map,
    ) = _process_targets(
        build_mode = build_mode,
        is_fixture = is_fixture,
        configuration = configuration,
        focused_labels = focused_labels,
        unfocused_labels = unfocused_labels,
        replacement_labels = replacement_labels,
        inputs = inputs,
        infos = infos,
        owned_extra_files = ctx.attr.owned_extra_files,
        include_swiftui_previews_scheme_targets = (
            build_mode == "bazel" and
            ctx.attr.adjust_schemes_for_swiftui_previews
        ),
    )

    bazel_integration_files = list(ctx.files._base_integration_files)
    if build_mode == "xcode":
        bazel_integration_files.append(
            _write_create_xcode_overlay_script(ctx = ctx, targets = targets),
        )
    else:
        bazel_integration_files.extend(ctx.files._bazel_integration_files)

    extra_files = _process_extra_files(
        ctx = ctx,
        configurations_map = configurations_map,
        focused_labels = focused_labels,
        is_fixture = is_fixture,
        unfocused_labels = unfocused_labels,
        replacement_labels_by_label = replacement_labels_by_label,
        inputs = inputs,
        focused_targets_extra_files = focused_targets_extra_files,
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
        is_fixture = is_fixture,
        project_name = project_name,
        config = config,
        configuration = configuration,
        envs = envs,
        targets = targets,
        target_dtos = target_dtos,
        has_unfocused_targets = has_unfocused_targets,
        replacement_labels = replacement_labels,
        inputs = inputs,
        extra_files = extra_files,
        infos = infos,
        minimum_xcode_version = minimum_xcode_version,
    )
    root_dirs_file = _write_root_dirs(ctx = ctx)
    xccurrentversions_file = _write_xccurrentversions(
        ctx = ctx,
        xccurrentversion_files = inputs.xccurrentversions.to_list(),
    )
    extensionpointidentifiers_file = _write_extensionpointidentifiers(
        ctx = ctx,
        extension_infoplists = extension_infoplists,
    )

    if configurations_map:
        flags = " ".join([
            "-e \'s/{}/{}/g\'".format(configuration, replacement)
            for configuration, replacement in configurations_map.items()
        ])

        normalized_specs = [
            ctx.actions.declare_file(
                "{}-normalized_spec.{}.json".format(ctx.attr.name, idx),
            )
            for idx, file in enumerate(spec_files)
        ]
        normalized_extensionpointidentifiers = ctx.actions.declare_file(
            "{}_normalized_extensionpointidentifiers_targetids".format(
                ctx.attr.name,
            ),
        )

        unstable_files = spec_files + [extensionpointidentifiers_file]
        normalized_files = normalized_specs + [normalized_extensionpointidentifiers]
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
                outputs = shell.array_literal([f.path for f in normalized_files]),
                flags = flags,
            ),
        )

        spec_files = normalized_specs
        extensionpointidentifiers_file = normalized_extensionpointidentifiers

    xcodeproj, install_path = _write_xcodeproj(
        ctx = ctx,
        project_name = project_name,
        spec_files = spec_files,
        root_dirs_file = root_dirs_file,
        xccurrentversions_file = xccurrentversions_file,
        extensionpointidentifiers_file = extensionpointidentifiers_file,
        build_mode = build_mode,
        is_fixture = is_fixture,
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
        xcodeproj_transition = None):
    if build_mode == "bazel":
        xcodeproj_aspect = bwb_xcodeproj_aspect
    else:
        xcodeproj_aspect = bwx_xcodeproj_aspect

    attrs = {
        "adjust_schemes_for_swiftui_previews": attr.bool(
            default = False,
            doc = """\
Whether to adjust schemes in BwB mode to explicitly include transitive
dependencies that are able to run SwiftUI Previews. For example, this changes a
scheme for an single application target to also include any app clip, app
extension, framework, or watchOS app dependencies.
""",
            mandatory = True,
        ),
        "bazel_path": attr.string(
            doc = """\
The path to the `bazel` binary or wrapper script. If the path is relative it
will be resolved using the `PATH` environment variable (which is set to
`/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` in Xcode). If
you wan to specify a path to a workspace-relative binary, you must prepend the
path with `./` (e.g. `"./bazelw"`).
""",
            mandatory = True,
        ),
        "build_mode": attr.string(
            doc = """\
The build mode the generated project should use.

If this is set to `"xcode"`, the project will use the Xcode build system to
build targets. Generated files and unfocused targets (see the `focused_targets`
and `unfocused_targets` attributes) will be built with Bazel.

If this is set to `"bazel"`, the project will use Bazel to build targets, inside
of Xcode. The Xcode build system still unavoidably orchestrates some things at a
high level.
""",
            mandatory = True,
            values = ["xcode", "bazel"],
        ),
        "config": attr.string(
            mandatory = True,
        ),
        "focused_targets": attr.string_list(
            doc = """\
A `list` of target labels as `string` values. If specified, only these targets
will be included in the generated project; all other targets will be excluded,
as if they were listed explicitly in the `unfocused_targets` attribute. The
labels must match transitive dependencies of the targets specified in the
`top_level_targets` attribute.
""",
            default = [],
        ),
        "minimum_xcode_version": attr.string(
            doc = """\
The minimum Xcode version that the generated project supports. Newer Xcode
versions can support newer features, so setting this to the highest value you
can will enable the most features. The value is the dot separated version
number (e.g. "13.4.1", "14", "14.1"). Defaults to whichever version of Xcode
that Bazel uses during project generation.
        """,
        ),
        "owned_extra_files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = """\
An optional dictionary of files to be added to the project. The key represents
the file and the value is the label of the target it should be associated with.
These files won't be added to the project if the target is unfocused.
""",
        ),
        "post_build": attr.string(
            doc = """\
The text of a script that will be run after the build. For example:
`./post-build.sh`, `"$PROJECT_DIR/post-build.sh"`.
""",
        ),
        "pre_build": attr.string(
            doc = """\
The text of a script that will be run before the build. For example:
`./pre-build.sh`, `"$PROJECT_DIR/pre-build.sh"`.
""",
        ),
        "project_name": attr.string(
            doc = "The name to use for the `.xcodeproj` file.",
            mandatory = True,
        ),
        "runner_label": attr.string(doc = "The label of the runner target."),
        "scheme_autogeneration_mode": attr.string(
            doc = "Specifies how Xcode schemes are automatically generated.",
            default = "auto",
            values = ["auto", "none", "all"],
        ),
        "schemes_json": attr.string(
            doc = """\
A JSON string representing a list of Xcode schemes to create.
""",
        ),
        "top_level_device_targets": attr.label_list(
            doc = """\
A list of top-level targets that should have Xcode targets, with device
target environments, generated for them and their transitive dependencies.

Only targets that you want to build for device and be code signed should be
listed here.

If a target listed here has different device and simulator deployment targets
(e.g. iOS targets), then the Xcode target generated will target devices,
otherwise it will be unaffected (i.e. macOS targets). To have a simulator
deployment target, list the target in the `top_level_simulator_targets`
attribute instead. Listing a target both here and in the
`top_level_simulator_targets` attribute will result in a single Xcode target
that can be built for both device and simulator. Targets that don't have
different device and simulator deployment targets (i.e. macOS targets) should
only be listed in one of `top_level_device_targets` or
`top_level_simulator_targets`, or they will appear as two separate but similar
Xcode targets.
""",
            cfg = _device_transition,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "top_level_simulator_targets": attr.label_list(
            doc = """\
A list of top-level targets that should have Xcode targets, with simulator
target environments, generated for them and their transitive dependencies.

If a target listed here has different device and simulator deployment targets
(e.g. iOS targets), then the Xcode target generated will target the simulator,
otherwise it will be unaffected (i.e. macOS targets). To have a device
deployment target, list the target in the `top_level_device_targets` attribute
instead. Listing a target both here and in the `top_level_device_targets`
attribute will result in a single Xcode target that can be built for both device
and simulator. Targets that don't have different device and simulator deployment
targets (i.e. macOS targets) should only be listed in one of
`top_level_device_targets` or `top_level_simulator_targets`, or they will appear
as two separate but similar Xcode targets.
""",
            cfg = _simulator_transition,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "unfocused_targets": attr.string_list(
            doc = """\
A `list` of target labels as `string` values. Any targets in the transitive
dependencies of the targets specified in the `top_level_targets` attribute with
a matching label will be excluded from the generated project. This overrides any
targets specified in the `focused_targets` attribute.
""",
            default = [],
        ),
        "unowned_extra_files": attr.label_list(
            allow_files = True,
            doc = """\
An optional list of files to be added to the project but not associated with any
targets.
""",
        ),
        "ios_device_cpus": attr.string(
            doc = """\
The value to use for `--ios_multi_cpus` when building the transitive
dependencies of the targets specified in the `top_level_device_targets`
attribute.

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_device_targets` attribute, even if they aren't iOS targets.
""",
            mandatory = True,
        ),
        "ios_simulator_cpus": attr.string(
            doc = """\
The value to use for `--ios_multi_cpus` when building the transitive
dependencies of the targets specified in the `top_level_simulator_targets`
attribute.

If no value is specified, it defaults to the simulator cpu that goes with
`--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_simulator_targets` attribute, even if they aren't iOS targets.
""",
        ),
        "tvos_device_cpus": attr.string(
            doc = """\
The value to use for `--tvos_cpus` when building the transitive dependencies of
the targets specified in the `top_level_device_targets` attribute.

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_device_targets` attribute, even if they aren't tvOS targets.
""",
            mandatory = True,
        ),
        "tvos_simulator_cpus": attr.string(
            doc = """\
The value to use for `--tvos_cpus` when building the transitive dependencies of
the targets specified in the `top_level_simulator_targets` attribute.

If no value is specified, it defaults to the simulator cpu that goes with
`--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_simulator_targets` attribute, even if they aren't tvOS targets.
""",
        ),
        "watchos_device_cpus": attr.string(
            doc = """\
The value to use for `--watchos_cpus` when building the transitive dependencies
of the targets specified in the `top_level_device_targets` attribute.

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_device_targets` attribute, even if they aren't watchOS targets.
""",
            mandatory = True,
        ),
        "watchos_simulator_cpus": attr.string(
            doc = """\
The value to use for `--watchos_cpus` when building the transitive dependencies
of the targets specified in the `top_level_simulator_targets` attribute.

If no value is specified, it defaults to the simulator cpu that goes with
`--host_cpu` (i.e. `arm64` on Apple Silicon and `x86_64` on Intel).

**Warning:** Changing this value will affect the Starlark transition hash of all
transitive dependencies of the targets specified in the
`top_level_simulator_targets` attribute, even if they aren't watchOS targets.
""",
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

bwx_xcodeproj = make_xcodeproj_rule(build_mode = "xcode")
bwb_xcodeproj = make_xcodeproj_rule(build_mode = "bazel")

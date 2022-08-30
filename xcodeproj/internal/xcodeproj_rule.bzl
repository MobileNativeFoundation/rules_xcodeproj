"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":collections.bzl", "set_if_true", "uniq")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "file_path", "file_path_to_dto", "parsed_file_path")
load(":flattened_key_values.bzl", "flattened_key_values")
load(":input_files.bzl", "input_files")
load(":output_files.bzl", "output_files")
load(":providers.bzl", "XcodeProjInfo")
load(":resource_target.bzl", "process_resource_bundles")
load(":xcode_targets.bzl", "xcode_targets")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")

# Utility

def _calculate_unfocused_dependencies(
        *,
        build_mode,
        targets,
        unfocused_targets):
    if not unfocused_targets or build_mode != "xcode":
        return sets.make()

    focused_dependencies = sets.make(
        depset(
            transitive = [
                xcode_target.transitive_dependencies
                for xcode_target in targets
            ],
        ).to_list(),
    )
    important_unfocused_target_ids = sets.intersection(
        focused_dependencies,
        sets.make(unfocused_targets.keys()),
    )

    transitive_dependencies = []
    for xcode_target in unfocused_targets.values():
        if sets.contains(important_unfocused_target_ids, xcode_target.id):
            transitive_dependencies.append(
                xcode_target.transitive_dependencies,
            )

    return sets.make(
        depset(
            transitive = transitive_dependencies,
        ).to_list(),
    )

def _process_targets(
        *,
        build_mode,
        focused_labels,
        unfocused_labels,
        inputs,
        infos):
    resource_bundle_xcode_targets = process_resource_bundles(
        bundles = inputs.resource_bundles.to_list(),
        resource_bundle_informations = depset(
            transitive = [info.resource_bundle_informations for info in infos],
        ).to_list(),
    )

    targets_list = depset(
        resource_bundle_xcode_targets,
        transitive = [info.xcode_targets for info in infos],
    ).to_list()
    targets_labels = sets.make([str(t.label) for t in targets_list])

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

    actual_targets = []
    unfocused_targets = {}
    infoplists = {}
    for xcode_target in targets_list:
        label_str = str(xcode_target.label)
        if (sets.contains(unfocused_labels, label_str) or
            (has_focused_labels and
             not sets.contains(focused_labels, label_str))):
            unfocused_targets[xcode_target.id] = xcode_target
            continue

        actual_targets.append(xcode_target)

        infoplist = xcode_target.infoplist
        if infoplist:
            infoplists.setdefault(xcode_target.label, []).append(infoplist)

    unfocused_dependencies = _calculate_unfocused_dependencies(
        build_mode = build_mode,
        targets = actual_targets,
        unfocused_targets = unfocused_targets,
    )

    has_unfocused_libraries = sets.length(unfocused_libraries) > 0
    has_unfocused_targets = bool(unfocused_targets)

    targets = {}
    additional_generated = {}
    additional_outputs = {}
    for xcode_target in actual_targets:
        additional_compiling_files = []
        additional_linking_files = []
        for dependency in xcode_target.transitive_dependencies.to_list():
            unfocused_dependency = unfocused_targets.get(dependency)
            if not unfocused_dependency:
                continue
            unfocused_compiling_files = (
                unfocused_dependency.inputs.unfocused_generated_compiling
            )
            unfocused_linking_files = (
                unfocused_dependency.inputs.unfocused_generated_linking
            )
            if unfocused_compiling_files:
                additional_compiling_files.append(
                    depset(unfocused_compiling_files),
                )
            if additional_linking_files:
                additional_compiling_files.append(
                    depset(unfocused_linking_files),
                )

        coompiling_output_group_name = (
            xcode_target.inputs.compiling_output_group_name
        )
        if coompiling_output_group_name:
            set_if_true(
                additional_generated,
                coompiling_output_group_name,
                additional_compiling_files,
            )

        target_infoplists = infoplists.get(xcode_target.label)
        if target_infoplists:
            infoplists_depset = depset(target_infoplists)
            additional_linking_files.append(infoplists_depset)
            products_output_group_name = (
                xcode_target.outputs.products_output_group_name
            )
            if products_output_group_name:
                additional_outputs[products_output_group_name] = (
                    [infoplists_depset]
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

        is_unfocused_dependency = (
            sets.contains(
                unfocused_dependencies,
                xcode_target.id,
            ) or sets.contains(
                unfocused_libraries,
                xcode_target.product.path,
            )
        )

        targets[xcode_target.id] = xcode_targets.to_dto(
            xcode_target = xcode_target,
            include_lldb_context = (
                has_unfocused_targets or
                has_unfocused_libraries or
                build_mode != "xcode"
            ),
            is_unfocused_dependency = is_unfocused_dependency,
            unfocused_targets = unfocused_targets,
        )

    return (targets, additional_generated, additional_outputs)

# Actions

def _write_json_spec(
        *,
        ctx,
        project_name,
        configuration,
        targets,
        has_focused_targets,
        inputs,
        infos):
    # `replacement_labels`
    replacement_labels = {
        r.id: str(r.label)
        for r in depset(
            transitive = [info.replacement_labels for info in infos],
        ).to_list()
        if r.id in targets
    }

    # `target_merges`
    potential_target_merges = depset(
        transitive = [info.potential_target_merges for info in infos],
    ).to_list()

    target_merge_dests = {}
    for merge in potential_target_merges:
        if merge.src.id not in targets or merge.dest not in targets:
            continue
        target_merge_dests.setdefault(merge.dest, []).append(merge.src.id)

    target_merges = {}
    for dest, src_ids in target_merge_dests.items():
        if len(src_ids) > 1:
            # We can only merge targets with a single library dependency
            continue
        target_merges.setdefault(src_ids[0], []).append(dest)

    # `target_hosts`
    hosted_targets = depset(
        transitive = [info.hosted_targets for info in infos],
    ).to_list()
    target_hosts = {}
    for s in hosted_targets:
        if s.host not in targets or s.hosted not in targets:
            continue
        target_hosts.setdefault(s.hosted, []).append(s.host)

    # `extra_files`
    extra_files = inputs.extra_files.to_list()
    extra_files.append((None, [parsed_file_path(ctx.build_file_path)]))
    extra_files = [
        file
        for id, files in extra_files
        for file in files
        if not id or id in targets
    ]
    extra_files = uniq(extra_files)
    extra_files_dto = [file_path_to_dto(file) for file in extra_files]

    # `custom_xcode_schemes`
    if ctx.attr.schemes_json == "":
        custom_xcode_schemes_json = "[]"
    else:
        custom_xcode_schemes_json = ctx.attr.schemes_json

    # TODO: Strip fat frameworks instead of setting `VALIDATE_WORKSPACE`
    spec_json = """\
{{\
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
"extra_files":{extra_files},\
"force_bazel_dependencies":{force_bazel_dependencies},\
"label":"{label}",\
"name":"{name}",\
"replacement_labels":{replacement_labels},\
"scheme_autogeneration_mode":"{scheme_autogeneration_mode}",\
"target_hosts":{target_hosts},\
"target_merges":{target_merges},\
"targets":{targets}\
}}
""".format(
        bazel_path = ctx.attr.bazel_path,
        bazel_workspace_name = ctx.workspace_name,
        configuration = configuration,
        custom_xcode_schemes = custom_xcode_schemes_json,
        extra_files = json.encode(extra_files_dto),
        force_bazel_dependencies = json.encode(
            has_focused_targets or inputs.has_generated_files,
        ),
        label = ctx.label,
        name = project_name,
        replacement_labels = json.encode(
            flattened_key_values.to_list(replacement_labels),
        ),
        scheme_autogeneration_mode = ctx.attr.scheme_autogeneration_mode,
        target_hosts = json.encode(flattened_key_values.to_list(target_hosts)),
        target_merges = json.encode(
            flattened_key_values.to_list(target_merges),
        ),
        targets = json.encode(flattened_key_values.to_list(targets)),
    )

    output = ctx.actions.declare_file("{}_spec.json".format(ctx.attr.name))
    ctx.actions.write(output, spec_json)

    return output

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

def _write_extensionpointidentifiers(
        *,
        ctx,
        extension_infoplists,
        focused_labels,
        unfocused_labels):
    has_focused_labels = sets.length(focused_labels) > 0
    if sets.length(unfocused_labels):
        extension_infoplists = [
            s
            for s in extension_infoplists
            if not sets.contains(unfocused_labels, s.id)
        ]
    if has_focused_labels:
        extension_infoplists = [
            s
            for s in extension_infoplists
            if sets.contains(focused_labels, s.id)
        ]

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

def _write_root_dirs(*, ctx):
    output = ctx.actions.declare_file("{}_root_dirs".format(ctx.attr.name))

    ctx.actions.run_shell(
        outputs = [output],
        command = """\
project_full="{project_full}"
remove_suffix="/${{project_full#*/*}}"
workspace_root_element="${{project_full%$remove_suffix}}"

execroot_workspace_dir="$(perl -MCwd -e 'print Cwd::abs_path' "{project_full}";)"
workspace_root_element="$(readlink $execroot_workspace_dir/$workspace_root_element)"
workspace_dir="${{workspace_root_element%/*}}"

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
        spec_file,
        root_dirs_file,
        bazel_integration_files,
        xccurrentversions_file,
        extensionpointidentifiers_file,
        build_mode):
    xcodeproj = ctx.actions.declare_directory(
        "{}.xcodeproj".format(ctx.attr.name),
    )

    install_path = ctx.attr._install_path[BuildSettingInfo].value
    if not install_path:
        install_path = paths.join(
            paths.dirname(xcodeproj.short_path),
            "{}.xcodeproj".format(project_name),
        )

    args = ctx.actions.args()
    args.add(spec_file.path)
    args.add(root_dirs_file.path)
    args.add(xccurrentversions_file.path)
    args.add(extensionpointidentifiers_file.path)
    args.add(bazel_integration_files[0].dirname)
    args.add(xcodeproj.path)
    args.add(install_path)
    args.add(build_mode)

    ctx.actions.run(
        executable = ctx.attr._generator[DefaultInfo].files_to_run,
        mnemonic = "GenerateXcodeProj",
        arguments = [args],
        inputs = [
            spec_file,
            root_dirs_file,
            xccurrentversions_file,
            extensionpointidentifiers_file,
        ] + bazel_integration_files,
        outputs = [xcodeproj],
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
        install_path,
        xcodeproj):
    installer = ctx.actions.declare_file(
        "{}-installer.sh".format(name or ctx.attr.name),
    )

    ctx.actions.expand_template(
        template = ctx.file._installer_template,
        output = installer,
        is_executable = True,
        substitutions = {
            "%bazel_path%": ctx.attr.bazel_path,
            "%output_path%": install_path,
            "%source_path%": xcodeproj.short_path,
        },
    )

    return installer

# Transition

def _base_target_transition_impl(_settings, attr):
    return {
        "//xcodeproj/internal:build_mode": attr.build_mode,
    }

def _device_transition_impl(settings, attr):
    outputs = {
        "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
        "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
        "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
    }

    outputs.update(_base_target_transition_impl(settings, attr))

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

    outputs.update(_base_target_transition_impl(settings, attr))

    return outputs

_TRANSITION_ATTR = {
    "inputs": [
        # Simulator and Device support
        "//command_line_option:cpu",
    ],
    "outputs": [
        "//xcodeproj/internal:build_mode",
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
    project_name = ctx.attr.project_name
    focused_labels = sets.make(ctx.attr.focused_targets)
    unfocused_labels = sets.make(ctx.attr.unfocused_targets)
    infos = [
        dep[XcodeProjInfo]
        for dep in (
            ctx.attr.top_level_simulator_targets +
            ctx.attr.top_level_device_targets
        )
    ]
    configuration = get_configuration(ctx = ctx)

    outputs = output_files.merge(
        automatic_target_info = None,
        transitive_infos = [(None, info) for info in infos],
    )

    extension_infoplists = depset(
        transitive = [
            info.extension_infoplists
            for info in infos
        ],
    )

    bazel_integration_files = list(ctx.files._base_integration_files)
    if build_mode != "xcode":
        bazel_integration_files.extend(ctx.files._bazel_integration_files)

    inputs = input_files.merge(
        transitive_infos = [(None, info) for info in infos],
    )

    targets, additional_generated, additional_outputs = _process_targets(
        build_mode = build_mode,
        focused_labels = focused_labels,
        unfocused_labels = unfocused_labels,
        inputs = inputs,
        infos = infos,
    )

    spec_file = _write_json_spec(
        ctx = ctx,
        project_name = project_name,
        configuration = configuration,
        targets = targets,
        has_focused_targets = sets.length(focused_labels) > 0,
        inputs = inputs,
        infos = infos,
    )
    root_dirs_file = _write_root_dirs(ctx = ctx)
    xccurrentversions_file = _write_xccurrentversions(
        ctx = ctx,
        xccurrentversion_files = inputs.xccurrentversions.to_list(),
    )
    extensionpointidentifiers_file = _write_extensionpointidentifiers(
        ctx = ctx,
        extension_infoplists = extension_infoplists.to_list(),
        focused_labels = focused_labels,
        unfocused_labels = unfocused_labels,
    )
    xcodeproj, install_path = _write_xcodeproj(
        ctx = ctx,
        project_name = project_name,
        spec_file = spec_file,
        root_dirs_file = root_dirs_file,
        xccurrentversions_file = xccurrentversions_file,
        extensionpointidentifiers_file = extensionpointidentifiers_file,
        bazel_integration_files = bazel_integration_files,
        build_mode = ctx.attr.build_mode,
    )
    installer = _write_installer(
        ctx = ctx,
        install_path = install_path,
        xcodeproj = xcodeproj,
    )

    input_files_output_groups = input_files.to_output_groups_fields(
        ctx = ctx,
        inputs = inputs,
        additional_generated = additional_generated,
        toplevel_cache_buster = ctx.files.toplevel_cache_buster,
    )
    output_files_output_groups = output_files.to_output_groups_fields(
        ctx = ctx,
        outputs = outputs,
        additional_outputs = additional_outputs,
        toplevel_cache_buster = ctx.files.toplevel_cache_buster,
    )

    if build_mode == "xcode":
        all_targets_files = [
            input_files_output_groups["all_xc"],
            input_files_output_groups["all_xl"],
        ]
    else:
        all_targets_files = [output_files_output_groups["all_b"]]

    return [
        DefaultInfo(
            executable = installer,
            files = depset(
                [xcodeproj],
                transitive = [inputs.important_generated],
            ),
            runfiles = ctx.runfiles(files = [xcodeproj]),
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

def make_xcodeproj_rule(*, xcodeproj_transition = None):
    attrs = {
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
        "project_name": attr.string(
            doc = """\
The name to use for the `.xcodeproj` file.
""",
            mandatory = True,
        ),
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
        "toplevel_cache_buster": attr.label_list(
            doc = "For internal use only. Do not set this value yourself.",
            allow_empty = True,
            allow_files = True,
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
            allow_files = True,
            default = Label(
                "//xcodeproj/internal/bazel_integration_files:base_integration_files",
            ),
        ),
        "_bazel_integration_files": attr.label(
            allow_files = True,
            default = Label("//xcodeproj/internal/bazel_integration_files"),
        ),
        "_extensionpointidentifiers_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/extensionpointidentifiers_parser"),
            executable = True,
        ),
        "_generator": attr.label(
            cfg = "exec",
            # TODO: Use universal generator when done debugging
            default = Label("//tools/generator"),
            executable = True,
        ),
        "_install_path": attr.label(
            default = Label("//xcodeproj/internal:install_path"),
            providers = [BuildSettingInfo],
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
        "_xccurrentversions_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/xccurrentversions_parser"),
            executable = True,
        ),
    }

    return rule(
        doc = "Creates an `.xcodeproj` file in the workspace when run.",
        cfg = xcodeproj_transition,
        implementation = _xcodeproj_impl,
        attrs = attrs,
        executable = True,
    )

xcodeproj = make_xcodeproj_rule()

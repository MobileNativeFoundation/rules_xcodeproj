"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":collections.bzl", "uniq")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "file_path", "file_path_to_dto", "parsed_file_path")
load(":flattened_key_values.bzl", "flattened_key_values")
load(":input_files.bzl", "input_files")
load(":output_files.bzl", "output_files")
load(":providers.bzl", "XcodeProjInfo", "XcodeProjOutputInfo")
load(":resource_target.bzl", "process_resource_bundles")
load(":xcode_targets.bzl", "xcode_targets")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")

# Actions

def _write_json_spec(
        *,
        ctx,
        project_name,
        configuration,
        inputs,
        infos):
    resource_bundle_informations = depset(
        transitive = [info.resource_bundle_informations for info in infos],
    ).to_list()

    resource_bundle_xcode_targets = process_resource_bundles(
        bundles = inputs.resource_bundles.to_list(),
        resource_bundle_informations = resource_bundle_informations,
    )

    extra_files = inputs.extra_files
    non_mergable_targets = depset(
        transitive = [info.non_mergable_targets for info in infos],
    )
    potential_target_merges = depset(
        transitive = [info.potential_target_merges for info in infos],
    )
    targets_depset = depset(
        resource_bundle_xcode_targets,
        transitive = [info.xcode_targets for info in infos],
    )

    non_mergable_targets_set = sets.make([
        file_path(file)
        for file in non_mergable_targets.to_list()
    ])

    target_merges = {}
    for merge in potential_target_merges.to_list():
        if not sets.contains(non_mergable_targets_set, merge.src.product_path):
            target_merges.setdefault(merge.src.id, []).append(merge.dest)

    unfocused_libraries = sets.make(inputs.unfocused_libraries.to_list())

    targets = {}
    for xcode_target in targets_depset.to_list():
        targets[xcode_target.id] = xcode_targets.to_dto(
            xcode_target,
            is_unfocused_dependency = sets.contains(
                unfocused_libraries,
                xcode_target.product.path
            ),
        )
    targets_json = json.encode(
        flattened_key_values.to_list(targets),
    )

    target_merges_json = json.encode(
        flattened_key_values.to_list(target_merges),
    )

    hosted_targets = depset(
        transitive = [info.hosted_targets for info in infos],
    )
    target_hosts = {}
    for s in hosted_targets.to_list():
        target_hosts.setdefault(s.hosted, []).append(s.host)
    target_hosts_json = json.encode(
        flattened_key_values.to_list(target_hosts),
    )

    extra_files = [
        file_path_to_dto(file)
        for file in extra_files.to_list()
    ]
    extra_files.append(file_path_to_dto(parsed_file_path(ctx.build_file_path)))

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
        extra_files = json.encode(extra_files),
        force_bazel_dependencies = json.encode(inputs.has_generated_files),
        label = ctx.label,
        name = project_name,
        scheme_autogeneration_mode = ctx.attr.scheme_autogeneration_mode,
        target_hosts = target_hosts_json,
        target_merges = target_merges_json,
        targets = targets_json,
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
        executable = ctx.executable._xccurrentversions_parser,
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
    ctx.actions.run(
        arguments = [targetids_file.path, files_list, output.path],
        executable = ctx.executable._extensionpointidentifiers_parser,
        inputs = [targetids_file] + infoplist_files,
        outputs = [output],
        mnemonic = "CalculateXcodeProjExtensionPointIdentifiers",
    )

    return output

def _write_xcodeproj(
        *,
        ctx,
        project_name,
        spec_file,
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
    args.add(xccurrentversions_file.path)
    args.add(extensionpointidentifiers_file.path)
    args.add(bazel_integration_files[0].dirname)
    args.add(xcodeproj.path)
    args.add(install_path)
    args.add(build_mode)

    ctx.actions.run(
        executable = ctx.executable._generator,
        mnemonic = "GenerateXcodeProj",
        arguments = [args],
        inputs = [
            spec_file,
            xccurrentversions_file,
            extensionpointidentifiers_file,
        ] + bazel_integration_files,
        outputs = [xcodeproj],
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
            "%output_path%": install_path,
            "%source_path%": xcodeproj.short_path,
        },
    )

    return installer

# Transition

def _base_target_transition_impl(settings, attr):
    features = [
        "oso_prefix_is_pwd",
        "relative_ast_path",
    ] + settings.get("//command_line_option:features")

    if attr.build_mode == "bazel":
        archived_bundles_allowed = attr.archived_bundles_allowed
    else:
        archived_bundles_allowed = True

    return {
        "//command_line_option:compilation_mode": "dbg",
        "//command_line_option:features": features,
        "//xcodeproj/internal:archived_bundles_allowed": (
            archived_bundles_allowed
        ),
        "//xcodeproj/internal:build_mode": attr.build_mode,
    }

def make_target_transition(
        implementation = None,
        inputs = [],
        outputs = []):
    def _target_transition_impl(settings, attr):
        """Transition that applies command-line settings for `xcodeproj` targets."""

        # Apply the other transition first
        if implementation:
            computed_outputs = implementation(settings, attr)
        else:
            computed_outputs = {}

        settings = dict(settings)
        settings.update(computed_outputs)

        # Then apply our transition
        computed_outputs.update(_base_target_transition_impl(settings, attr))

        return computed_outputs

    merged_inputs = uniq(
        inputs + [
            "//command_line_option:compilation_mode",
            "//command_line_option:features",
        ],
    )
    merged_outputs = uniq(
        outputs + [
            "//command_line_option:compilation_mode",
            "//command_line_option:features",
            "//xcodeproj/internal:archived_bundles_allowed",
            "//xcodeproj/internal:build_mode",
        ],
    )

    return transition(
        implementation = _target_transition_impl,
        inputs = merged_inputs,
        outputs = merged_outputs,
    )

# Rule

def _xcodeproj_impl(ctx):
    project_name = ctx.attr.project_name or ctx.attr.name
    infos = [
        dep[XcodeProjInfo]
        for dep in ctx.attr.targets
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

    bazel_integration_files = [ctx.file._create_lldbinit_script]
    if ctx.attr.build_mode != "xcode":
        bazel_integration_files.extend(ctx.files._bazel_integration_files)

    inputs = input_files.merge(
        transitive_infos = [(None, info) for info in infos],
    )

    spec_file = _write_json_spec(
        ctx = ctx,
        project_name = project_name,
        configuration = configuration,
        inputs = inputs,
        infos = infos,
    )
    xccurrentversions_file = _write_xccurrentversions(
        ctx = ctx,
        xccurrentversion_files = inputs.xccurrentversions.to_list(),
    )
    extensionpointidentifiers_file = _write_extensionpointidentifiers(
        ctx = ctx,
        extension_infoplists = extension_infoplists.to_list(),
    )
    xcodeproj, install_path = _write_xcodeproj(
        ctx = ctx,
        project_name = project_name,
        spec_file = spec_file,
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
            **dicts.add(
                input_files.to_output_groups_fields(
                    ctx = ctx,
                    inputs = inputs,
                    toplevel_cache_buster = ctx.files.toplevel_cache_buster,
                ),
                output_files.to_output_groups_fields(
                    ctx = ctx,
                    outputs = outputs,
                    toplevel_cache_buster = ctx.files.toplevel_cache_buster,
                ),
            )
        ),
        XcodeProjOutputInfo(
            installer = installer,
            project_name = project_name,
            spec = spec_file,
            xcodeproj = xcodeproj,
        ),
    ]

def make_xcodeproj_rule(
        *,
        xcodeproj_transition = None,
        target_transition = make_target_transition()):
    attrs = {
        "archived_bundles_allowed": attr.bool(
            default = False,
        ),
        "bazel_path": attr.string(
            default = "bazel",
        ),
        "build_mode": attr.string(
            default = "xcode",
            values = ["xcode", "bazel"],
        ),
        "project_name": attr.string(),
        "scheme_autogeneration_mode": attr.string(
            default = "auto",
            doc = "Specifies how Xcode schemes are automatically generated.",
            values = ["auto", "none", "all"],
        ),
        "schemes_json": attr.string(
            doc = """\
A JSON string representing a list of Xcode schemes to create.\
""",
        ),
        "targets": attr.label_list(
            cfg = target_transition,
            mandatory = True,
            allow_empty = False,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "toplevel_cache_buster": attr.label_list(
            allow_empty = True,
            allow_files = True,
            doc = "For internal use only. Do not set this value yourself.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_bazel_integration_files": attr.label(
            allow_files = True,
            default = Label("//xcodeproj/internal/bazel_integration_files"),
        ),
        "_create_lldbinit_script": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal/bazel_integration_files:create_lldbinit.sh"),
        ),
        "_extensionpointidentifiers_parser": attr.label(
            cfg = "exec",
            default = Label("//tools/extensionpointidentifiers_parser"),
            executable = True,
        ),
        "_external_file_marker": attr.label(
            allow_single_file = True,
            # This just has to point to a source file in an external repo. It is
            # only used by a local action, so it doesn't matter what it points
            # to.
            default = "@build_bazel_rules_apple//:LICENSE",
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
        cfg = xcodeproj_transition,
        implementation = _xcodeproj_impl,
        attrs = attrs,
        executable = True,
    )

xcodeproj = make_xcodeproj_rule()

"""Implementation of the `xcodeproj` rule."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":files.bzl", "file_path", "file_path_to_dto")
load(":flattened_key_values.bzl", "flattened_key_values")
load(":input_files.bzl", "input_files")
load(":providers.bzl", "XcodeProjInfo", "XcodeProjOutputInfo")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")

# Actions

def _write_json_spec(*, ctx, project_name, inputs, infos):
    extra_files = inputs.extra_files
    potential_target_merges = depset(
        transitive = [info.potential_target_merges for info in infos],
    )
    required_links = depset(
        transitive = [info.required_links for info in infos],
    )
    xcode_targets = depset(
        transitive = [info.xcode_targets for info in infos],
    )

    # `potential_target_merges` needs to be converted into a `dict` of sets
    potential_target_merges_dict = {}
    for merge in potential_target_merges.to_list():
        destinations = potential_target_merges_dict.get(merge.src, [])
        destinations.append(merge.dest)
        potential_target_merges_dict[merge.src] = destinations
    potential_target_merges_array = []
    for key, value in potential_target_merges_dict.items():
        potential_target_merges_array.append(key)
        potential_target_merges_array.append(value)

    # `xcode_targets` is partial json dictionary strings. It and
    # `potential_target_merges` are dictionaries in alternating key and value
    # array format.
    sorted_xcode_targets = sorted(xcode_targets.to_list())
    sorted_potential_target_merges_array = flattened_key_values.sort(
        potential_target_merges_array,
    )
    targets_json = "[{}]".format(",".join(sorted_xcode_targets))
    potential_target_merges_json = json.encode(sorted_potential_target_merges_array)

    # TODO: Set CURRENT_PROJECT_VERSION and MARKETING_VERSION from `version`
    spec_json = """\
{{\
"build_settings":{{\
"ALWAYS_SEARCH_USER_PATHS":false,\
"BAZEL_PATH":"{bazel_path}",\
"CLANG_ENABLE_OBJC_ARC":true,\
"CLANG_MODULES_AUTOLINK":false,\
"COPY_PHASE_STRIP":false,\
"CURRENT_PROJECT_VERSION":"1",\
"MARKETING_VERSION":"1.0",\
"ONLY_ACTIVE_ARCH":true,\
"USE_HEADERMAP":false\
}},\
"extra_files":{extra_files},\
"label":"{label}",\
"name":"{name}",\
"potential_target_merges":{potential_target_merges},\
"required_links":{required_links},\
"targets":{targets}\
}}
""".format(
        bazel_path = ctx.attr.bazel_path,
        extra_files = json.encode([
            file_path_to_dto(file_path(file))
            for file in extra_files.to_list()
        ]),
        label = ctx.label,
        potential_target_merges = potential_target_merges_json,
        name = project_name,
        targets = targets_json,
        required_links = json.encode(sorted(required_links.to_list())),
    )

    output = ctx.actions.declare_file("{}_spec.json".format(ctx.attr.name))
    ctx.actions.write(output, spec_json)

    return output

def _write_root_dirs(*, ctx):
    an_external_input = ctx.file._external_file_marker

    output = ctx.actions.declare_file("{}_root_dirs".format(ctx.attr.name))
    ctx.actions.run_shell(
        inputs = [an_external_input],
        outputs = [output],
        command = """\
if [ -n "{external_dir_override}" ]; then
  echo "{external_dir_override}" >> "{out_full}"
else
  # `readlink -f` doesn't exist on macOS, so use perl instead
  external_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{external_full}";)"
  # Strip `/private` prefix from paths (as it breaks breakpoints)
  external_full_path="${{external_full_path#/private}}"
  # Trim the suffix from the paths
  echo "${{external_full_path%/{external_full}}}/external" >> "{out_full}"
fi
if [ -n "{generated_dir_override}" ]; then
  echo "{generated_dir_override}" >> "{out_full}"
else
  # `readlink -f` doesn't exist on macOS, so use perl instead
  generated_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{generated_full}";)"
  # Strip `/private` prefix from paths (as it breaks breakpoints)
  generated_full_path="${{generated_full_path#/private}}"
  # Trim the suffix from the paths
  echo "${{generated_full_path%/{generated_full}}}/bazel-out" >> "{out_full}"
fi
""".format(
            external_full = an_external_input.path,
            external_dir_override = ctx.attr.external_dir_override,
            generated_full = ctx.bin_dir.path,
            generated_dir_override = ctx.attr.generated_dir_override,
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

def _write_xcodeproj(*, ctx, project_name, root_dirs_file, spec_file):
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
    args.add(root_dirs_file.path)
    args.add(spec_file.path)
    args.add(xcodeproj.path)
    args.add(install_path)

    ctx.actions.run(
        executable = ctx.executable._generator,
        mnemonic = "GenerateXcodeProj",
        arguments = [args],
        inputs = [root_dirs_file, spec_file],
        outputs = [xcodeproj],
    )

    return xcodeproj, install_path

def _write_installer(*, ctx, name = None, install_path, xcodeproj):
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

# Rule

def _xcodeproj_impl(ctx):
    project_name = ctx.attr.project_name or ctx.attr.name
    infos = [
        dep[XcodeProjInfo]
        for dep in ctx.attr.targets
        if XcodeProjInfo in dep
    ]
    inputs = input_files.merge(
        transitive_infos = [(None, info) for info in infos],
    )

    spec_file = _write_json_spec(
        ctx = ctx,
        project_name = project_name,
        inputs = inputs,
        infos = infos,
    )
    root_dirs_file = _write_root_dirs(ctx = ctx)
    xcodeproj, install_path = _write_xcodeproj(
        ctx = ctx,
        project_name = project_name,
        root_dirs_file = root_dirs_file,
        spec_file = spec_file,
    )
    installer = _write_installer(
        ctx = ctx,
        install_path = install_path,
        xcodeproj = xcodeproj,
    )

    return [
        DefaultInfo(
            executable = installer,
            files = depset([xcodeproj]),
            runfiles = ctx.runfiles(files = [xcodeproj]),
        ),
        OutputGroupInfo(
            generated_inputs = inputs.generated,
        ),
        XcodeProjOutputInfo(
            installer = installer,
            root_dirs = root_dirs_file,
            spec = spec_file,
            xcodeproj = xcodeproj,
        ),
    ]

def make_xcodeproj_rule(*, transition = None):
    attrs = {
        "bazel_path": attr.string(
            default = "bazel",
        ),
        "external_dir_override": attr.string(
            default = "",
        ),
        "generated_dir_override": attr.string(
            default = "",
        ),
        "project_name": attr.string(),
        "targets": attr.label_list(
            cfg = transition,
            mandatory = True,
            allow_empty = False,
            aspects = [xcodeproj_aspect],
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
            default = Label("//tools/generator:generator"),
            executable = True,
        ),
        "_install_path": attr.label(
            default = Label("//xcodeproj/internal:install_path"),
            providers = [BuildSettingInfo],
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            executable = False,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
    }

    if transition:
        attrs["_allowlist_function_transition"] = attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        )

    return rule(
        implementation = _xcodeproj_impl,
        attrs = attrs,
        executable = True,
    )

_xcodeproj = make_xcodeproj_rule()

def xcodeproj(*, xcodeproj_rule = _xcodeproj, **kwargs):
    testonly = kwargs.pop("testonly", True)

    xcodeproj_rule(
        testonly = testonly,
        **kwargs
    )

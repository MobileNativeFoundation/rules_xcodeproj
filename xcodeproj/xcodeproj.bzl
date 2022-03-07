"""Implementation of the `xcodeproj` rule."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:target.bzl",
    "XcodeProjInfo",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:xcodeproj_aspect.bzl",
    "xcodeproj_aspect",
)
load("@bazel_skylib//lib:paths.bzl", "paths")

XcodeProjOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj` rule.",
    fields = {
        "root_dirs": "The root directories file",
        "spec": "The json spec",
        "xcodeproj": "The xcodeproj file",
    },
)

# Actions

def _write_json_spec(*, ctx, project_name, infos):
    extra_files = depset(
        transitive = [info.extra_files for info in infos],
    )
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
    targets_json = "[{}]".format(",".join(xcode_targets.to_list()))
    potential_target_merges_json = json.encode(potential_target_merges_array)

    # TODO: Set CURRENT_PROJECT_VERSION and MARKETING_VERSION from `version`
    spec_json = """\
{{\
"build_settings":{{\
"ALWAYS_SEARCH_USER_PATHS":false,\
"COPY_PHASE_STRIP":false,\
"CURRENT_PROJECT_VERSION":"1",\
"MARKETING_VERSION":"1.0",\
"ONLY_ACTIVE_ARCH":true\
}},\
"extra_files":{extra_files},\
"name": "{name}",\
"potential_target_merges":{potential_target_merges},\
"required_links":{required_links},\
"targets":{targets}\
}}
""".format(
        extra_files = json.encode(
            [file.path for file in extra_files.to_list()],
        ),
        potential_target_merges = potential_target_merges_json,
        name = project_name,
        targets = targets_json,
        required_links = json.encode(required_links.to_list()),
    )

    output = ctx.actions.declare_file("{}_spec.json".format(ctx.attr.name))
    ctx.actions.write(output, spec_json)

    return output

def _write_root_dirs(*, ctx, infos):
    all_inputs = depset(transitive = [info.all_inputs for info in infos])

    a_project_input = None
    for input in all_inputs.to_list():
        if not input.owner.workspace_name:
            a_project_input = input
            break
    an_external_input = ctx.file._external_file_marker

    output = ctx.actions.declare_file("{}_root_dirs".format(ctx.attr.name))
    ctx.actions.run_shell(
        inputs = [a_project_input, an_external_input],
        outputs = [output],
        command = """\
# `readlink -f` doesn't exist on macOS, so use perl instead
full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{src_full}";)"
external_full_path="$(perl -MCwd -e 'print Cwd::abs_path shift' "{external_full}";)"
# Strip `/private` prefix from external_full_path (as it breaks breakpoints)
external_full_path="${{external_full_path#/private}}"
# Trim the short_path suffix from full_path
echo "${{full_path%/{src_short}}}" > "{out_full}"
echo "${{external_full_path%/{external_full}}}/external" >> "{out_full}"
""".format(
            src_full = a_project_input.path,
            src_short = a_project_input.short_path,
            external_full = an_external_input.path,
            out_full = output.path,
        ),
        mnemonic = "CalculateXcodeProjRootDirs",
        # This has to run locally
        execution_requirements = {
            "no-sandbox": "1",
            "no-remote": "1",
            "local": "1",
        },
    )

    return output

def _write_xcodeproj(*, ctx, project_name, root_dirs_file, spec_file):
    xcodeproj = ctx.actions.declare_directory(
        "{}.xcodeproj".format(ctx.attr.name),
    )

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
            "%source_path%": xcodeproj.short_path,
            "%output_path%": install_path,
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

    spec_file = _write_json_spec(
        ctx = ctx,
        project_name = project_name,
        infos = infos,
    )
    root_dirs_file = _write_root_dirs(
        ctx = ctx,
        infos = infos,
    )
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
        XcodeProjOutputInfo(
            root_dirs = root_dirs_file,
            spec = spec_file,
            xcodeproj = xcodeproj,
        ),
    ]

_xcodeproj = rule(
    implementation = _xcodeproj_impl,
    attrs = {
        "project_name": attr.string(),
        "targets": attr.label_list(
            mandatory = True,
            allow_empty = False,
            aspects = [xcodeproj_aspect],
        ),
        "_generator": attr.label(
            cfg = "exec",
            # TODO: Use universal generator when done debugging
            default = Label("//tools/generator:generator"),
            executable = True,
        ),
        "_external_file_marker": attr.label(
            allow_single_file = True,
            # This just has to point to a source file in an external repo. It is
            # only used by a local action, so it doesn't matter what it points
            # to.
            default = "@build_bazel_rules_apple//:LICENSE",
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            executable = False,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
    },
    executable = True,
)

def xcodeproj(**kwargs):
    testonly = kwargs.pop("testonly", True)
    _xcodeproj(
        testonly = testonly,
        **kwargs
    )

internal = struct(
    write_installer = _write_installer,
)

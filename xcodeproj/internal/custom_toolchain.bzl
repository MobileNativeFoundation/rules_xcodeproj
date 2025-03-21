"""Implementation of the `custom_toolchain` rule."""

def _get_xcode_product_version(*, xcode_config):
    raw_version = str(xcode_config.xcode_version())
    if not raw_version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")

    version_components = raw_version.split(".")
    if len(version_components) < 4:
        # This will result in analysis cache misses, but it's better than
        # failing
        return raw_version

    return version_components[3]

def _custom_toolchain_impl(ctx):
    xcode_version = _get_xcode_product_version(
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )

    toolchain_name_base = ctx.attr.toolchain_name
    toolchain_dir = ctx.actions.declare_directory(
        toolchain_name_base + "{}".format(xcode_version) + ".xctoolchain",
    )

    resolved_overrides = {}
    override_files = []

    for tool_target, tool_name in ctx.attr.overrides.items():
        files = tool_target.files.to_list()
        if not files:
            fail("ERROR: Override for '{}' does not produce any files!".format(tool_name))

        if len(files) > 1:
            fail("ERROR: Override for '{}' produces multiple files ({}). Each override must have exactly one file.".format(
                tool_name,
                len(files),
            ))

        override_file = files[0]
        override_files.append(override_file)
        resolved_overrides[tool_name] = override_file.path

    overrides_list = " ".join(["{}={}".format(k, v) for k, v in resolved_overrides.items()])

    script_file = ctx.actions.declare_file(toolchain_name_base + "_setup.sh")

    ctx.actions.expand_template(
        template = ctx.file._symlink_template,
        output = script_file,
        is_executable = True,
        substitutions = {
            "%overrides_list%": overrides_list,
            "%toolchain_dir%": toolchain_dir.path,
            "%toolchain_name_base%": toolchain_name_base,
            "%xcode_version%": xcode_version,
        },
    )

    ctx.actions.run_shell(
        outputs = [toolchain_dir],
        inputs = override_files,
        tools = [script_file],
        mnemonic = "CreateCustomToolchain",
        command = script_file.path,
        execution_requirements = {
            "local": "1",
            "no-cache": "1",
            "no-sandbox": "1",
            "requires-darwin": "1",
        },
        use_default_shell_env = True,
    )

    # Create runfiles with the override files and script file
    runfiles = ctx.runfiles(files = override_files + [script_file])

    return [DefaultInfo(
        files = depset([toolchain_dir]),
        runfiles = runfiles,
    )]

custom_toolchain = rule(
    implementation = _custom_toolchain_impl,
    attrs = {
        "overrides": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = False,
            default = {},
        ),
        "toolchain_name": attr.string(mandatory = True),
        "_symlink_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal/templates:custom_toolchain_symlink.sh"),
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    },
)

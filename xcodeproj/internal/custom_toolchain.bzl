"""Implementation of the `custom_toolchain` rule."""

load("//xcodeproj/internal:providers.bzl", "ToolchainInfo")

def _get_xcode_product_version(*, xcode_config):
    raw_version = str(xcode_config.xcode_version())
    if not raw_version:
        fail("""\
`xcode_config.xcode_version` was not set. This is a bazel bug. Try again.
""")

    version_components = raw_version.split(".")
    if len(version_components) != 4:
        fail("""\
`xcode_config.xcode_version` returned an unexpected number of components: {}
""".format(len(version_components)))

    return version_components[3]

def _custom_toolchain_impl(ctx):
    xcode_version = _get_xcode_product_version(
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )

    toolchain_name_base = ctx.attr.toolchain_name
    toolchain_id = "com.rules_xcodeproj.{}.{}".format(toolchain_name_base, xcode_version)
    full_toolchain_name = "{}{}".format(toolchain_name_base, xcode_version)

    # Create two directories - one for symlinks, one for the final overridden toolchain
    symlink_toolchain_dir = ctx.actions.declare_directory(full_toolchain_name + ".symlink.xctoolchain")
    final_toolchain_dir = ctx.actions.declare_directory(full_toolchain_name + ".xctoolchain")

    resolved_overrides = {}
    override_files = []

    # Process tools from comma-separated list
    for stub_target, tools_str in ctx.attr.overrides.items():
        files = stub_target.files.to_list()
        if not files:
            fail("ERROR: Override stub does not produce any files!")

        if len(files) > 1:
            fail("ERROR: Override stub produces multiple files ({}). Each stub must have exactly one file.".format(
                len(files),
            ))

        stub_file = files[0]
        if stub_file not in override_files:
            override_files.append(stub_file)

        # Split comma-separated list of tool names
        tool_names = [name.strip() for name in tools_str.split(",")]

        # Add an entry for each tool name
        for tool_name in tool_names:
            if tool_name:  # Skip empty names
                resolved_overrides[tool_name] = stub_file.path

    # Instead of passing the full map of overrides, just pass the tool names
    # This way, changes to the stubs don't trigger a rebuild
    tool_names_list = " ".join(resolved_overrides.keys())

    overrides_list = " ".join(["{}={}".format(k, v) for k, v in resolved_overrides.items()])

    symlink_script_file = ctx.actions.declare_file(full_toolchain_name + "_symlink.sh")
    override_script_file = ctx.actions.declare_file(full_toolchain_name + "_override.sh")
    override_marker = ctx.actions.declare_file(full_toolchain_name + ".override.marker")

    # Create symlink script
    ctx.actions.expand_template(
        template = ctx.file._symlink_template,
        output = symlink_script_file,
        is_executable = True,
        substitutions = {
            "%tool_names_list%": tool_names_list,
            "%toolchain_dir%": symlink_toolchain_dir.path,
            "%toolchain_id%": toolchain_id,
            "%toolchain_name_base%": full_toolchain_name,
            "%xcode_version%": xcode_version,
        },
    )

    # First run the symlinking script to set up the toolchain
    ctx.actions.run_shell(
        outputs = [symlink_toolchain_dir],
        tools = [symlink_script_file],
        mnemonic = "CreateSymlinkToolchain",
        command = symlink_script_file.path,
        execution_requirements = {
            "local": "1",
            "no-cache": "1",
            "no-sandbox": "1",
            "requires-darwin": "1",
        },
        use_default_shell_env = True,
    )

    if override_files:
        ctx.actions.expand_template(
            template = ctx.file._override_template,
            output = override_script_file,
            is_executable = True,
            substitutions = {
                "%final_toolchain_dir%": final_toolchain_dir.path,
                "%marker_file%": override_marker.path,
                "%overrides_list%": overrides_list,
                "%symlink_toolchain_dir%": symlink_toolchain_dir.path,
                "%tool_names_list%": tool_names_list,
            },
        )

        ctx.actions.run_shell(
            inputs = override_files + [symlink_toolchain_dir],
            outputs = [final_toolchain_dir, override_marker],
            tools = [override_script_file],
            mnemonic = "ApplyCustomToolchainOverrides",
            command = override_script_file.path,
            execution_requirements = {
                "local": "1",
                "no-cache": "1",
                "no-sandbox": "1",
                "requires-darwin": "1",
            },
            use_default_shell_env = True,
        )

    runfiles = ctx.runfiles(files = override_files + [symlink_script_file, override_script_file, override_marker])

    toolchain_provider = ToolchainInfo(
        name = full_toolchain_name,
        identifier = toolchain_id,
    )

    return [
        DefaultInfo(
            files = depset([final_toolchain_dir if override_files else symlink_toolchain_dir]),
            runfiles = runfiles,
        ),
        toolchain_provider,
    ]

custom_toolchain = rule(
    implementation = _custom_toolchain_impl,
    attrs = {
        "overrides": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
            doc = "Map from stub target to comma-separated list of tool names that should use that stub",
        ),
        "toolchain_name": attr.string(mandatory = True),
        "_override_template": attr.label(
            allow_single_file = True,
            default = Label("//xcodeproj/internal/templates:custom_toolchain_override.sh"),
        ),
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

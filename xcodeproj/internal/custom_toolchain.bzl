"""Implementation of the `custom_toolchain` rule."""

load("//xcodeproj/internal:providers.bzl", "ToolchainInfo")

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
    toolchain_id = "com.rules_xcodeproj.{}.{}".format(toolchain_name_base, xcode_version)
    full_toolchain_name = "{}{}".format(toolchain_name_base, xcode_version)
    toolchain_dir = ctx.actions.declare_directory(full_toolchain_name + ".xctoolchain")

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

    overrides_list = " ".join(["{}={}".format(k, v) for k, v in resolved_overrides.items()])

    script_file = ctx.actions.declare_file(full_toolchain_name + "_setup.sh")

    ctx.actions.expand_template(
        template = ctx.file._symlink_template,
        output = script_file,
        is_executable = True,
        substitutions = {
            "%overrides_list%": overrides_list,
            "%toolchain_dir%": toolchain_dir.path,
            "%toolchain_id%": toolchain_id,
            "%toolchain_name_base%": full_toolchain_name,
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

    runfiles = ctx.runfiles(files = override_files + [script_file])

    toolchain_provider = ToolchainInfo(
        name = full_toolchain_name,
        identifier = toolchain_id,
    )

    return [
        DefaultInfo(
            files = depset([toolchain_dir]),
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

"""allow_multiple_flag Rule"""

AllowMultipleProvider = provider(
    doc = "Information about an allow_multiple flag.",
    fields = {
        "flag": "The name of the flag.",
        "values": "The values that were set for the flag.",
    },
)

def _allow_multiple_flag_impl(ctx):
    flag = "@{workspace}//{pkg}:{name}".format(
        workspace = ctx.label.workspace_name,
        pkg = ctx.label.package,
        name = ctx.label.name,
    )

    # Due to a nuance on how allow_multiple flags work, we can see an empty
    # string.
    values = [v for v in ctx.build_setting_value if v != ""]

    # Write the values to a file.
    values_out = ctx.actions.declare_file(ctx.label.name + "_values.txt")
    ctx.actions.write(values_out, content = "\n".join(values))

    return [
        DefaultInfo(
            files = depset([values_out]),
            runfiles = ctx.runfiles([values_out]),
        ),
        AllowMultipleProvider(
            flag = flag,
            values = values,
        ),
    ]

allow_multiple_flag = rule(
    implementation = _allow_multiple_flag_impl,
    build_setting = config.string(flag = True, allow_multiple = True),
    doc = "Defines a string flag that can be set multiple times.",
)

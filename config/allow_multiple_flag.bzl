# _allow_multiple_flag Rule

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

# # _write_allow_multiple_flag_values Rule

# def _write_allow_multiple_flag_values_impl(ctx):
#     values = ctx.attr.flag[AllowMultipleProvider].values
#     values_out = ctx.actions.declare_file(ctx.label.name + ".txt")
#     ctx.actions.write(values_out, content = "\n".join(values))
#     return [DefaultInfo(
#         files = depset([values_out]),
#         runfiles = ctx.runfiles([values_out]),
#     )]

# _write_allow_multiple_flag_values = rule(
#     implementation = _write_allow_multiple_flag_values_impl,
#     attrs = {
#         "flag": attr.label(
#             doc = "The _allow_multiple_flag whose values should be serialized.",
#             providers = [AllowMultipleProvider],
#             mandatory = True,
#         ),
#     },
#     doc = "Defines a string flag that can be set multiple times.",
# )

# def allow_multiple_flag(name, build_setting_default, visibility = None):
#     _allow_multiple_flag(
#         name = name,
#         build_setting_default = build_setting_default,
#         visibility = visibility,
#     )
#     _write_allow_multiple_flag_values(
#         name = name + "_values",
#         flag = name,
#         visibility = visibility,
#     )

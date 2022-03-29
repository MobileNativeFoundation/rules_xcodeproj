"""String Flag That Serializes Value"""

StringValueProvider = provider(
    doc = "Information about a string value flag.",
    fields = {
        "value": "The value that was set for the flag.",
    },
)

def _string_flag_impl(ctx):
    # Get the provided value
    value = ctx.build_setting_value

    # Write the value to a file.
    value_out = ctx.actions.declare_file(ctx.label.name + "_value.txt")
    ctx.actions.write(value_out, content = value + "\n")

    return [
        DefaultInfo(
            files = depset([value_out]),
            # We add it to the runfiles so that the file is propagated to
            # runfiles for shell rules.
            # Related to
            #  https://github.com/bazelbuild/bazel/issues/1147
            #  https://github.com/bazelbuild/bazel/issues/12348
            runfiles = ctx.runfiles([value_out]),
        ),
        StringValueProvider(value = value),
    ]

string_flag = rule(
    implementation = _string_flag_impl,
    build_setting = config.string(flag = True),
    doc = "Defines a string flag that will serialize the value that is set.",
)

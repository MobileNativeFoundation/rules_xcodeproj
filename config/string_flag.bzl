"""String Flag That Serializes Value"""

StringValueInfo = provider(
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
        StringValueInfo(value = value),
    ]

string_flag = rule(
    implementation = _string_flag_impl,
    build_setting = config.string(flag = True),
    doc = """\
Defines a string flag that will serialize the value that is set.

The [Skylib string_flag](https://github.com/bazelbuild/bazel-skylib/blob/main/docs/common_settings_doc.md#string_flag) \
provides a similar functionality. In addition to passing the value along in a \
provider, it writes the value to a file that can be used by shell scripts (e.g. \
`sh_binary`, `sh_test`) by listing the flag in the `data` attribute.
""",
)

"""
Simple file generation
"""
def _generated_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.output_name)

    ctx.actions.run_shell(
        progress_message = "Copying file",
        command = "cp {input} {output}".format(
            input = ctx.file.source_file.path,
            output = out.path,
        ),
        arguments = [],
        inputs = [ctx.file.source_file],
        outputs = [out],
        mnemonic = "CopyFile",
    )

    return [
        DefaultInfo(files = depset([out])),
    ]

generated_file = rule(
    implementation = _generated_file_impl,
    attrs = {
        "source_file": attr.label(allow_single_file = True, mandatory = True),
        "output_name": attr.string(mandatory = True),
    },
)

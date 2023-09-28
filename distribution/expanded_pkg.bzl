"""Implementation of the `expanded_pkg` rule."""

def _impl(ctx):
    input = ctx.file.dep
    output = ctx.actions.declare_directory(ctx.label.name)

    args = ctx.actions.args()
    args.add(input)
    args.add(output.path)

    ctx.actions.run_shell(
        inputs = [input],
        arguments = [args],
        outputs = [output],
        command = """\
set -euo pipefail

tar -xf "$1" -C "$2"
touch "$2/WORKSPACE"
""",
    )

    return [DefaultInfo(files = depset([output]))]

expanded_pkg = rule(
    implementation = _impl,
    attrs = {
        "dep": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

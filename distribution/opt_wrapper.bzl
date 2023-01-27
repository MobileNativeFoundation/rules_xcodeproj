"""Implementation of the `opt_wrapper` rule."""

def _force_opt_impl(_settings, _attr):
    return {
        "//command_line_option:compilation_mode": "opt",
    }

_force_opt = transition(
    implementation = _force_opt_impl,
    inputs = [],
    outputs = [
        "//command_line_option:compilation_mode",
    ],
)

def _impl(ctx):
    return [
        ctx.attr.dep[0][DefaultInfo],
    ]

opt_wrapper = rule(
    implementation = _impl,
    attrs = {
        "dep": attr.label(cfg = _force_opt, mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

"""Implementation of the `release_wrapper` rule."""

def _force_release_settings_impl(_settings, _attr):
    return {
        "//command_line_option:compilation_mode": "opt",

        # Lock down distribution to a specific Xcode version
        "//command_line_option:xcode_version": "17B100",  # 26.1.1
    }

_force_release_settings = transition(
    implementation = _force_release_settings_impl,
    inputs = [],
    outputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:xcode_version",
    ],
)

def _impl(ctx):
    return [
        ctx.attr.dep[0][DefaultInfo],
    ]

release_wrapper = rule(
    implementation = _impl,
    attrs = {
        "dep": attr.label(cfg = _force_release_settings, mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

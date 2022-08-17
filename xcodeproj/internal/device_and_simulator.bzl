"""Implementation of the `device_and_simulator` rule."""

load(":providers.bzl", "XcodeProjInfo")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")
load(":xcodeprojinfo.bzl", "merge_xcodeprojinfos")

# Transition

def _device_transition_impl(_settings, attr):
    return {
        "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
        "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
        "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
    }

def _simulator_transition_impl(settings, attr):
    cpu_value = settings["//command_line_option:cpu"]

    ios_cpus = attr.ios_simulator_cpus
    if not ios_cpus:
        if cpu_value == "darwin_arm64":
            ios_cpus = "sim_arm64"
        else:
            ios_cpus = "x86_64"

    tvos_cpus = attr.tvos_simulator_cpus
    if not tvos_cpus:
        if cpu_value == "darwin_arm64":
            tvos_cpus = "sim_arm64"
        else:
            tvos_cpus = "x86_64"

    watchos_cpus = attr.watchos_simulator_cpus
    if not watchos_cpus:
        if cpu_value == "darwin_arm64":
            watchos_cpus = "arm64"
        else:
            # rules_apple defaults to i386, but Xcode 13 requires x86_64
            watchos_cpus = "x86_64"

    return {
        "//command_line_option:ios_multi_cpus": ios_cpus,
        "//command_line_option:tvos_cpus": tvos_cpus,
        "//command_line_option:watchos_cpus": watchos_cpus,
    }

def _both_transition_impl(settings, attr):
    return {
        "Simulator": _simulator_transition_impl(settings, attr),
        "Device": _device_transition_impl(settings, attr),
    }

_TRANSITION_ATTR = {
    "inputs": [
        "//command_line_option:cpu",
    ],
    "outputs": [
        "//command_line_option:ios_multi_cpus",
        "//command_line_option:tvos_cpus",
        "//command_line_option:watchos_cpus",
    ],
}

_simulator_transition = transition(
    implementation = _simulator_transition_impl,
    **_TRANSITION_ATTR
)

_device_transition = transition(
    implementation = _device_transition_impl,
    **_TRANSITION_ATTR
)

_both_transition = transition(
    implementation = _both_transition_impl,
    **_TRANSITION_ATTR
)

# Rule

def _device_and_simulator_impl(ctx):
    if not (ctx.attr.targets or ctx.attr.simulator_only_targets or
            ctx.attr.device_only_targets):
        fail("""\
One of `targets`, `simulator_only_targets`, or `device_only_targets` must be \
set.""")

    providers = [
        merge_xcodeprojinfos([
            dep[XcodeProjInfo]
            for dep in (
                ctx.attr.targets +
                ctx.attr.simulator_only_targets +
                ctx.attr.device_only_targets
            )
            if XcodeProjInfo in dep
        ]),
    ]

    return providers

_device_and_simulator = rule(
    implementation = _device_and_simulator_impl,
    attrs = {
        "ios_device_cpus": attr.string(
            default = "arm64",
        ),
        "ios_simulator_cpus": attr.string(),
        "tvos_device_cpus": attr.string(
            default = "arm64",
        ),
        "tvos_simulator_cpus": attr.string(),
        "watchos_device_cpus": attr.string(
            default = "arm64_32",
        ),
        "watchos_simulator_cpus": attr.string(),
        "targets": attr.label_list(
            cfg = _both_transition,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "simulator_only_targets": attr.label_list(
            cfg = _simulator_transition,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "device_only_targets": attr.label_list(
            cfg = _device_transition,
            aspects = [xcodeproj_aspect],
            providers = [XcodeProjInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def device_and_simulator(*, name, **kwargs):
    _device_and_simulator(
        name = name,
        testonly = True,
        **kwargs
    )

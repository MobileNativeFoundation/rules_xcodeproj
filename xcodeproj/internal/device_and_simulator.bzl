"""Implementation of the `device_and_simulator` rule."""

load(":providers.bzl", "XcodeProjInfo")
load(":xcodeproj_aspect.bzl", "xcodeproj_aspect")
load(":xcodeprojinfo.bzl", "merge_xcodeprojinfos")

# Transition

def _target_transition_impl(settings, attr):
    cpu_value = settings["//command_line_option:cpu"]

    ios_simulator_cpus = attr.ios_simulator_cpus
    if not ios_simulator_cpus:
        if cpu_value == "darwin_arm64":
            ios_simulator_cpus = "sim_arm64"
        else:
            ios_simulator_cpus = "x86_64"

    tvos_simulator_cpus = attr.tvos_simulator_cpus
    if not tvos_simulator_cpus:
        if cpu_value == "darwin_arm64":
            tvos_simulator_cpus = "sim_arm64"
        else:
            tvos_simulator_cpus = "x86_64"

    watchos_simulator_cpus = attr.watchos_simulator_cpus
    if not watchos_simulator_cpus:
        if cpu_value == "darwin_arm64":
            watchos_simulator_cpus = "arm64"
        else:
            # rules_apple defaults to i386, but Xcode 13 requires x86_64
            watchos_simulator_cpus = "x86_64"

    return {
        "Simulator": {
            "//command_line_option:ios_multi_cpus": ios_simulator_cpus,
            "//command_line_option:tvos_cpus": tvos_simulator_cpus,
            "//command_line_option:watchos_cpus": watchos_simulator_cpus,
        },
        "Device": {
            "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
            "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
            "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
        },
    }

_target_transition = transition(
    implementation = _target_transition_impl,
    inputs = [
        "//command_line_option:cpu",
    ],
    outputs = [
        "//command_line_option:ios_multi_cpus",
        "//command_line_option:tvos_cpus",
        "//command_line_option:watchos_cpus",
    ],
)

# Rule

def _device_and_simulator_impl(ctx):
    providers = [
        merge_xcodeprojinfos([
            dep[XcodeProjInfo]
            for dep in ctx.attr.targets
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
            cfg = _target_transition,
            mandatory = True,
            allow_empty = False,
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

"""Functions for dealing with `xcodeproj` transitions."""

load(":collections.bzl", "uniq")

_BASE_TRANSITION_INPUTS = [
    "//command_line_option:cpu",
]

_BASE_TRANSITION_OUTPUTS = [
    "//command_line_option:ios_multi_cpus",
    "//command_line_option:tvos_cpus",
    "//command_line_option:watchos_cpus",
]

# buildifier: disable=function-docstring
def make_xcodeproj_target_transitions(
        *,
        implementation,
        inputs = [],
        outputs = []):
    merged_inputs = uniq(_BASE_TRANSITION_INPUTS + inputs)
    merged_outputs = uniq(_BASE_TRANSITION_OUTPUTS + outputs)

    def device_impl(settings, attr):
        base_outputs = {
            "//command_line_option:ios_multi_cpus": attr.ios_device_cpus,
            "//command_line_option:tvos_cpus": attr.tvos_device_cpus,
            "//command_line_option:watchos_cpus": attr.watchos_device_cpus,
        }

        merged_outputs = {}
        for config, config_outputs in implementation(settings, attr).items():
            o = dict(config_outputs)
            o.update(base_outputs)
            merged_outputs[config] = o

        return merged_outputs

    def simulator_impl(settings, attr):
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

        base_outputs = {
            "//command_line_option:ios_multi_cpus": ios_cpus,
            "//command_line_option:tvos_cpus": tvos_cpus,
            "//command_line_option:watchos_cpus": watchos_cpus,
        }

        merged_outputs = {}
        for config, config_outputs in implementation(settings, attr).items():
            o = dict(config_outputs)
            o.update(base_outputs)
            merged_outputs[config] = o

        return merged_outputs

    simulator_transition = transition(
        implementation = simulator_impl,
        inputs = merged_inputs,
        outputs = merged_outputs,
    )
    device_transition = transition(
        implementation = device_impl,
        inputs = merged_inputs,
        outputs = merged_outputs,
    )
    return struct(
        device = device_transition,
        simulator = simulator_transition,
    )

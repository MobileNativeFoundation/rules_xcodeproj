"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

# buildifier: disable=bzl-visibility
load(
    "@rules_xcodeproj//xcodeproj/internal:xcodeproj_aspect.bzl",
    "make_xcodeproj_aspect",
)

# buildifier: disable=bzl-visibility
load(
    "@rules_xcodeproj//xcodeproj/internal:xcodeproj_rule.bzl",
    "make_xcodeproj_rule",
)

# buildifier: disable=bzl-visibility
load(
    "@rules_xcodeproj//xcodeproj/internal:xcodeproj_transitions.bzl",
    "make_xcodeproj_target_transitions",
)

# buildifier: disable=bzl-visibility
load(
    "@rules_xcodeproj//xcodeproj/internal:fixtures.bzl",
    "fixtures_transition",
)

# Transition

_INPUTS = {}

_XCODE_CONFIGURATIONS = {"AppStore": {"//command_line_option:compilation_mode": "opt", "@//:flag_to_transition_on": "AAAAAAA"}, "Debug": {"//command_line_option:compilation_mode": "dbg", "@//:flag_to_transition_on": "B"}}

def _target_transition_implementation(settings, _attr):
    outputs = {}
    for configuration, flags in _XCODE_CONFIGURATIONS.items():
        config_outputs = {}
        for key, value in flags.items():
            if key in _INPUTS:
                # Only array settings, like "//command_line_option:features"
                # will hit this path, and we want to append instead of replace
                config_outputs[key] = settings[key] + value
            else:
                config_outputs[key] = value
        outputs[configuration] = config_outputs
    return outputs

_target_transitions = make_xcodeproj_target_transitions(
    implementation = _target_transition_implementation,
    inputs = _INPUTS.keys(),
    outputs = ["//command_line_option:compilation_mode", "@//:flag_to_transition_on"],
)

# Aspect

_aspect = make_xcodeproj_aspect(
    build_mode = "xcode",
    generator_name = "xcodeproj_bwx",
)

# Rule

xcodeproj = make_xcodeproj_rule(
    xcodeproj_aspect = _aspect,
    is_fixture = True,
    target_transitions = _target_transitions,
    xcodeproj_transition = fixtures_transition,
)

# Constants

BAZEL_ENV = {}
BAZEL_PATH = "FIXTURE_BAZEL_PATH"
WORKSPACE_DIRECTORY = "FIXTURE_WORKSPACE_DIRECTORY"

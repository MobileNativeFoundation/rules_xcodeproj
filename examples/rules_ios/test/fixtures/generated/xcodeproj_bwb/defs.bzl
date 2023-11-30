"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~override//xcodeproj/internal:xcodeproj_factory.bzl",
    "xcodeproj_factory",
)

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~override//xcodeproj/internal:xcodeproj_transitions.bzl",
    "make_xcodeproj_target_transitions",
)

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~override//xcodeproj/internal:fixtures.bzl",
    "fixtures_transition",
)

# Transition

_INPUTS = {}

_XCODE_CONFIGURATIONS = {"Debug": {}}

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
    outputs = [],
)

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    build_mode = "bazel",
    generator_name = "xcodeproj_bwb",
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    is_fixture = True,
    target_transitions = _target_transitions,
    xcodeproj_aspect = _aspect,
    xcodeproj_transition = fixtures_transition,
)

# Constants

BAZEL_ENV = {}
BAZEL_PATH = "FIXTURE_BAZEL_PATH"
WORKSPACE_DIRECTORY = "FIXTURE_WORKSPACE_DIRECTORY"

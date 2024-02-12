"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~//xcodeproj/internal:xcodeproj_factory.bzl",
    "xcodeproj_factory",
)

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~//xcodeproj/internal:xcodeproj_transitions.bzl",
    "make_xcodeproj_target_transitions",
)

# buildifier: disable=bzl-visibility
load(
    "@@rules_xcodeproj~//xcodeproj/internal:fixtures.bzl",
    "fixtures_transition",
)

_FOCUSED_LABELS = []
_OWNED_EXTRA_FILES = {"@@//Lib:README.md": "@@//Lib:Lib", "@@//iOSApp:ownership.yaml": "@@//iOSApp/Source:iOSApp"}
_UNFOCUSED_LABELS = ["@@//Lib:LibFramework.iOS"]

# Transition

_INPUTS = {}

_XCODE_CONFIGURATIONS = {"AppStore": {"//command_line_option:compilation_mode": "opt", "@@//:flag_to_transition_on": "AAAAAAA"}, "Debug": {"//command_line_option:compilation_mode": "dbg", "@@//:flag_to_transition_on": "B"}}

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
    outputs = ["//command_line_option:compilation_mode", "@@//:flag_to_transition_on"],
)

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    build_mode = "bazel",
    focused_labels = _FOCUSED_LABELS,
    generator_name = "xcodeproj_bwb",
    owned_extra_files = _OWNED_EXTRA_FILES,
    unfocused_labels = _UNFOCUSED_LABELS,
    use_incremental = False,
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    focused_labels = _FOCUSED_LABELS,
    is_fixture = True,
    owned_extra_files = _OWNED_EXTRA_FILES,
    target_transitions = _target_transitions,
    unfocused_labels = _UNFOCUSED_LABELS,
    use_incremental = False,
    xcodeproj_aspect = _aspect,
    xcodeproj_transition = fixtures_transition,
)

# Constants

BAZEL_ENV = {}
BAZEL_PATH = "FIXTURE_BAZEL_PATH"
WORKSPACE_DIRECTORY = "FIXTURE_WORKSPACE_DIRECTORY"

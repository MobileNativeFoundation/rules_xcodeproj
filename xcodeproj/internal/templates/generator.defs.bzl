"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

_FOCUSED_LABELS = %focused_labels%
_OWNED_EXTRA_FILES = %owned_extra_files%
_UNFOCUSED_LABELS = %unfocused_labels%

# Transition

%target_transitions%

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    build_mode = "%build_mode%",
    generator_name = "%generator_name%",
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    focused_labels = _FOCUSED_LABELS,
    is_fixture = %is_fixture%,
    owned_extra_files = _OWNED_EXTRA_FILES,
    target_transitions = _target_transitions,
    unfocused_labels = _UNFOCUSED_LABELS,
    xcodeproj_aspect = _aspect,
    xcodeproj_transition = %xcodeproj_transitions%,
)

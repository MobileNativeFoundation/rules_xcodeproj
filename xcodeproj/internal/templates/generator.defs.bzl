"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

_FOCUSED_LABELS = %focused_labels%
_OWNED_EXTRA_FILES = %owned_extra_files%
_UNFOCUSED_LABELS = %unfocused_labels%

# Transition

%target_transitions%

# Aspect

_aspect = make_xcodeproj_aspect(
    build_mode = "%build_mode%",
    focused_labels = _FOCUSED_LABELS,
    generator_name = "%generator_name%",
    owned_extra_files = _OWNED_EXTRA_FILES,
    unfocused_labels = _UNFOCUSED_LABELS,
)

# Rule

xcodeproj = make_xcodeproj_rule(
    xcodeproj_aspect = _aspect,
    focused_labels = _FOCUSED_LABELS,
    is_fixture = %is_fixture%,
    owned_extra_files = _OWNED_EXTRA_FILES,
    target_transitions = _target_transitions,
    unfocused_labels = _UNFOCUSED_LABELS,
    xcodeproj_transition = %xcodeproj_transitions%,
)

"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

_FOCUSED_LABELS = %focused_labels%
_UNFOCUSED_LABELS = %unfocused_labels%

# Transition

%target_transitions%

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    build_mode = "%build_mode%",
    focused_labels = _FOCUSED_LABELS,
    generator_name = "%generator_name%",
    unfocused_labels = _UNFOCUSED_LABELS,
    use_incremental = %use_incremental%,
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    focused_labels = _FOCUSED_LABELS,
    is_fixture = %is_fixture%,
    target_transitions = _target_transitions,
    unfocused_labels = _UNFOCUSED_LABELS,
    use_incremental = %use_incremental%,
    xcodeproj_aspect = _aspect,
    xcodeproj_transition = %xcodeproj_transitions%,
)

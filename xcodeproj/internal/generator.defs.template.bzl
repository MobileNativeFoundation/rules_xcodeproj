"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

# Transition

%target_transitions%

# Rule

xcodeproj = make_xcodeproj_rule(
    build_mode = "%build_mode%",
    is_fixture = %is_fixture%,
    target_transitions = _target_transitions,
    xcodeproj_transition = %xcodeproj_transitions%,
)

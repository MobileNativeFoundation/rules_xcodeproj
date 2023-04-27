"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

# Transition

%target_transitions%

# Aspect

_aspect = make_xcodeproj_aspect(
    build_mode = "%build_mode%",
    generator_name = "%generator_name%",
)

# Rule

xcodeproj = make_xcodeproj_rule(
    xcodeproj_aspect = _aspect,
    is_fixture = %is_fixture%,
    target_transitions = _target_transitions,
    xcodeproj_transition = %xcodeproj_transitions%,
)

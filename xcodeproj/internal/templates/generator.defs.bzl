"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

# Transition

%target_transitions%

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    build_mode = "%build_mode%",
    generator_name = "%generator_name%",
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    is_fixture = %is_fixture%,
    target_transitions = _target_transitions,
    xcodeproj_aspect = _aspect,
    xcodeproj_transition = %xcodeproj_transitions%,
)

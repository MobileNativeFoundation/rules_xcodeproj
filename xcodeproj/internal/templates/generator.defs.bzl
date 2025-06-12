"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

# Transition

%target_transitions%

# Aspect

_aspect = xcodeproj_factory.make_aspect(
    focused_labels = %focused_labels%,
    generator_name = "%generator_name%",
    unfocused_labels = %unfocused_labels%,
)

# Rule

xcodeproj = xcodeproj_factory.make_rule(
    target_transitions = _target_transitions,
    xcodeproj_aspect = _aspect,
)

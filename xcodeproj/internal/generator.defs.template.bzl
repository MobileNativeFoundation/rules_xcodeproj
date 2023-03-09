"Generated file used by `xcodeproj_runner`. Do not depend on it yourself."

%loads%

xcodeproj = make_xcodeproj_rule(
    build_mode = "%build_mode%",
    is_fixture = %is_fixture%,
    xcodeproj_transition = %xcodeproj_transitions%,
)

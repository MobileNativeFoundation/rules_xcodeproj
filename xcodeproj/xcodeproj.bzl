""""""

# TODO: Remove these by the 1.0 release

def _moved(name, type):
    fail("""\
The `{name}` {type} has moved to \
`@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl`. Please update \
your `load` statements to use the new path.
""".format(name = name, type = type))

# buildifier: disable=unused-variable
def top_level_target(**kwargs):
    _moved(name = "top_level_target", type = "function")

# buildifier: disable=unused-variable
def xcodeproj(**kwargs):
    _moved(name = "xcodeproj", type = "rule")

# buildifier: disable=unused-variable
def xcode_provisioning_profile(**kwargs):
    _moved(name = "xcode_provisioning_profile", type = "rule")

# buildifier: disable=unused-variable
def XcodeProjAutomaticTargetProcessingInfo(**kwargs):
    _moved(name = "XcodeProjAutomaticTargetProcessingInfo", type = "provider")

# buildifier: disable=unused-variable
def XcodeProjInfo(**kwargs):
    _moved(name = "XcodeProjInfo", type = "provider")

# buildifier: disable=unused-variable
def _xcode_schemes_function(**kwargs):
    _moved(name = "xcode_schemes", type = "module")

xcode_schemes = struct(
    scheme = _xcode_schemes_function,
    build_action = _xcode_schemes_function,
    build_target = _xcode_schemes_function,
    build_for = _xcode_schemes_function,
    build_for_values = _xcode_schemes_function,
    launch_action = _xcode_schemes_function,
    test_action = _xcode_schemes_function,
    pre_post_action = _xcode_schemes_function,
)

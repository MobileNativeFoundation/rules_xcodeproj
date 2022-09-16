"""Public evolving/experimental rules, macros, and libraries."""

# buildifier: disable=deprecated-function
load(
    "//xcodeproj/internal:device_and_simulator_macro.bzl",
    _device_and_simulator = "device_and_simulator",
)

# Re-exporting rules
device_and_simulator = _device_and_simulator

# TODO: Remove this by the 1.0 release
# buildifier: disable=unused-variable
def xcode_provisioning_profile(**kwargs):
    fail("""\
The `xcode_provisioning_profile` rule has moved to \
`@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl`. Please update \
your `load` statements to use the new path.
""")

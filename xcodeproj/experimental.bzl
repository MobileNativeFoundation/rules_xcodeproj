"""Public evolving/experimental rules, macros, and libraries."""

# buildifier: disable=deprecated-function
load(
    "//xcodeproj/internal:device_and_simulator_macro.bzl",
    _device_and_simulator = "device_and_simulator",
)
load(
    "//xcodeproj/internal:xcode_provisioning_profile.bzl",
    _xcode_provisioning_profile = "xcode_provisioning_profile",
)

# Re-exporting rules
device_and_simulator = _device_and_simulator
xcode_provisioning_profile = _xcode_provisioning_profile

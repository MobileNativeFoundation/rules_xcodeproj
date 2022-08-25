"""Public evolving/experimental rules, macros, and libraries."""

load(
    "//xcodeproj/internal:device_and_simulator_rule.bzl",
    _device_and_simulator = "device_and_simulator",
)
load(
    "//xcodeproj/internal:xcode_provisioning_profile.bzl",
    _xcode_provisioning_profile = "xcode_provisioning_profile",
)

# Re-export original rules rather than their wrapper macros
# so that stardoc documents the rule attributes, not an opaque
# **kwargs argument
device_and_simulator = _device_and_simulator
xcode_provisioning_profile = _xcode_provisioning_profile

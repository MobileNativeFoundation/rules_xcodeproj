"""Public evolving/experimental rules, macros, and libraries."""

load(
    "//xcodeproj/internal:device_and_simulator.bzl",
    _device_and_simulator = "device_and_simulator",
)

# Re-exporting rules
device_and_simulator = _device_and_simulator

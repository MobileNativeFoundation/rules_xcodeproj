"""Macro wrapper for the `device_and_simulator` rule."""

load(
    ":device_and_simulator_rule.bzl",
    _device_and_simulator = "device_and_simulator",
)

def device_and_simulator(*, name, **kwargs):
    """Configures targets to be built for both simulator and device.

    Deprecated:
        The `device_and_simulator` rule is deprecated and will be removed in a
        future rules_xcodeproj release. Please use the `top_level_target()`
        function with `xcodeproj.top_level_targets` instead.
    """
    kwargs.pop("deprecation", None)

    _device_and_simulator(
        name = name,
        deprecation = """\
The `device_and_simulator` rule is deprecated and will be removed in a future \
rules_xcodeproj release. Please use the `top_level_target()` function with \
`xcodeproj.top_level_targets` instead.
""",
        testonly = True,
        **kwargs
    )

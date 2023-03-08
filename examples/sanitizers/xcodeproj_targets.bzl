"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_schemes")

SCHEME_AUTOGENERATION_MODE = "none"

_ADDRESS_SANITIZER_TARGET = "//AddressSanitizerApp"
_THREAD_SANITIZER_TARGET = "//ThreadSanitizerApp"
_UNDEFINED_BEHAVIOR_SANITIZER_TARGET = "//UndefinedBehaviorSanitizerApp"

XCODEPROJ_TARGETS = [
    _ADDRESS_SANITIZER_TARGET,
    _THREAD_SANITIZER_TARGET,
    _UNDEFINED_BEHAVIOR_SANITIZER_TARGET,
]

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "AddressSanitizer",
            launch_action = xcode_schemes.launch_action(
                _ADDRESS_SANITIZER_TARGET,
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        address = True,
                    ),
                ),
            ),
        ),
        xcode_schemes.scheme(
            name = "ThreadSanitizer",
            launch_action = xcode_schemes.launch_action(
                _THREAD_SANITIZER_TARGET,
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        thread = True,
                    ),
                ),
            ),
        ),
        xcode_schemes.scheme(
            name = "UndefinedBehaviorSanitizer",
            launch_action = xcode_schemes.launch_action(
                _UNDEFINED_BEHAVIOR_SANITIZER_TARGET,
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        undefined_behavior = True,
                    ),
                ),
            ),
        ),
    ]

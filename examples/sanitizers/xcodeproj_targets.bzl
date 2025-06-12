"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

SCHEME_AUTOGENERATION_MODE = "none"

_ADDRESS_SANITIZER_TARGET = "//AddressSanitizerApp"
_THREAD_SANITIZER_TARGET = "//ThreadSanitizerApp"
_UNDEFINED_BEHAVIOR_SANITIZER_TARGET = "//UndefinedBehaviorSanitizerApp"

XCODEPROJ_TARGETS = [
    _ADDRESS_SANITIZER_TARGET,
    _THREAD_SANITIZER_TARGET,
    _UNDEFINED_BEHAVIOR_SANITIZER_TARGET,
]

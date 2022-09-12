"""# Providers

[Providers](https://bazel.build/rules/lib/Provider) that are used throughout
the rules in this repository.

Most users will not need to use these providers to simply create Xcode projects,
but if you want to write your own custom rules that interact with these
rules, then you will use these providers to communicate between them.
"""

load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
    _XcodeProjInfo = "XcodeProjInfo",
)

XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo
XcodeProjInfo = _XcodeProjInfo

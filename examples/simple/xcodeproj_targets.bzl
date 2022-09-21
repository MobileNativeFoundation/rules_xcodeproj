"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

XCODEPROJ_TARGETS = [
    "//:SwiftBin",
]

PRE_BUILD = "pre-build w spaces.sh"
POST_BUILD = "post-build w spaces.sh"

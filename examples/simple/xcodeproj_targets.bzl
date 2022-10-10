"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

XCODEPROJ_TARGETS = [
    "//:SwiftBin",
]

PRE_BUILD = "echo 'Pre-building...'"
POST_BUILD = """\
"$SRCROOT/post-build w spaces.sh"
"""

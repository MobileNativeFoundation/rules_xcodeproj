"""# Xcode build settings

Rules that provide additional information to the [`xcodeproj`](#xcodeproj) rule,
so that it can properly determine values for various Xcode build settings.
"""

load(
    "//xcodeproj/internal:xcode_provisioning_profile.bzl",
    _xcode_provisioning_profile = "xcode_provisioning_profile",
)

xcode_provisioning_profile = _xcode_provisioning_profile

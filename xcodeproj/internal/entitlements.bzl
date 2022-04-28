"""API to retrieve an entitlements file from a `Target`."""

load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")

def _get_file(target):
    if AppleBundleInfo in target:
        return target[AppleBundleInfo].entitlements
    return None

entitlements = struct(
    get_file = _get_file,
)

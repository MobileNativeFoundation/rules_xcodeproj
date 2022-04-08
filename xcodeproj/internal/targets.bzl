"""API for Inspecting and Acting on Targets"""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "IosXcTestBundleInfo",
    "MacosXcTestBundleInfo",
)

def _is_test_bundle_with_provider(target, deps, bundle_provider):
    """Determines whether the target is a test bundle target that provides the specified bundle provider.

    Apple test bundle targets will provide a test bundle provider and will have
    a single dep that also provides the provider.

    Args:
        target: The `Target` to evaluate.
        deps: The `list` of dependencies for the target as returned by
            `ctx.rule.attr.deps`.
        bundle_provider: A bundle provider type (e.g
            `IosXcTestBundleInfo`, `MacosXcTestBundleInfo`).

    Returns:
        A `bool` indicating whether the target is a test bundle provider of the
        specified provider.
    """
    return (
        bundle_provider in target and
        len(deps) == 1 and
        bundle_provider in deps[0]
    )

def _is_test_bundle(target, deps):
    """Determines whether the specified target is an Apple test bundle target.

    Args:
        target: The `Target` to evaluate.
        deps: The `list` of dependencies for the target as returned by
            `ctx.rule.attr.deps`.

    Returns:
        A `bool` indicating whether the target is an Apple test bundle target.
    """
    if deps == None:
        return False
    return (
        _is_test_bundle_with_provider(target, deps, IosXcTestBundleInfo) or
        _is_test_bundle_with_provider(target, deps, MacosXcTestBundleInfo)
    )

targets = struct(
    is_test_bundle = _is_test_bundle,
)

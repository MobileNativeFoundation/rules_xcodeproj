load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "IosXcTestBundleInfo",
    "MacosXcTestBundleInfo",
)

def _is_test_bundle_with_provider(target, deps, bundle_provider):
    return (
        bundle_provider in target and
        len(deps) == 1 and
        bundle_provider in deps[0]
    )

def _is_test_bundle(target, deps):
    if deps == None:
        return False
    return (
        _is_test_bundle_with_provider(target, deps, IosXcTestBundleInfo) or
        _is_test_bundle_with_provider(target, deps, MacosXcTestBundleInfo)
    )

targets = struct(
    is_test_bundle = _is_test_bundle,
)

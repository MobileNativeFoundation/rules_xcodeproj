load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "IosXcTestBundleInfo",
    "MacosXcTestBundleInfo",
)

# TODO(chuck): Try to remove ctx.

def _is_test_bundle_with_provider(ctx, target, bundle_provider):
    return (
        bundle_provider in target and
        len(ctx.rule.attr.deps) == 1 and
        bundle_provider in ctx.rule.attr.deps[0]
    )

def _is_test_bundle(ctx, target):
    return (
        _is_test_bundle_with_provider(ctx, target, IosXcTestBundleInfo) or
        _is_test_bundle_with_provider(ctx, target, MacosXcTestBundleInfo)
    )

targets = struct(
    is_test_bundle = _is_test_bundle,
)

"""Implementation of the `default_automatic_target_processing_aspect` aspect."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
)
load(":providers.bzl", "XcodeProjAutomaticTargetProcessingInfo", "target_type")

# Utility

def _get_target_type(*, target):
    # Top-level bundles
    if AppleBundleInfo in target:
        return target_type.compile

    # Libraries
    if CcInfo in target:
        return target_type.compile

    # Command-line tools
    executable = target[DefaultInfo].files_to_run.executable
    if executable and not executable.is_source:
        return target_type.compile

    return None

def _is_test_target(target):
    """Returns whether the given target is for test purposes or not."""
    if AppleBundleInfo not in target:
        return False
    return target[AppleBundleInfo].product_type in (
        "com.apple.product-type.bundle.ui-testing",
        "com.apple.product-type.bundle.unit-test",
    )

# Aspects

def _default_automatic_target_processing_aspect_impl(target, ctx):
    if XcodeProjAutomaticTargetProcessingInfo in target:
        return []

    this_target_type = _get_target_type(target = target)

    # Targets that don't produce outputs can't be Xcode targets
    should_generate_target = target.files != depset()

    if CcInfo in target:
        srcs = ("srcs")
    else:
        srcs = ()

    non_arc_srcs = ()
    pch = None
    provisioning_profile = None

    attrs = dir(ctx.rule.attr)

    if ctx.rule.kind == "cc_library":
        xcode_targets = {
            "deps": [target_type.compile],
            "interface_deps": [target_type.compile],
        }
    elif ctx.rule.kind == "objc_library":
        xcode_targets = {
            "deps": [target_type.compile],
            "runtime_deps": [target_type.compile],
        }
        non_arc_srcs = ("non_arc_srcs")
        pch = "pch"
    elif ctx.rule.kind == "swift_library":
        xcode_targets = {
            "deps": [target_type.compile],
            "private_deps": [target_type.compile],
        }
    elif ctx.rule.kind == "apple_resource_bundle":
        xcode_targets = {}

        # Ideally this would be exposed on `AppleResourceBundleInfo`
        bundle_id = "bundle_id"
        infoplists = ("infoplists")
        should_generate_target = False
    elif AppleBundleInfo in target:
        xcode_targets = {
            "deps": [target_type.compile],
        }
        if _is_test_target(target):
            xcode_targets["test_host"] = [target_type.compile]
        if "codesignopts" in attrs:
            codesignopts = "codesignopts"
        if "provisioning_profile" in attrs:
            provisioning_profile = "provisioning_profile"
        if "infoplists" in attrs:
            infoplists = ("infoplists")
        if "entitlements" in attrs:
            entitlements = "entitlements"
    elif AppleBinaryInfo in target:
        codesignopts = "codesignopts"
        if "infoplists" in attrs:
            infoplists = ("infoplists")
        xcode_targets = {"deps": [target_type.compile]}
    elif AppleFrameworkImportInfo in target:
        xcode_targets = {"deps": [target_type.compile]}
        should_generate_target = False
    else:
        xcode_targets = {"deps": [this_target_type]}

        # Command-line tools
        executable = target[DefaultInfo].files_to_run.executable
        should_generate_target = executable and not executable.is_source

    return [
        XcodeProjAutomaticTargetProcessingInfo(
            codesignopts = codesignopts,
            should_generate_target = should_generate_target,
            target_type = this_target_type,
            xcode_targets = xcode_targets,
            non_arc_srcs = non_arc_srcs,
            srcs = srcs,
            pch = pch,
            bundle_id = bundle_id,
            provisioning_profile = provisioning_profile,
            infoplists = infoplists,
            entitlements = entitlements,
        ),
    ]

default_automatic_target_processing_aspect = aspect(
    implementation = _default_automatic_target_processing_aspect_impl,
    attr_aspects = ["*"],
)

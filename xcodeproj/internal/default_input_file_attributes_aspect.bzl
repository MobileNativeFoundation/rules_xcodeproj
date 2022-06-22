"""Implementation of the `default_input_file_attributes_aspect` aspect."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
)
load(":providers.bzl", "InputFileAttributesInfo", "target_type")

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

def _default_input_file_attributes_aspect_impl(target, ctx):
    if InputFileAttributesInfo in target:
        return []

    this_target_type = _get_target_type(target = target)

    if CcInfo in target:
        srcs = ("srcs")
    else:
        srcs = ()

    non_arc_srcs = ()
    hdrs = ()
    pch = None
    bundle_id = None
    provisioning_profile = None
    infoplists = ()
    entitlements = None
    if ctx.rule.kind == "cc_library":
        xcode_targets = {
            "deps": [target_type.compile],
            "interface_deps": [target_type.compile],
        }
        hdrs = ("hdrs", "textual_hdrs")
    elif ctx.rule.kind == "cc_import":
        xcode_targets = {}
    elif ctx.rule.kind == "objc_library":
        xcode_targets = {
            "deps": [target_type.compile],
            "runtime_deps": [target_type.compile],
        }
        non_arc_srcs = ("non_arc_srcs")
        hdrs = ("hdrs", "textual_hdrs")
        pch = "pch"
    elif ctx.rule.kind == "objc_import":
        xcode_targets = {}
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
    elif ctx.rule.kind == "genrule":
        xcode_targets = {}
    elif AppleBundleInfo in target:
        xcode_targets = {
            "deps": [target_type.compile],
        }
        if _is_test_target(target):
            xcode_targets["test_host"] = [target_type.compile]
        provisioning_profile = "provisioning_profile"
        infoplists = ("infoplists")
        entitlements = "entitlements"
    elif AppleBinaryInfo in target:
        xcode_targets = {"deps": [target_type.compile]}
        infoplists = ("infoplists")
    elif AppleFrameworkImportInfo in target:
        xcode_targets = {"deps": [target_type.compile]}
    else:
        xcode_targets = {"deps": [this_target_type]}

    return [
        InputFileAttributesInfo(
            target_type = this_target_type,
            xcode_targets = xcode_targets,
            non_arc_srcs = non_arc_srcs,
            srcs = srcs,
            hdrs = hdrs,
            pch = pch,
            bundle_id = bundle_id,
            provisioning_profile = provisioning_profile,
            infoplists = infoplists,
            entitlements = entitlements,
        ),
    ]

default_input_file_attributes_aspect = aspect(
    implementation = _default_input_file_attributes_aspect_impl,
    attr_aspects = ["*"],
)

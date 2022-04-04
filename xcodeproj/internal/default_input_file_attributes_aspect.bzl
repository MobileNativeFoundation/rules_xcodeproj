"""Implementation of the `default_input_file_attributes_aspect` aspect."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load(":providers.bzl", "InputFileAttributesInfo", "target_type")

# Utility

def _get_target_type(*, ctx, target):
    if ctx.rule.kind == "apple_resource_group":
        return target_type.resources

    # Top-level bundles
    if AppleBundleInfo in target:
        return target_type.compile

    # Resources
    if AppleResourceBundleInfo in target or AppleResourceInfo in target:
        return target_type.resources

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

    this_target_type = _get_target_type(ctx = ctx, target = target)

    if CcInfo in target:
        srcs = ("srcs")
    else:
        srcs = ()

    non_arc_srcs = ()
    hdrs = ()
    resources = {}
    structured_resources = ()
    bundle_imports = ()
    if ctx.rule.kind == "cc_library":
        xcode_targets = {
            "deps": target_type.compile,
            "interface_deps": target_type.compile,
        }
        excluded = ("deps", "interface_deps", "win_def_file")
        hdrs = ("hdrs", "textual_hdrs")
        resources = {
            "deps": target_type.compile,
            "interface_deps": target_type.compile,
        }
    elif ctx.rule.kind == "objc_library":
        xcode_targets = {
            "deps": target_type.compile,
            "runtime_deps": target_type.compile,
            "data": target_type.resources,
        }
        excluded = ("deps", "runtime_deps")
        non_arc_srcs = ("non_arc_srcs")
        hdrs = ("hdrs", "textual_hdrs")
        resources = {
            "deps": target_type.compile,
            "runtime_deps": target_type.compile,
            "data": target_type.resources,
        }
    elif ctx.rule.kind == "swift_library":
        xcode_targets = {
            "deps": target_type.compile,
            "private_deps": target_type.compile,
            "data": target_type.resources,
        }
        excluded = ("deps", "private_deps")
        resources = {
            "deps": target_type.compile,
            "private_deps": target_type.compile,
            "data": target_type.resources,
        }
    elif (ctx.rule.kind == "apple_resource_group" or
          ctx.rule.kind == "apple_resource_bundle"):
        xcode_targets = {"resources": target_type.resources}
        excluded = ()
        resources = {"resources": target_type.resources}
        structured_resources = ("structured_resources")
    elif ctx.rule.kind == "apple_bundle_import":
        xcode_targets = {}
        excluded = ()
        bundle_imports = ("bundle_imports")
    elif ctx.rule.kind == "genrule":
        xcode_targets = {}
        excluded = ("tools")
    elif AppleBundleInfo in target:
        xcode_targets = {
            "deps": target_type.compile,
            "resources": target_type.resources,
        }
        excluded = ["deps", "extensions", "frameworks"]
        if _is_test_target(target):
            xcode_targets["test_host"] = target_type.compile
            excluded.append("test_host")
        resources = {
            "deps": target_type.compile,
            "resources": target_type.resources,
        }
    else:
        xcode_targets = {"deps": this_target_type}
        excluded = ("deps")
        resources = {"deps": this_target_type}

    return [
        InputFileAttributesInfo(
            target_type = this_target_type,
            xcode_targets = xcode_targets,
            excluded = excluded,
            non_arc_srcs = non_arc_srcs,
            srcs = srcs,
            hdrs = hdrs,
            resources = resources,
            structured_resources = structured_resources,
            bundle_imports = bundle_imports,
        ),
    ]

default_input_file_attributes_aspect = aspect(
    implementation = _default_input_file_attributes_aspect_impl,
    attr_aspects = ["*"],
)

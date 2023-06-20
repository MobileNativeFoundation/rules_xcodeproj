"""Functions for calculating automatic target info."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
    "AppleResourceBundleInfo",
)
load(":memory_efficiency.bzl", "EMPTY_LIST", "NONE_LIST")
load(":providers.bzl", "XcodeProjAutomaticTargetProcessingInfo", "target_type")

## Utility

_UNSUPPORTED_SRCS_EXTENSIONS = {
    "a": True,
    "lo": True,
    "o": True,
    "so": True,
}

def _get_target_type(*, target):
    # Top-level bundles
    if AppleBundleInfo in target:
        return target_type.compile

    # Resource bundles
    if AppleResourceBundleInfo in target:
        return None

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

## Aspects

# These are declared as constants to cause starlark to reuse the same instances
# instead of allocating and retaining new ones for each target

_BINARY_DEPS_ATTRS = ["binary"]
_DEPS_ATTRS = ["deps"]
_EXPORTED_SYMBOLS_LISTS_ATTRS = ["exported_symbols_lists"]
_HDRS_DEPS_ATTRS = ["hdrs"]
_IMPLEMENTATION_DEPS_ATTRS = ["implementation_deps"]
_INFOPLISTS_ATTRS = ["infoplists"]
_LAUNCHDPLISTS_ATTRS = ["launchdplists"]
_NON_ARC_SRCS_ATTRS = ["non_arc_srcs"]
_SRCS_ATTRS = ["srcs"]

_LINK_MNEMONICS = ["ObjcLink", "CppLink"]

_SWIFT_BINARY_RULES = {
    "swift_binary": None,
    "swift_test": None,
}

_XCODE_TARGET_TYPES_COMPILE = [target_type.compile]
_XCODE_TARGET_TYPES_COMPILE_AND_NONE = [target_type.compile, None]

_BINARY_XCODE_TARGETS = {
    "binary": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
}
_DEPS_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
}
_DEPS_ONLY_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE,
}
_EMPTY_XCODE_TARGETS = {}
_CC_LIBRARY_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "implementation_deps": _XCODE_TARGET_TYPES_COMPILE,
}
_BUNDLE_XCODE_TARGETS = {
    "app_clips": _XCODE_TARGET_TYPES_COMPILE,
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "extension": _XCODE_TARGET_TYPES_COMPILE,
    "extensions": _XCODE_TARGET_TYPES_COMPILE,
    "frameworks": _XCODE_TARGET_TYPES_COMPILE,
    "watch_application": _XCODE_TARGET_TYPES_COMPILE,
}
_OBJC_LIBRARY_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    # Issues like https://github.com/bazelbuild/bazel/issues/17646 made some Bazel users
    # to fork Bazel and add implementation_deps attribute for objc_library_rule.
    # TODO: Add link to changes for more context
    "implementation_deps": _XCODE_TARGET_TYPES_COMPILE,
    "runtime_deps": _XCODE_TARGET_TYPES_COMPILE,
}
_PLUGINS_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "plugins": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
}
_SWIFT_LIBRARY_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "plugins": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "private_deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
}
_TEST_BUNDLE_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "frameworks": _XCODE_TARGET_TYPES_COMPILE,
    "test_host": _XCODE_TARGET_TYPES_COMPILE,
}

_DEFAULT_XCODE_TARGETS = {
    target_type.compile: _DEPS_XCODE_TARGETS,
    None: {"deps": NONE_LIST},
}

def calculate_automatic_target_info(ctx, build_mode, target):
    """Calculates the automatic target info for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to calculate the automatic target info for.

    Returns:
        A `XcodeProjAutomaticTargetProcessingInfo` provider.
    """
    if XcodeProjAutomaticTargetProcessingInfo in target:
        return target[XcodeProjAutomaticTargetProcessingInfo]

    this_target_type = _get_target_type(target = target)

    if CcInfo in target:
        srcs = _SRCS_ATTRS
    else:
        srcs = EMPTY_LIST

    alternate_icons = None
    app_icons = None
    args = None
    bundle_id = None
    codesignopts = None
    deps = _DEPS_ATTRS
    entitlements = None
    env = None
    exported_symbols_lists = EMPTY_LIST
    hdrs = EMPTY_LIST
    implementation_deps = EMPTY_LIST
    infoplists = EMPTY_LIST
    launchdplists = EMPTY_LIST
    link_mnemonics = _LINK_MNEMONICS
    non_arc_srcs = EMPTY_LIST
    pch = None
    provisioning_profile = None
    collect_uncategorized_files = False
    should_generate_target = True

    rule_kind = ctx.rule.kind

    if rule_kind == "cc_library":
        implementation_deps = _IMPLEMENTATION_DEPS_ATTRS
        xcode_targets = _CC_LIBRARY_XCODE_TARGETS
    elif rule_kind == "objc_library":
        implementation_deps = _IMPLEMENTATION_DEPS_ATTRS
        non_arc_srcs = _NON_ARC_SRCS_ATTRS
        pch = "pch"
        xcode_targets = _OBJC_LIBRARY_XCODE_TARGETS
    elif rule_kind == "swift_library":
        xcode_targets = _SWIFT_LIBRARY_XCODE_TARGETS
    elif rule_kind == "apple_resource_bundle":
        should_generate_target = False

        # Ideally this would be exposed on `AppleResourceBundleInfo`
        bundle_id = "bundle_id"
        infoplists = _INFOPLISTS_ATTRS
        xcode_targets = _EMPTY_XCODE_TARGETS
    elif rule_kind == "apple_resource_group":
        should_generate_target = False
        xcode_targets = _EMPTY_XCODE_TARGETS
    elif _is_test_target(target):
        args = "args"
        codesignopts = "codesignopts"
        entitlements = "entitlements"
        env = "env"
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        provisioning_profile = "provisioning_profile"
        xcode_targets = _TEST_BUNDLE_XCODE_TARGETS
    elif AppleBundleInfo in target and target[AppleBundleInfo].binary:
        # Checking for `binary` being set is to work around a rules_ios issue
        alternate_icons = "alternate_icons"
        app_icons = "app_icons"
        codesignopts = "codesignopts"
        entitlements = "entitlements"
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        hdrs = _HDRS_DEPS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        provisioning_profile = "provisioning_profile"
        xcode_targets = _BUNDLE_XCODE_TARGETS
    elif AppleBundleInfo in target:
        should_generate_target = False
        collect_uncategorized_files = rule_kind != "apple_bundle_import"
        xcode_targets = _DEFAULT_XCODE_TARGETS[this_target_type]
    elif rule_kind == "macos_command_line_application":
        codesignopts = "codesignopts"
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        launchdplists = _LAUNCHDPLISTS_ATTRS
        xcode_targets = _DEPS_XCODE_TARGETS
    elif rule_kind in _SWIFT_BINARY_RULES:
        srcs = _SRCS_ATTRS
        xcode_targets = _PLUGINS_XCODE_TARGETS
    elif rule_kind == "apple_universal_binary":
        deps = _BINARY_DEPS_ATTRS
        xcode_targets = _BINARY_XCODE_TARGETS
    elif AppleFrameworkImportInfo in target:
        if (getattr(ctx.rule.attr, "bundle_only", False) and
            build_mode == "xcode"):
            fail("""\
`bundle_only` can't be `True` on {} when `build_mode = \"xcode\"`
""".format(target.label))

        should_generate_target = False
        collect_uncategorized_files = False
        xcode_targets = _DEPS_ONLY_XCODE_TARGETS
    else:
        # Command-line tools
        executable = target[DefaultInfo].files_to_run.executable
        is_executable = executable and not executable.is_source

        should_generate_target = is_executable
        collect_uncategorized_files = not should_generate_target
        if is_executable and hasattr(ctx.rule.attr, "srcs"):
            srcs = _SRCS_ATTRS

        xcode_targets = _DEFAULT_XCODE_TARGETS[this_target_type]

    # Xcode doesn't support some source types that Bazel supports
    for attr in srcs:
        for file in getattr(ctx.rule.files, attr, []):
            if _UNSUPPORTED_SRCS_EXTENSIONS.get(file.extension):
                should_generate_target = False
                break

    return XcodeProjAutomaticTargetProcessingInfo(
        alternate_icons = alternate_icons,
        app_icons = app_icons,
        args = args,
        bundle_id = bundle_id,
        codesignopts = codesignopts,
        collect_uncategorized_files = collect_uncategorized_files,
        deps = deps,
        entitlements = entitlements,
        env = env,
        exported_symbols_lists = exported_symbols_lists,
        hdrs = hdrs,
        infoplists = infoplists,
        implementation_deps = implementation_deps,
        launchdplists = launchdplists,
        link_mnemonics = link_mnemonics,
        non_arc_srcs = non_arc_srcs,
        pch = pch,
        provisioning_profile = provisioning_profile,
        should_generate_target = should_generate_target,
        srcs = srcs,
        target_type = this_target_type,
        xcode_targets = xcode_targets,
    )

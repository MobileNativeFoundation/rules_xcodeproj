"""Functions for calculating automatic target info."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
    "AppleResourceBundleInfo",
)
load(":memory_efficiency.bzl", "EMPTY_LIST", "NONE_LIST")
load(":xcodeprojinfo.bzl", "target_type")

## Utility

_TEST_TARGET_PRODUCT_TYPES = {
    "com.apple.product-type.bundle.ui-testing": None,
    "com.apple.product-type.bundle.unit-test": None,
}

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

def _has_values_in(attrs, *, attr):
    for name in attrs:
        if getattr(attr, name, None):
            return True
    return False

def _is_test_target(target):
    """Returns whether the given target is for test purposes or not."""
    if AppleBundleInfo not in target:
        return False
    return target[AppleBundleInfo].product_type in _TEST_TARGET_PRODUCT_TYPES

## Provider

XcodeProjAutomaticTargetProcessingInfo = provider(
    """\
Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return an `XcodeProjInfo` provider instance instead.

> [!WARNING]
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.
""",
    fields = {
        # TODO: Remove when dropping legacy generation mode
        "alternate_icons": """\
An attribute name (or `None`) to collect the application alternate icons.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "app_icons": """\
An attribute name (or `None`) to collect the application icons.
""",
        "args": """\
A `List` (or `None`) representing the command line arguments that this target
should execute or test with.
""",
        "bundle_id": """\
An attribute name (or `None`) to collect the bundle id string from.
""",
        # TODO: Remove when dropping legacy generation mode
        "codesign_inputs": """\
An attribute name (or `None`) to collect the `codesign_inputs` `list` from.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        # TODO: Remove when dropping legacy generation mode
        "codesignopts": """\
An attribute name (or `None`) to collect the `codesignopts` `list` from.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "collect_uncategorized_files": """\
Whether to collect files from uncategorized attributes.
""",
        "deps": """\
A sequence of attribute names to collect `Target`s from for `deps`-like
attributes.
""",
        "entitlements": """\
An attribute name (or `None`) to collect `File`s from for the
`entitlements`-like attribute.
""",
        "env": """\
A `dict` representing the environment variables that this target should execute
or test with.
""",
        # TODO: Remove when dropping legacy generation mode
        "exported_symbols_lists": """\
A sequence of attribute names to collect `File`s from for the
`exported_symbols_lists`-like attributes.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "extra_files": """\
A sequence of attribute names to collect `File`s from to include in the project,
which don't fall under other categorized attributes.

This is only used when `xcodeproj.generation_mode = "incremental"` is set.
""",
        # TODO: Remove when dropping legacy generation mode
        "hdrs": """\
A sequence of attribute names to collect `File`s from for `hdrs`-like
attributes.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "implementation_deps": """\
A sequence of attribute names to collect `Target`s from for
`implementation_deps`-like attributes.
""",
        # TODO: Remove when dropping legacy generation mode
        "infoplists": """\
A sequence of attribute names to collect `File`s from for the `infoplists`-like
attributes.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "is_supported": """\
Whether an Xcode target can be generated for this target. Even if this value is
`False`, setting values for the other attributes can cause inputs to be
collected and shown in the Xcode project.
""",
        "is_top_level": """\
Whether this target is a "top-level" (e.g. bundled or executable) target.
""",
        "label": """\
The effective `Label` to use for the target. This should generally be
`target.label`, but in the case of skipped wrapper rules (e.g. `*_unit_test`
targets), you might want to rename the target to the skipped target's label.

This is only used when `xcodeproj.generation_mode = "incremental"` is set.
""",
        # TODO: Remove when dropping legacy generation mode
        "launchdplists": """\
A sequence of attribute names to collect `File`s from for the
`launchdplists`-like attributes.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "link_mnemonics": """\
A sequence of mnemonic (action) names to gather link parameters. The first
action that matches any of the mnemonics is used.
""",
        "non_arc_srcs": """\
A sequence of attribute names to collect `File`s from for `non_arc_srcs`-like
attributes.
""",
        "pch": """\
An attribute name (or `None`) to collect `File`s from for the `pch`-like
attribute.

This is only used when `xcodeproj.generation_mode = "legacy"` is set.
""",
        "provisioning_profile": """\
An attribute name (or `None`) to collect `File`s from for the
`provisioning_profile`-like attribute.
""",
        "should_generate": """\
If `is_supported` is `True`, this determines whether an Xcode target should be
generated for this target.

This is only used when `xcodeproj.generation_mode = "incremental"` is set.
""",
        "srcs": """\
A sequence of attribute names to collect `File`s from for `srcs`-like
attributes.
""",
        "target_type": "See `XcodeProjInfo.target_type`.",
        "xcode_targets": """\
A `dict` mapping attribute names to target type strings (i.e. "resource" or
"compile"). Only Xcode targets from the specified attributes with the specified
target type are allowed to propagate.
""",
    },
)

## API

# These are declared as constants to cause starlark to reuse the same instances
# instead of allocating and retaining new ones for each target

_BINARY_DEPS_ATTRS = ["binary"]

# @unsorted-dict-items
_BUNDLE_DEPS_ATTRS = [
    "deps",

    # rules_ios
    "private_deps",
    "transitive_deps",
]
_CMAKE_SRCS_ATTRS = ["lib_source"]
_DEPS_ATTRS = ["deps"]
_EXPORTED_SYMBOLS_LISTS_ATTRS = ["exported_symbols_lists"]
_HDRS_DEPS_ATTRS = ["hdrs"]
_IMPLEMENTATION_DEPS_ATTRS = ["implementation_deps"]
_INFOPLISTS_ATTRS = ["infoplists"]
_LAUNCHDPLISTS_ATTRS = ["launchdplists"]
_NON_ARC_SRCS_ATTRS = ["non_arc_srcs"]
_SRCS_ATTRS = ["srcs"]

_BUNDLE_EXTRA_FILES_ATTRS = [
    "additional_linker_inputs",
    "alternate_icons",
    "codesign_inputs",
    "exported_symbols_lists",
    "hdrs",
    "infoplists",
    "launchdplists",
]
_CC_LIBRARY_EXTRA_FILES_ATTRS = [
    "additional_compiler_inputs",
    "additional_linker_inputs",
]
_COMMAND_LINE_EXTRA_FILES_ATTRS = [
    "codesign_inputs",
    "exported_symbols_lists",
    "launchdplists",
    "infoplists",
]
_OBJC_LIBRARY_EXTRA_FILES_ATTRS = [
    "pch",
]
_RESOURCE_BUNDLE_EXTRA_FILES_ATTRS = [
    "infoplists",
]
_SWIFT_COMPILATION_EXTRA_FILES_ATTRS = [
    "swiftc_inputs",
]
_TEST_EXTRA_FILES_ATTRS = [
    "codesign_inputs",
    "exported_symbols_lists",
    "infoplists",
]

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

# @unsorted-dict-items
_BUNDLE_XCODE_TARGETS = {
    "app_clips": _XCODE_TARGET_TYPES_COMPILE,
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "extension": _XCODE_TARGET_TYPES_COMPILE,
    "extensions": _XCODE_TARGET_TYPES_COMPILE,
    "frameworks": _XCODE_TARGET_TYPES_COMPILE,
    "watch_application": _XCODE_TARGET_TYPES_COMPILE,

    # rules_ios
    "private_deps": _XCODE_TARGET_TYPES_COMPILE,
    "transitive_deps": _XCODE_TARGET_TYPES_COMPILE,
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
_SWIFT_GRPC_LIBRARY_XCODE_TARGETS = {
    "deps": _XCODE_TARGET_TYPES_COMPILE_AND_NONE,
    "_proto_support": _XCODE_TARGET_TYPES_COMPILE,
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

def calculate_automatic_target_info(
        *,
        ctx,
        build_mode = "bazel",
        rule_attr,
        rule_kind,
        target):
    """Calculates the automatic target info for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        rule_attr: `ctx.rule.attr`.
        rule_kind: `ctx.rule.kind`.
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
    codesign_inputs = None
    codesignopts = None
    collect_uncategorized_files = False
    deps = _DEPS_ATTRS
    entitlements = None
    env = None
    extra_files = EMPTY_LIST
    exported_symbols_lists = EMPTY_LIST
    hdrs = EMPTY_LIST
    implementation_deps = EMPTY_LIST
    infoplists = EMPTY_LIST
    is_supported = True
    is_top_level = False
    label = target.label
    launchdplists = EMPTY_LIST
    link_mnemonics = _LINK_MNEMONICS
    non_arc_srcs = EMPTY_LIST
    pch = None
    provisioning_profile = None

    if rule_kind == "cc_library":
        extra_files = _CC_LIBRARY_EXTRA_FILES_ATTRS
        implementation_deps = _IMPLEMENTATION_DEPS_ATTRS
        xcode_targets = _CC_LIBRARY_XCODE_TARGETS

        is_supported = (
            bool(target.files) and
            _has_values_in(_SRCS_ATTRS, attr = rule_attr)
        )
    elif rule_kind == "objc_library":
        extra_files = _OBJC_LIBRARY_EXTRA_FILES_ATTRS
        implementation_deps = _IMPLEMENTATION_DEPS_ATTRS
        non_arc_srcs = _NON_ARC_SRCS_ATTRS
        pch = "pch"
        xcode_targets = _OBJC_LIBRARY_XCODE_TARGETS

        is_supported = (
            bool(target.files) and (
                _has_values_in(_SRCS_ATTRS, attr = rule_attr) or
                _has_values_in(_NON_ARC_SRCS_ATTRS, attr = rule_attr)
            )
        )
    elif rule_kind == "swift_library":
        extra_files = _SWIFT_COMPILATION_EXTRA_FILES_ATTRS
        xcode_targets = _SWIFT_LIBRARY_XCODE_TARGETS
    elif rule_kind == "swift_grpc_library":
        srcs = EMPTY_LIST
        xcode_targets = _SWIFT_GRPC_LIBRARY_XCODE_TARGETS
    elif rule_kind == "swift_proto_library":
        xcode_targets = _DEPS_XCODE_TARGETS
    elif (AppleResourceBundleInfo in target and
          rule_kind != "apple_bundle_import"):
        is_supported = False
        collect_uncategorized_files = rule_kind != "apple_resource_bundle"

        # Ideally this would be exposed on `AppleResourceBundleInfo`
        bundle_id = "bundle_id"
        extra_files = _RESOURCE_BUNDLE_EXTRA_FILES_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        xcode_targets = _EMPTY_XCODE_TARGETS
    elif rule_kind == "apple_resource_group":
        is_supported = False
        xcode_targets = _EMPTY_XCODE_TARGETS
    elif _is_test_target(target):
        args = "args"
        codesign_inputs = "codesign_inputs"
        codesignopts = "codesignopts"
        entitlements = "entitlements"
        env = "env"
        extra_files = _TEST_EXTRA_FILES_ATTRS
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        is_top_level = True
        provisioning_profile = "provisioning_profile"
        xcode_targets = _TEST_BUNDLE_XCODE_TARGETS

        label = Label(
            # This is an implementation detail, but we can update if rules_apple
            # ever changes this. It's worth it to be able to do this change at
            # the aspect level. We only support rules_apple versions greater
            # than 2.5.0, if the `bundle_name` attribute is set, since
            # 2.3.0-2.5.0 had the bundle name instead of target name as part of
            # the label.
            str(label).split(".__internal__.")[0],
        )
    elif AppleBundleInfo in target and target[AppleBundleInfo].binary:
        # Checking for `binary` being set is to work around a rules_ios issue
        alternate_icons = "alternate_icons"
        app_icons = "app_icons"
        codesign_inputs = "codesign_inputs"
        codesignopts = "codesignopts"
        deps = _BUNDLE_DEPS_ATTRS
        entitlements = "entitlements"
        extra_files = _BUNDLE_EXTRA_FILES_ATTRS
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        hdrs = _HDRS_DEPS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        is_top_level = True
        provisioning_profile = "provisioning_profile"
        xcode_targets = _BUNDLE_XCODE_TARGETS
    elif AppleBundleInfo in target:
        is_supported = False
        collect_uncategorized_files = rule_kind != "apple_bundle_import"
        xcode_targets = _DEFAULT_XCODE_TARGETS[this_target_type]
    elif rule_kind == "macos_command_line_application":
        codesign_inputs = "codesign_inputs"
        codesignopts = "codesignopts"
        extra_files = _COMMAND_LINE_EXTRA_FILES_ATTRS
        exported_symbols_lists = _EXPORTED_SYMBOLS_LISTS_ATTRS
        infoplists = _INFOPLISTS_ATTRS
        is_top_level = True
        launchdplists = _LAUNCHDPLISTS_ATTRS
        xcode_targets = _DEPS_XCODE_TARGETS
    elif rule_kind in _SWIFT_BINARY_RULES:
        extra_files = _SWIFT_COMPILATION_EXTRA_FILES_ATTRS
        srcs = _SRCS_ATTRS
        is_top_level = True
        xcode_targets = _PLUGINS_XCODE_TARGETS
    elif rule_kind == "apple_universal_binary":
        deps = _BINARY_DEPS_ATTRS
        is_supported = False
        is_top_level = True
        xcode_targets = _BINARY_XCODE_TARGETS
    elif AppleFrameworkImportInfo in target:
        if (getattr(rule_attr, "bundle_only", False) and
            build_mode == "xcode"):
            fail("""\
`bundle_only` can't be `True` on {} when `build_mode = \"xcode\"`
""".format(target.label))

        is_supported = False
        xcode_targets = _DEPS_ONLY_XCODE_TARGETS
    elif rule_kind == "cmake":
        is_supported = False
        srcs = _CMAKE_SRCS_ATTRS
        xcode_targets = _DEFAULT_XCODE_TARGETS[this_target_type]
    else:
        # Command-line tools
        executable = target[DefaultInfo].files_to_run.executable
        is_executable = bool(executable and not executable.is_source)
        is_top_level = is_executable

        is_supported = is_executable
        collect_uncategorized_files = not is_supported
        if is_executable and hasattr(rule_attr, "srcs"):
            srcs = _SRCS_ATTRS

        xcode_targets = _DEFAULT_XCODE_TARGETS[this_target_type]

    # Xcode doesn't support some source types that Bazel supports
    for attr in srcs:
        for file in getattr(ctx.rule.files, attr, []):
            if _UNSUPPORTED_SRCS_EXTENSIONS.get(file.extension):
                is_supported = False
                break

    return XcodeProjAutomaticTargetProcessingInfo(
        alternate_icons = alternate_icons,
        app_icons = app_icons,
        args = args,
        bundle_id = bundle_id,
        codesign_inputs = codesign_inputs,
        codesignopts = codesignopts,
        collect_uncategorized_files = collect_uncategorized_files,
        deps = deps,
        entitlements = entitlements,
        env = env,
        extra_files = extra_files,
        exported_symbols_lists = exported_symbols_lists,
        hdrs = hdrs,
        infoplists = infoplists,
        is_supported = is_supported,
        is_top_level = is_top_level,
        implementation_deps = implementation_deps,
        label = label,
        launchdplists = launchdplists,
        link_mnemonics = link_mnemonics,
        non_arc_srcs = non_arc_srcs,
        pch = pch,
        provisioning_profile = provisioning_profile,
        should_generate = True,
        srcs = srcs,
        target_type = this_target_type,
        xcode_targets = xcode_targets,
    )

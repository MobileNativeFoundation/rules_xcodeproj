"""Implementation of the `default_automatic_target_processing_aspect` aspect."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
    "AppleBundleInfo",
    "AppleFrameworkImportInfo",
    "AppleResourceBundleInfo",
)
load(":providers.bzl", "XcodeProjAutomaticTargetProcessingInfo", "target_type")

# Utility

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

# Aspects

def _default_automatic_target_processing_aspect_impl(target, ctx):
    if XcodeProjAutomaticTargetProcessingInfo in target:
        return []

    this_target_type = _get_target_type(target = target)

    if CcInfo in target:
        srcs = ["srcs"]
    else:
        srcs = []

    alternate_icons = None
    app_icons = None
    args = None
    bundle_id = None
    codesignopts = None
    deps = ["deps"]
    entitlements = None
    env = None
    exported_symbols_lists = []
    hdrs = []
    infoplists = []
    launchdplists = []
    link_mnemonics = ["ObjcLink", "CppLink"]
    bazel_build_mode_error = None
    non_arc_srcs = []
    pch = None
    provisioning_profile = None
    should_generate_target = True

    attrs = dir(ctx.rule.attr)

    if ctx.rule.kind == "cc_library":
        xcode_targets = {
            "deps": [target_type.compile, None],
            "implementation_deps": [target_type.compile],
            "interface_deps": [target_type.compile],
        }
    elif ctx.rule.kind == "objc_library":
        xcode_targets = {
            "deps": [target_type.compile, None],
            # Issues like https://github.com/bazelbuild/bazel/issues/17646 made some Bazel users 
            # to fork Bazel and add implementation_deps attribute for objc_library_rule.
            # TODO: Add link to changes for more context
            # handle case when objc_library rule has attribute implementation_deps
            "implementation_deps": [target_type.compile],
            "runtime_deps": [target_type.compile],
        }
        non_arc_srcs = ["non_arc_srcs"]
        pch = "pch"
    elif ctx.rule.kind == "swift_library":
        xcode_targets = {
            "deps": [target_type.compile, None],
            "private_deps": [target_type.compile, None],
        }
    elif ctx.rule.kind == "apple_resource_bundle":
        xcode_targets = {}

        # Ideally this would be exposed on `AppleResourceBundleInfo`
        bundle_id = "bundle_id"
        infoplists = ["infoplists"]
        should_generate_target = False
    elif AppleBundleInfo in target and target[AppleBundleInfo].binary:
        # Checking for `binary` being set is to work around a rules_ios issue
        xcode_targets = {
            "deps": [target_type.compile, None],
        }
        if _is_test_target(target):
            xcode_targets["test_host"] = [target_type.compile]
            env = "env"
            if "args" in attrs:
                args = "args"
        if "alternate_icons" in attrs:
            alternate_icons = "alternate_icons"
        if "app_clips" in attrs:
            xcode_targets["app_clips"] = [target_type.compile]
        if "app_icons" in attrs:
            app_icons = "app_icons"
        if "codesignopts" in attrs:
            codesignopts = "codesignopts"
        if "entitlements" in attrs:
            entitlements = "entitlements"
        if "exported_symbols_lists" in attrs:
            exported_symbols_lists = ["exported_symbols_lists"]
        if "extension" in attrs:
            xcode_targets["extension"] = [target_type.compile]
        if "extensions" in attrs:
            xcode_targets["extensions"] = [target_type.compile]
        if "frameworks" in attrs:
            xcode_targets["frameworks"] = [target_type.compile]
        if "hdrs" in attrs:
            hdrs = ["hdrs"]
        if "infoplists" in attrs:
            infoplists = ["infoplists"]
        if "provisioning_profile" in attrs:
            provisioning_profile = "provisioning_profile"
        if "watch_application" in attrs:
            xcode_targets["watch_application"] = [target_type.compile]
    elif AppleBundleInfo in target:
        should_generate_target = False
        xcode_targets = {
            "deps": [this_target_type, None],
        }
    elif AppleBinaryInfo in target:
        if "binary" in attrs:
            deps_attr = "binary"
        else:
            deps_attr = "deps"
        deps = [deps_attr]

        if "codesignopts" in attrs:
            codesignopts = "codesignopts"
        if "exported_symbols_lists" in attrs:
            exported_symbols_lists = ["exported_symbols_lists"]
        if "infoplists" in attrs:
            infoplists = ["infoplists"]
        if "launchdplists" in attrs:
            launchdplists = ["launchdplists"]
        xcode_targets = {
            deps_attr: [target_type.compile, None],
        }
    elif AppleFrameworkImportInfo in target:
        xcode_targets = {"deps": [target_type.compile]}
        if getattr(ctx.rule.attr, "bundle_only", False):
            bazel_build_mode_error = """\
`bundle_only` can't be `True` on {} when `build_mode = \"xcode\"`
""".format(target.label)

        should_generate_target = False
    else:
        xcode_targets = {
            "deps": [this_target_type, None],
        }

        # Command-line tools
        executable = target[DefaultInfo].files_to_run.executable
        is_executable = executable and not executable.is_source

        should_generate_target = is_executable
        if is_executable and "srcs" in attrs:
            srcs = ["srcs"]

    # Xcode doesn't support some source types that Bazel supports
    for attr in srcs:
        for file in getattr(ctx.rule.files, attr, []):
            if _UNSUPPORTED_SRCS_EXTENSIONS.get(file.extension):
                should_generate_target = False
                break

    return [
        XcodeProjAutomaticTargetProcessingInfo(
            all_attrs = attrs,
            alternate_icons = alternate_icons,
            app_icons = app_icons,
            args = args,
            bazel_build_mode_error = bazel_build_mode_error,
            bundle_id = bundle_id,
            codesignopts = codesignopts,
            deps = deps,
            entitlements = entitlements,
            env = env,
            exported_symbols_lists = exported_symbols_lists,
            hdrs = hdrs,
            infoplists = infoplists,
            launchdplists = launchdplists,
            link_mnemonics = link_mnemonics,
            non_arc_srcs = non_arc_srcs,
            pch = pch,
            provisioning_profile = provisioning_profile,
            should_generate_target = should_generate_target,
            srcs = srcs,
            target_type = this_target_type,
            xcode_targets = xcode_targets,
        ),
    ]

default_automatic_target_processing_aspect = aspect(
    implementation = _default_automatic_target_processing_aspect_impl,
    attr_aspects = ["*"],
)

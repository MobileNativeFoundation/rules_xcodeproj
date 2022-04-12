"""API for Inspecting and Acting on Targets"""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
    "IosXcTestBundleInfo",
    "MacosXcTestBundleInfo",
    "TvosXcTestBundleInfo",
    "WatchosXcTestBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")

# Target Classification

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
        _is_test_bundle_with_provider(target, deps, MacosXcTestBundleInfo) or
        _is_test_bundle_with_provider(target, deps, TvosXcTestBundleInfo) or
        _is_test_bundle_with_provider(target, deps, WatchosXcTestBundleInfo)
    )

def _should_become_xcode_target(target):
    """Determines if the given target should be included in the Xcode project.

    Args:
        target: The `Target` to check.

    Returns:
        `False` if `target` shouldn't become an actual target in the generated
        Xcode project. Resource bundles are a current example of this, as we
        only include their files in the project, but we don't create targets
        for them.
    """

    # Top-level bundles
    if AppleBundleInfo in target:
        return True

    # Resource bundles
    if AppleResourceBundleInfo in target and AppleResourceInfo not in target:
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        return True

    # Libraries
    # Targets that don't produce files are ignored (e.g. imports)
    if CcInfo in target and target.files != depset():
        return True

    # Command-line tools
    executable = target[DefaultInfo].files_to_run.executable
    if executable and not executable.is_source:
        return True

    return False

# Outputs

def _swift_module_output(module):
    """Generates information about the target's Swift module.

    Args:
        module: The value returned from `swift_common.create_module()`. See
            https://github.com/bazelbuild/rules_swift/blob/master/doc/api.md#swift_commoncreate_module.

    Returns:
        A `dict` containing the Swift module's output information. See
        `Output.SwiftModule` in `//tools/generator/src:DTO.swift` for what it
        transforms into.
    """
    swift = module.swift

    output = {
        "name": module.name + ".swiftmodule",
        "swiftdoc": swift.swiftdoc.path,
        "swiftmodule": swift.swiftmodule.path,
    }
    if swift.swiftsourceinfo:
        output["swiftsourceinfo"] = swift.swiftsourceinfo.path
    if swift.swiftinterface:
        output["swiftinterface"] = swift.swiftinterface.path

    return output

def _get_outputs(target):
    """Generates information about the target's outputs.

    Args:
        target: The `Target` the output information is gathered from.

    Returns:
        A `dict` containing the targets output information. See `Output` in
        `//tools/generator/src:DTO.swift` for what it transforms into.
    """
    outputs = {}
    if OutputGroupInfo in target:
        if "dsyms" in target[OutputGroupInfo]:
            outputs["dsyms"] = [
                file.path
                for file in target[OutputGroupInfo].dsyms.to_list()
            ]
    if SwiftInfo in target:
        outputs["swift_module"] = _swift_module_output([
            module
            for module in target[SwiftInfo].direct_modules
            if module.swift
        ][0])
    return outputs

targets = struct(
    get_outputs = _get_outputs,
    is_test_bundle = _is_test_bundle,
    should_become_xcode_target = _should_become_xcode_target,
)

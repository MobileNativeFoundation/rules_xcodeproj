"""Functions for handling Xcode build settings."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo", "swift_common")

# Maps the strings passed in to the `families` attribute to the numerical
# representation in the "TARGETED_DEVICE_FAMILY" build setting.
# @unsorted-dict-items
_DEVICE_FAMILY_VALUES = {
    "iphone": "1",
    "ipad": "2",
    "tv": "3",
    "watch": "4",
    # We want `get_targeted_device_family` to find `None` for the valid "mac"
    # family since macOS doesn't use "TARGETED_DEVICE_FAMILY", but we still want
    # to catch invalid families with a `KeyError`.
    "mac": None,
}

def get_product_module_name(*, ctx, target):
    """Generates a module name for the given target.

    Args:
        ctx: The aspect context.
        target: The `Target` to generate a module name for.

    Returns:
        The `module_name` attribute of `target` if set, otherwise it transforms
        the target's `Label` into a valid module name (e.g. "//some/pkg:target"
        becomes "some_pkg_target").
    """
    module_name = getattr(ctx.rule.attr, "module_name", None)
    if module_name:
        return module_name

    if SwiftInfo in target:
        return swift_common.derive_module_name(target.label)

    return None

def get_targeted_device_family(families):
    """Generates a TARGETED_DEVICE_FAMILY based string.

    Args:
        families: A `list` of strings representing the device families. This
            value should come from the `families` attribute on the `Target`. See
            https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_application-families.

    Returns:
        An optional string that is can be used for the TARGETED_DEVICE_FAMILY
        Xcode build setting.
    """
    family_ids = []
    for family in families:
        number = _DEVICE_FAMILY_VALUES[family]
        if number:
            family_ids.append(number)
    if family_ids:
        return ",".join(family_ids)
    return None

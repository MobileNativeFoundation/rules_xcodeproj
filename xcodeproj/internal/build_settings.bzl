"""Functions for handling Xcode build settings."""

load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "SwiftInfo",
    "SwiftProtoInfo",
    "swift_common",
)

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

def get_product_module_name(*, rule_attr, target):
    """Generates a module name for the given target.

    Args:
        rule_attr: `ctx.rule.attr`.
        target: The `Target` to generate a module name for.

    Returns:
        A `tuple` containing two elements:
            * The `module_name` attribute of `target`
            * The `module_name` attribute of `target` if set, otherwise it transforms
            the target's `Label` into a valid module name (e.g. "//some/pkg:target"
            becomes "some_pkg_target").
    """
    module_name = getattr(rule_attr, "module_name", None)
    if module_name:
        return (module_name, module_name)

    if SwiftProtoInfo in target:
        # The new swift_proto_library implementation exposes
        # the derived module name via the provider.
        swift_proto_info = target[SwiftProtoInfo]
        if hasattr(swift_proto_info, "module_name"):
            return (None, module_name)

        # A `swift_proto_library` target must only have exactly one target in
        # the deps attribute. This is already validated in
        # `swift_proto_library`'s implementation.
        target_to_derive_module_name = rule_attr.deps[0]

        # The module name of the Swift library produced by a
        # `swift_proto_library` is based on the name of the `proto_library`
        # target, *not* the name of the `swift_proto_library` target.
        return (None, swift_common.derive_module_name(
            target_to_derive_module_name.label,
        ))

    if SwiftInfo in target:
        return (None, swift_common.derive_module_name(target.label))

    return (None, None)

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
    return ",".join(family_ids)

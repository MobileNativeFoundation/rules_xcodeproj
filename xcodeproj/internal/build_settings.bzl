"""Functions for handling Xcode build settings."""

def _calculate_module_name(*, label, module_name):
    """Calculates a module name.

    Args:
        label: The `Label` of the `Target`.
        module_name: The value of the `module_name` attribute of the target.
            Can be `None`.

    Returns:
        `module_name` if not `None`, otherwise it transforms `label` into a
        valid module name (e.g. "//some/pkg:target" becomes "some_pkg_target").
    """
    if module_name:
        return module_name

    label_string = str(label)

    if label_string.startswith("//"):
        label_string = label_string[2:]

    return (label_string
        .replace("@", "")
        .replace("//", "_")
        .replace("-", "_")
        .replace("/", "_")
        .replace(":", "_")
        .replace(".", "_"))

# API

def set_if_true(build_settings, key, value):
    """Sets `build_settings[key]` to `value` if it doesn't evaluate to `False`.

    This is useful for setting build settings that are lists, but only when we
    have a value to set.
    """
    if value:
        build_settings[key] = value

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
    return _calculate_module_name(
        label = target.label,
        module_name = getattr(ctx.rule.attr, "module_name", None),
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    calculate_module_name = _calculate_module_name,
)

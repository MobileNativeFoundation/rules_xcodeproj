"""Functions dealing with Target IDs."""

def get_id(*, label, configuration):
    """Generates a unique identifier for a target.

    Args:
        label: The `Label` of the `Target`.
        configuration: The value returned from `get_configuration`.

    Returns:
        An opaque string that uniquely identifies the target.
    """
    return "{} {}".format(label, configuration)

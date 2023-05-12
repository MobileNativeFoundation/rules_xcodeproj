"""Functions dealing with Target IDs."""

def get_id(*, label, configuration):
    """Generates a unique identifier for a target.

    Args:
        label: The `Label` of the `Target`.
        configuration: The value returned from `calculate_configuration`.

    Returns:
        An opaque string that uniquely identifies the target.
    """
    return "{} {}".format(label, configuration)

def write_target_ids_list(*, actions, name, target_ids):
    """Writes the list of target IDs for a set of `xcode_target`s to a file.

    Args:
        actions: `ctx.actions`.
        name: `ctx.attr.name`.
        target_ids: A sequence of target IDs.

    Returns:
        The `File` that was written.
    """
    output = actions.declare_file(
        "{}_target_ids".format(name),
    )

    args = actions.args()
    args.set_param_file_format("multiline")
    args.add_all(sorted(target_ids))

    actions.write(
        output,
        args,
    )

    return output

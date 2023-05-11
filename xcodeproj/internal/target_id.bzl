"""Functions dealing with Target IDs."""

load(":bazel_labels.bzl", "bazel_labels")

def get_id(*, label, configuration):
    """Generates a unique identifier for a target.

    Args:
        label: The `Label` of the `Target`.
        configuration: The value returned from `calculate_configuration`.

    Returns:
        An opaque string that uniquely identifies the target.
    """
    return "{} {}".format(label, configuration)

def _longest_common_prefix(labels):
    if not labels:
        return None

    # Assume the shortest string is the answer
    res = labels[0]
    for s in labels:
        if len(s) < len(res):
            res = s

    # Compare one character at a time with the rest,
    # as soon as any difference is found the result holds the longest common prefix
    index = 0
    for c in res.elems():
        for label in labels:
            if label[index] != c:
                return res[:index]
        index += 1

    # If the above never returns the shortest string is the result
    return res

def calculate_replacement_label(*, id, replacement_labels):
    """Calculates a single replacement label for a given id and list of \
    replacement labels.

    It considers the list of labels received plus the label contained in the id
    itself, then it finds the longest common prefix between those.

    Args:
        id: An id that uniquely represents a target (see `get_id`)
        replacement_labels: A list of replacement labels

    Returns:
        The longest common prefix between the list of labels and the label contained in the id,
        if a longest common prefix is not found the label contained in the id is returned
    """
    id_label = id.split(" ")[0]  # This assumes the id follows the creation pattern in `get_id`

    res = _longest_common_prefix(
        [id_label] + ["%s" % label for label in replacement_labels],
    )
    if not res:
        return None

    res = bazel_labels.normalize_label(res)
    return Label(res)

def write_target_ids_list(*, actions, name, target_dtos):
    """Writes the list of target IDs for a set of `xcode_target`s to a file.

    Args:
        actions: `ctx.actions`.
        name: `ctx.attr.name`.
        target_dtos: A `dict` with target IDs as keys.

    Returns:
        The `File` that was written.
    """
    output = actions.declare_file(
        "{}_target_ids".format(name),
    )

    args = actions.args()
    args.set_param_file_format("multiline")
    args.add_all(sorted(target_dtos.keys()))

    actions.write(
        output,
        args,
    )

    return output

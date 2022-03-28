"""Functions for manipulating collections."""

def flatten(seq):
    """Flatten a sequence of sequences."""
    return [
        item
        for sub_seq in seq
        for item in sub_seq
    ]

def set_if_true(dictionary, key, value):
    """Sets `dictionary[key]` to `value` if it doesn't evaluate to `False`.

    This is useful for setting build settings that are lists, but only when we
    have a value to set.
    """
    if value:
        dictionary[key] = value

def uniq(seq):
    """Returns a list of unique elements in `seq`.

    Requires all the elements to be hashable.

    Args:
        seq: A sequence to filter.

    Returns:
        A new `list` with all unique elements from `seq`.
    """
    return {x: None for x in seq}.keys()

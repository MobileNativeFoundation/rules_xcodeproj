"""Functions for manipulating collections."""

def flatten(seq):
    """Flatten a sequence of sequences."""
    return [
        item
        for sub_seq in seq
        for item in sub_seq
    ]

def uniq(seq):
    """Returns a list of unique elements in `seq`.

    Requires all the elements to be hashable.

    Args:
        seq: A sequence to filter.

    Returns:
        A new `list` with all unique elements from `seq`.
    """
    return {x: None for x in seq}.keys()

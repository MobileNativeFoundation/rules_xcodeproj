"""Functions for manipulating collections."""

def flatten(seq):
    """Flatten a sequence of sequences."""
    return [
        item
        for sub_seq in seq
        for item in sub_seq
    ]

"""Testing utility functions."""

def stringify_dict(dict):
    """Converts the values of a dictionary to strings."""
    return {k: str(v) for k, v in dict.items()}

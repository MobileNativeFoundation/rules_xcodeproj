"""Testing utility functions."""

def _stringify_dict_value(value):
    if type(value) == "tuple":
        value = list(value)
    return str(value)

def stringify_dict(dict):
    """Converts the values of a dictionary to strings."""
    return {k: _stringify_dict_value(v) for k, v in dict.items()}

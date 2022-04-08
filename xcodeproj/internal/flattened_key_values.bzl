"""Utility functions to manage flattend key-value lists."""

def _to_dict(iterable):
    """Converts an iterable of flattened key-value pairs to a dictionary.

    Args:
        iterable: A `list` where the even index is the key and the next item is
                  the value.

    Returns:
        A `dict` representing each key-value pair.
    """
    iterable_len = len(iterable)
    if iterable_len % 2 != 0:
        fail(
            """\
Expected the iterable to have an even number of items. length: {len}\
""".format(len = iterable_len),
        )

    key_values = {}
    key_value_count = iterable_len // 2
    for kv_idx in range(key_value_count):
        idx = kv_idx * 2
        key = iterable[idx]
        value = iterable[idx + 1]
        key_values[key] = value

    return key_values

def _to_list(key_values_dict, *, sort = True):
    """Converts a `dict` to a flattened key-value `list`.

    Args:
        key_values_dict: A `dict` whose key-values will be written to the
                         `list`.
        sort: Optional. Specifies whether the keys should be sorted before
                        serializing the key-value pairs to the `list`.

    Returns:
        A `list` consisiting of the keys at even index numbers and the
        corresponding value is the next item.
    """
    keys = key_values_dict.keys()
    if sort:
        keys = sorted(keys)

    iterable = []
    for key in keys:
        iterable.append(key)
        iterable.append(key_values_dict[key])
    return iterable

def _sort(iterable):
    return _to_list(
        _to_dict(iterable),
    )

flattened_key_values = struct(
    to_dict = _to_dict,
    to_list = _to_list,
    sort = _sort,
)

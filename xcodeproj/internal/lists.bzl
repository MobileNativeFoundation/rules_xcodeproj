def _flattened_key_values_to_dict(iterable):
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

def _dict_to_flattened_key_values(key_values_dict, sort = True):
    keys = key_values_dict.keys()
    if sort:
        keys = sorted(keys)

    iterable = []
    for key in keys:
        iterable.extend([key, key_values_dict[key]])
    return iterable

def _sort_flattened_key_values(iterable):
    return _dict_to_flattened_key_values(
        _flattened_key_values_to_dict(iterable),
    )

lists = struct(
    flattened_key_values_to_dict = _flattened_key_values_to_dict,
    dict_to_flattened_key_values = _dict_to_flattened_key_values,
    sort_flattened_key_values = _sort_flattened_key_values,
)

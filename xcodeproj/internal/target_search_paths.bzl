"""Module containing functions for collecting target search paths."""

def _make_search_paths(*, opts_search_paths = None):
    """Creates the internal data structure of the `target_search_paths` module.

    Args:
        opts_search_paths: A value returned from `create_opts_search_paths`, or
            `None`.

    Returns:
        An opaque `struct` representing the internal data structure of the
        `target_search_paths` module.
    """
    return struct(
        _opts_search_paths = opts_search_paths,
    )

target_search_paths = struct(
    make = _make_search_paths,
)

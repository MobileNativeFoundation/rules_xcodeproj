"Commonly used constant expressions. Used to avoid creating new objects in memory."

EMPTY_DICT = {}
EMPTY_DEPSET = depset()
EMPTY_LIST = []
EMPTY_STRING = ""
EMPTY_TUPLE = tuple()
NONE_LIST = [None]

def memory_efficient_depset(direct = None, *, transitive = None, **kwargs):
    """Creates a memory efficient `depset`.

    Args:
        direct: Maps to `depset.direct`.
        transitive: Maps to `depset.transitive`. Empty depsets are removed.
        **kwargs: Additional keyword arguments to pass to `depset`.

    Returns:
        If both `direct` and `transitive` are empty after filtering empty
        depsets out of `transitive`, then `EMPTY_DEPSET` is returned. Otherwise
        a new `depset` is returned.
    """
    if transitive:
        transitive = [d for d in transitive if d != EMPTY_DEPSET]
    if direct or transitive:
        return depset(direct, transitive = transitive, **kwargs)
    return EMPTY_DEPSET

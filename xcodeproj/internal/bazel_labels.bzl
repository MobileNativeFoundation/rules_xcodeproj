"""API for resolving and managing Bazel labels"""

_ROOT_SEPARATOR = "//"
_ROOT_SEPARATOR_LEN = len(_ROOT_SEPARATOR)
_NAME_SEPARATOR = ":"
_NAME_SEPARATOR_LEN = len(_NAME_SEPARATOR)
_PKG_SEPARATOR = "/"
_PKG_SEPARATOR_LEN = len(_PKG_SEPARATOR)

def _create(repository_name, package, name):
    return struct(
        repository_name = repository_name,
        package = package,
        name = name,
    )

def _parse(value, loading_phase = True):
    """Parse a string as a Bazel label returning its parts.

    Args:
        value: A `string` value to parse.
        load_phase: Optional. A `bool` that indicates whether the function is
            being called from Bazel's loading phase. Some native functionality
            is only available during the loading phase.

    Returns:
        A `struct` as returned from `bazel_labels.create`.
    """
    root_sep_pos = value.find(_ROOT_SEPARATOR)

    # The package starts after the root separator
    if root_sep_pos > -1:
        pkg_start_pos = root_sep_pos + _ROOT_SEPARATOR_LEN
    else:
        pkg_start_pos = -1

    # Extract the repo name
    if root_sep_pos > 0:
        repo_name = value[:root_sep_pos]
    elif loading_phase:
        repo_name = native.repository_name()
    else:
        repo_name = "@"

    colon_pos = value.find(_NAME_SEPARATOR)

    # Extract the name
    if colon_pos > -1:
        # Found a colon, the name follows it
        name_start_pos = colon_pos + _NAME_SEPARATOR_LEN
        pkg_end_pos = colon_pos
    elif pkg_start_pos > -1:
        # No colon and have a package, so the name is the last part of the
        # package
        pkg_end_pos = len(value)
        last_sep_pos = value.rfind(_PKG_SEPARATOR, pkg_start_pos)
        if last_sep_pos > -1:
            name_start_pos = last_sep_pos + _PKG_SEPARATOR_LEN
        else:
            name_start_pos = pkg_start_pos
    else:
        # No colon and no package, the value is the name
        name = value
        pkg_end_pos = -1
    name = value[name_start_pos:]

    if pkg_start_pos > -1:
        package = value[pkg_start_pos:pkg_end_pos]
    elif loading_phase:
        package = native.package_name()
    else:
        package = ""

    return _create(
        repository_name = repo_name,
        package = package,
        name = name,
    )

    # if value.startswith("@") or value.startswith("//"):
    #     return value
    # repo_name = native.repository_name()
    # if repo_name == "@":
    #     repo_name = ""
    # pkg_name = native.package_name()
    # name = value[1:] if value.startswith(":") else value

def _normalize(value, loading_phase = True):
    parts = _parse(value, loading_phase = loading_phase)
    return "{repo_name}//{package}:{name}".format(
        repo_name = parts.repository_name,
        package = parts.package,
        name = parts.name,
    )

# TODO: Handle value without explicit name (//Sources/Foo)
# TODO: Perhaps do normalze (convert string to a format that is
# explicit label with all parts), and validate (

bazel_labels = struct(
    create = _create,
    parse = _parse,
    normalize = _normalize,
)

"""API for resolving and managing Bazel labels"""

# MARK: - name_resolver Module Factory

def _create_name_resolver(repository_name, package_name):
    """Create a name resolver module.

    Args:
        repository_name: A `function` that returns the current repository name.
        package_name: A `function` that returns the current package name.

    Returns:
        A `struct` that can be used as a name resolver module.
    """
    return struct(
        repository_name = repository_name,
        package_name = package_name,
    )

native_name_resolver = _create_name_resolver(
    repository_name = native.repository_name,
    package_name = native.package_name,
)

def make_stub_name_resolver(repo_name = "@", pkg_name = ""):
    """Create a name resolver module that returns the provided values.

    Args:
        repo_name: A `string` value returned as the repository name.
        pkg_name: A `string` value returned as the package name.

    Returns:
        A `struct` that can nbe used as a name resolver module.
    """

    def _stub_repository_name():
        return repo_name

    def _stub_package_name():
        return pkg_name

    return _create_name_resolver(
        repository_name = _stub_repository_name,
        package_name = _stub_package_name,
    )

# MARK: - bazel_labels Module Factory

_ROOT_SEPARATOR = "//"
_ROOT_SEPARATOR_LEN = len(_ROOT_SEPARATOR)
_NAME_SEPARATOR = ":"
_NAME_SEPARATOR_LEN = len(_NAME_SEPARATOR)
_PKG_SEPARATOR = "/"
_PKG_SEPARATOR_LEN = len(_PKG_SEPARATOR)

def _create_label_parts(repository_name, package, name):
    if not repository_name.startswith("@"):
        fail("Repository names must start with an '@'. {repo_name}".format(
            repo_name = repository_name,
        ))
    return struct(
        repository_name = repository_name,
        package = package,
        name = name,
    )

def make_bazel_labels(name_resolver = native_name_resolver):
    """Creates a `bazel_labels` module using the specified name resolver.

    Args:
        name_resolver: Optional. A `name_resolver` module.

    Returns:
        A `struct` that can be used as a Bazel labels module.
    """

    def _parse(value):
        """Parse a string as a Bazel label returning its parts.

        Args:
            value: A `string` value to parse.

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
        else:
            repo_name = name_resolver.repository_name()

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
            name_start_pos = 0
            pkg_end_pos = -1
        name = value[name_start_pos:]

        if pkg_start_pos > -1:
            package = value[pkg_start_pos:pkg_end_pos]
        else:
            package = name_resolver.package_name()

        return _create_label_parts(
            repository_name = repo_name,
            package = package,
            name = name,
        )

    def _normalize(value):
        parts = _parse(value)
        return "{repo_name}//{package}:{name}".format(
            repo_name = parts.repository_name,
            package = parts.package,
            name = parts.name,
        )

    # TODO: Handle value without explicit name (//Sources/Foo)
    # TODO: Perhaps do normalze (convert string to a format that is
    # explicit label with all parts), and validate (

    return struct(
        create = _create_label_parts,
        parse = _parse,
        normalize = _normalize,
    )

bazel_labels = make_bazel_labels()

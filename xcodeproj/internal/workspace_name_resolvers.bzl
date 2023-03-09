"""API for resolving workspace names"""

def _make_workspace_name_resolvers(
        repository_name,
        package_name,
        package_relative_label):
    """Create a name resolver module.

    Args:
        repository_name: A `function` that returns the current repository name.
        package_name: A `function` that returns the current package name.
        package_relative_label: A `function` that returns the current package
            relative label.

    Returns:
        A `struct` that can be used as a name resolver module.
    """
    return struct(
        repository_name = repository_name,
        package_name = package_name,
        package_relative_label = package_relative_label,
    )

def _package_relative_label_shim(value):
    if hasattr(native, "package_relative_label"):
        return native.package_relative_label(value)
    return None

workspace_name_resolvers = _make_workspace_name_resolvers(
    repository_name = native.repository_name,
    package_name = native.package_name,
    package_relative_label = _package_relative_label_shim,
)

def make_stub_workspace_name_resolvers(repo_name = "@", pkg_name = ""):
    """Create a `workspace_name_resolvers` module that returns the provided values.

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

    def _stub_package_relative_label(value):
        if not hasattr(native, "package_relative_label"):
            return None
        if value.startswith(":"):
            return "{}//{}{}".format(repo_name, pkg_name, value)
        if value.startswith("//"):
            return "{}{}".format(repo_name, value)
        if not value.startswith("@@"):
            return repo_name + value[1:]
        return value

    return _make_workspace_name_resolvers(
        repository_name = _stub_repository_name,
        package_name = _stub_package_name,
        package_relative_label = _stub_package_relative_label,
    )

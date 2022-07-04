"""API for resolving workspace names"""

def _make_workspace_name_resolvers(repository_name, package_name):
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

workspace_name_resolvers = _make_workspace_name_resolvers(
    repository_name = native.repository_name,
    package_name = native.package_name,
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

    return _make_workspace_name_resolvers(
        repository_name = _stub_repository_name,
        package_name = _stub_package_name,
    )

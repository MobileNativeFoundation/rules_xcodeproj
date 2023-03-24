"""API for resolving and managing Bazel labels"""

load(":workspace_name_resolvers.bzl", "workspace_name_resolvers")

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

# buildifier: disable=unnamed-macro
def make_bazel_labels(workspace_name_resolvers = workspace_name_resolvers):
    """Creates a `bazel_labels` module using the specified name resolver.

    Args:
        workspace_name_resolvers: A `workspace_name_resolvers` module.

    Returns:
        A `struct` that can be used as a `bazel_labels` module.
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
            repo_name = workspace_name_resolvers.repository_name()

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
            package = workspace_name_resolvers.package_name()

        return _create_label_parts(
            repository_name = repo_name,
            package = package,
            name = name,
        )

    def _normalize_label(value):
        label_str = str(value)
        if label_str[0] == "@":
            return label_str
        return "@" + label_str

    def _normalize_string(value):
        package_relative_label = (
            workspace_name_resolvers.package_relative_label(value)
        )
        if package_relative_label:
            label_str = str(package_relative_label)
            if label_str[0] == "@":
                return label_str
            return "@" + label_str

        parts = _parse(value)

        label_str = str(Label("{repo_name}//{package}:{name}".format(
            repo_name = parts.repository_name,
            package = parts.package,
            name = parts.name,
        )))
        if label_str[0] == "@":
            return label_str
        return "@" + label_str

    return struct(
        create = _create_label_parts,
        parse = _parse,
        normalize_label = _normalize_label,
        normalize_string = _normalize_string,
    )

bazel_labels = make_bazel_labels(
    workspace_name_resolvers = workspace_name_resolvers,
)

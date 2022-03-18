"""Function for creating local include copts."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def local_includes(path):
    """Returns a list of copts that act like a `local_includes` attribute.

    Args:
        path: A `string` of the directory to add to local `includes`.

    Returns:
        A `list` of copts.
    """
    repo_name = native.repository_name()[1:]
    package_name = native.package_name()
    if repo_name:
        source_dir = paths.join("external", repo_name, package_name, path)
    else:
        source_dir = paths.join(package_name, path)
    return [
        "-I{}".format(source_dir),
        "-I{}".format(paths.join("$(GENDIR)", source_dir)),
    ]

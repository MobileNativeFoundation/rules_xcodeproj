"""API for resolving and managing Bazel labels"""

def _absolute(label):
    if label.startswith("@") or label.startswith("//"):
        return label
    repo_name = native.repository_name()
    if repo_name == "@":
        repo_name = ""
    pkg_name = native.package_name()
    name = label[1:] if label.startswith(":") else label
    return "{repo_name}//{pkg_name}:{name}".format(
        repo_name = repo_name,
        pkg_name = pkg_name,
        name = name,
    )

# TODO: Handle label without explicit name (//Sources/Foo)
# TODO: Should I normalize in absolute or create a separate function?

bazel_labels = struct(
    absolute = _absolute,
)

"""Functions for processing `File`s."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def file_path(file, path = None, is_folder = False, include_in_navigator = True):
    """Converts a `File` into a `FilePath` Swift DTO value.

    Args:
        file: A `File`.
        path: A path string to use instead of `file.path`.
        is_folder: Whether the path is to a folder.
        include_in_navigator: Whether to include the file in the Project
            navigator.

    Returns:
        A `struct` containing the following fields:

        *   `path`: The file path.
        *   `is_folder`: `True` if the path is a folder.
        *   `type`: Maps to `FilePath.FileType`:
            *   "p" for `.project`
            *   "e" for `.external`
            *   "g" for `.generated`
            *   "i" for `.internal`
    """
    if not path:
        path = file.path
    if not file.is_source:
        return generated_file_path(
            path = path,
            is_folder = is_folder,
            include_in_navigator = include_in_navigator,
        )
    if file.owner.workspace_name:
        return external_file_path(
            path = path,
            is_folder = is_folder,
            include_in_navigator = include_in_navigator,
        )
    return project_file_path(
        path = path,
        is_folder = is_folder,
        include_in_navigator = include_in_navigator,
    )

def parsed_file_path(path):
    """Coverts a file path string into a `FilePath` Swift DTO value.

    Args:
        path: A file path string.

    Returns:
        A value as returned from `file_path`.
    """

    # These checks are less than ideal, but since it's a string we can't tell if
    # they meant something else
    if path.startswith("bazel-out/"):
        return generated_file_path(path)
    elif path.startswith("external/"):
        return external_file_path(path)
    else:
        return project_file_path(path)

def _file_path(type, *, path, is_folder, include_in_navigator):
    return struct(
        path = path,
        type = type,
        is_folder = is_folder,
        include_in_navigator = include_in_navigator,
    )

def external_file_path(path, is_folder = False, include_in_navigator = True):
    return _file_path(
        # Type: "e" == `.external`
        type = "e",
        # Path, removing `external/` prefix
        path = path[9:],
        is_folder = is_folder,
        include_in_navigator = include_in_navigator,
    )

def generated_file_path(path, is_folder = False, include_in_navigator = True):
    return _file_path(
        # Type: "g" == `.generated`
        type = "g",
        # Path, removing `bazel-out/` prefix
        path = path[10:],
        is_folder = is_folder,
        include_in_navigator = include_in_navigator,
    )

def project_file_path(path, is_folder = False, include_in_navigator = True):
    return _file_path(
        # Type: "p" == `.project`
        type = "p",
        path = path,
        is_folder = is_folder,
        include_in_navigator = include_in_navigator,
    )

# TODO: Refactor all of file_path stuff to a module
def file_path_to_dto(file_path):
    """Converts a `file_path` return value to a `FilePath` Swift DTO value.

    Args:
        file_path: A value returned from `file_path`.

    Returns:
        A `FilePath` Swift DTO value, which is either a string or a `struct`
        containing the following fields:

        *   `_`: The file path.
        *   `f`: `True` if the path is a folder.
        *   `t`: Maps to `FilePath.FileType`:
            *   "p" for `.project`
            *   "e" for `.external`
            *   "g" for `.generated`
            *   "i" for `.internal`
    """
    if not file_path:
        return None

    ret = {}

    if file_path.is_folder:
        ret["f"] = True

    if file_path.type != "p":
        ret["t"] = file_path.type

    if not file_path.include_in_navigator:
        ret["i"] = False

    if ret:
        ret["_"] = file_path.path

    # `FilePath` allows a `string` to imply a `.project` file
    return ret if ret else file_path.path

def join_paths_ignoring_empty(*components):
    non_empty_components = [
        component
        for component in components
        if component
    ]
    if not non_empty_components:
        return ""
    return paths.join(*non_empty_components)

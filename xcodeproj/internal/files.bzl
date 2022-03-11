"""Functions for processing `File`s."""

def file_path(file):
    """Converts a `File` into a `FilePath` Swift DTO value.

    Args:
        file: A `File`.

    Returns:
        A `FilePath` Swift DTO value, which is either a string or a `struct`
        containing the following fields:

        *   `_`: The file path.
        *   `t`: Maps to `FilePath.FileType`:
            *   "p" for `.project`
            *   "e" for `.external`
            *   "i" for `.internal`
    """
    path = file.path
    if file.owner.workspace_name:
        return struct(
            # Type: "e" == `.external`
            t = "e",
            # Path, removing `external/` prefix
            _ = path[9:],
        )
    return path

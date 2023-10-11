"""Functions for processing `File`s."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def build_setting_path(
        *,
        file = None,
        path = None,
        use_build_dir = False):
    """Converts a `File` into a `string` to be used in an Xcode build setting.

    Args:
        file: A `File`. One of `file` or `path` must be specified.
        path: A path `string. One of `file` or `path` must be specified.
        use_build_dir: Whether to use `$(BUILD_DIR)` instead of `$(BAZEL_OUT)`
            for generated files.

    Returns:
        A `string`.
    """
    if not file and not path:
        fail("One of `file` or `path` must be specified.")

    if file:
        type = _file_type(file)
        if not path:
            path = file.path
    else:
        type = _parsed_path_type(path)

    if path == ".":
        # We need to use Bazel's execution root for ".", since includes can
        # reference things like "external/" and "bazel-out"
        return "$(PROJECT_DIR)"

    if type == "g":
        # Generated
        if use_build_dir:
            if path:
                build_setting = "$(BUILD_DIR)/{}".format(path)
            else:
                # Support directory reference
                build_setting = "$(BUILD_DIR)"
        else:
            # Removing "bazel-out" prefix
            build_setting = "$(BAZEL_OUT){}".format(path[9:])
    elif type == "e":
        # External
        if path:
            # Removing "external" prefix
            build_setting = "$(BAZEL_EXTERNAL){}".format(path[8:])
        else:
            # Support directory reference
            build_setting = "$(BAZEL_EXTERNAL)"
    else:
        # Project or absolute
        if is_relative_path(path):
            build_setting = "$(SRCROOT)/{}".format(path)
        else:
            build_setting = path

    return build_setting

def quote_if_needed(path):
    """Quotes a path if it contains spaces.

    Args:
        path: A path `string`.

    Returns:
        A `string`.
    """
    if path.find(" ") != -1:
        return '"{}"'.format(path)
    return path

def _file_type(file):
    if not file.is_source:
        return "g"
    if file.owner.workspace_name:
        return "e"
    return None

def _parsed_path_type(path):
    if is_generated_path(path):
        return "g"
    if is_external_path(path):
        return "e"
    return None

RESOURCES_FOLDER_TYPE_EXTENSIONS = [
    ".bundle",
    ".docc",
    ".framework",
    ".scnassets",
    ".xcassets",
]

FRAMEWORK_EXTENSIONS = [
    ".framework",
]

# TODO: See if we can move this into `args.add_all.map_each`, normalizing every file?
def normalized_file_path(file, *, folder_type_extensions):
    """Converts a `File` into a `FilePath` Swift DTO value, leaving off \
    unnecessary components under folder types.

    Args:
        file: A `File`.
        folder_type_extensions: The extensions to check for folder types.

    Returns:
        A tuple with two elements:

        *   A `File` if no normalization happened, otherwise `None`
        *   A file path `str` if normalization happened, otherwise `None
    """
    path = file.path

    for extension in folder_type_extensions:
        if extension not in path:
            continue
        prefix, ext, _ = path.partition(extension)
        return (None, prefix + ext)

    return (file, None)

def is_external_path(path):
    return path == "external" or path.startswith("external/")

def is_generated_path(path):
    return path == "bazel-out" or path.startswith("bazel-out/")

def is_relative_path(path):
    return not path.startswith("/") and not path.startswith("__BAZEL_")

def join_paths_ignoring_empty(*components):
    non_empty_components = [
        component
        for component in components
        if component
    ]
    if not non_empty_components:
        return ""
    return paths.join(*non_empty_components)

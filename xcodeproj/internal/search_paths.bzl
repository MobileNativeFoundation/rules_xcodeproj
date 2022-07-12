"""Functions for processing search paths."""

load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path_to_dto",
    "parsed_file_path",
)

def process_search_paths(
        *,
        compilation_providers,
        bin_dir_path,
        opts_search_paths):
    """Processes search paths.

    Args:
        compilation_providers: A value returned from
            `compilation_providers.collect`.
        bin_dir_path: `ctx.bin_dir.path`.
        opts_search_paths: A value returned from `create_opts_search_paths`.

    Returns:
        A DTO `dict`.
    """
    if not compilation_providers:
        return {}

    cc_info = compilation_providers._cc_info
    objc = compilation_providers._objc

    search_paths = {}
    if cc_info:
        compilation_context = cc_info.compilation_context

        quote_includes = depset(
            [".", bin_dir_path] + opts_search_paths.quote_includes,
            transitive = [compilation_context.quote_includes],
        )

        set_if_true(
            search_paths,
            "quote_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in quote_includes.to_list()
            ],
        )
        set_if_true(
            search_paths,
            "includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.includes.to_list() +
                             opts_search_paths.includes)
            ],
        )
        set_if_true(
            search_paths,
            "system_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.system_includes.to_list() +
                             opts_search_paths.system_includes)
            ],
        )

    if objc:
        framework_paths = depset(
            transitive = [
                objc.static_framework_paths,
                objc.dynamic_framework_paths,
            ],
        )

        set_if_true(
            search_paths,
            "framework_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in framework_paths.to_list()
            ],
        )

    return search_paths

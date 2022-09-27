"""Module containing functions for collecting target search paths."""

load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path_to_dto",
    "parsed_file_path",
)

def _make(*, compilation_providers, bin_dir_path, opts_search_paths = None):
    """Creates the internal data structure of the `target_search_paths` module.

    Args:
        compilation_providers: A value returned from
            `compilation_providers.collect`, or `None`.
        bin_dir_path: `ctx.bin_dir.path`.
        opts_search_paths: A value returned from `create_opts_search_paths`, or
            `None`.

    Returns:
        An opaque `struct` representing the internal data structure of the
        `target_search_paths` module.
    """
    return struct(
        _bin_dir_path = bin_dir_path,
        _compilation_providers = compilation_providers,
        _opts_search_paths = opts_search_paths,
    )

def _to_dto(search_paths):
    if not search_paths:
        return {}

    compilation_providers = search_paths._compilation_providers
    if not compilation_providers:
        return {}

    cc_info = compilation_providers._cc_info
    objc = compilation_providers._objc

    dto = {}
    if cc_info:
        compilation_context = cc_info.compilation_context
        opts_search_paths = search_paths._opts_search_paths

        if opts_search_paths:
            opts_includes = list(opts_search_paths.includes)
            opts_quote_includes = list(opts_search_paths.quote_includes)
            opts_system_includes = list(opts_search_paths.system_includes)
        else:
            opts_includes = []
            opts_quote_includes = []
            opts_system_includes = []

        quote_includes = depset(
            [".", search_paths._bin_dir_path] + opts_quote_includes,
            transitive = [compilation_context.quote_includes],
        )

        set_if_true(
            dto,
            "quote_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in quote_includes.to_list()
            ],
        )
        set_if_true(
            dto,
            "includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.includes.to_list() +
                             opts_includes)
            ],
        )
        set_if_true(
            dto,
            "system_includes",
            [
                file_path_to_dto(parsed_file_path(path))
                for path in (compilation_context.system_includes.to_list() +
                             opts_system_includes)
            ],
        )

    if objc:
        framework_paths = depset(
            transitive = [
                objc.static_framework_paths,
                objc.dynamic_framework_paths,
            ],
        )

        framework_file_paths = [
            parsed_file_path(path)
            for path in framework_paths.to_list()
        ]

        set_if_true(
            dto,
            "framework_includes",
            [
                file_path_to_dto(fp)
                for fp in framework_file_paths
            ],
        )

    return dto

target_search_paths = struct(
    make = _make,
    to_dto = _to_dto,
)

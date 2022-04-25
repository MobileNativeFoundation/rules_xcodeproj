"""API for parsing and retrieving linker options data."""

# Documentation on linker flags:
#   https://www.objc.io/issues/6-build-tools/mach-o-executables/
#   https://www.manpagez.com/man/1/ld/

def _create_section(*, name, file):
    """Creates a section `struct`.

    Args:
        name: The name of the section as a `string`.
        file: The path of the file that contains a section's contents as a
            `string`.

    Returns:
        A `struct` representing a section as defined by linker options.
    """
    return struct(
        name = name,
        file = file,
    )

def _get_segments(linker_opts_or_segments):
    """Gathers all of the segments defined by the specified linker options.

    If `linker_opts_or_segments` is a `dict`, it is assumed to be a segments
    `dict` and is returned. Otherwise, the options are processed and a segments
    `dict` is created.

    Args:
        linker_opts_or_segments: A `list` of flags passed to the linker or a
            segments `dict`.

    Returns:
        A `dict` that contains all of the segments defined by the specified
        linker options.
    """
    if type(linker_opts_or_segments) == "dict":
        return linker_opts_or_segments

    # Example of a linker option that creates a section named __info_plist in
    # the __TEXT segment:
    # -Wl,-sectcreate,__TEXT,__info_plist,bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-fastbuild-ST-72fe7e1ef217/bin/examples/command_line/tool/tool.merged_infoplist-intermediates/Info.plist

    segments = {}
    for opt in linker_opts_or_segments:
        if not opt.startswith("-Wl,-sectcreate,"):
            continue
        parts = opt.split(",")
        segment_name = parts[2]
        section_name = parts[3]
        file = parts[4]
        segment = segments.setdefault(segment_name, default = {})
        segment[section_name] = _create_section(
            name = section_name,
            file = file,
        )
    return segments

def _get_section(linker_opts_or_segments, segment_name, section_name):
    """Retrieves the section from the specified segment.

    Args:
        linker_opts_or_segments: A `list` of flags passed to the linker or a
            segments `dict`.
        segment_name: The name of the segment as a `string`.
        section_name: The name of the section as a `string`.

    Returns:
        A value as returned from `link_opts.create_section` if the section
        exists exists, otherwise `None`.
    """
    segments = _get_segments(linker_opts_or_segments)
    segment = segments.get(segment_name)
    if segment == None:
        return None
    return segment.get(section_name)

link_opts = struct(
    get_segments = _get_segments,
    get_section = _get_section,
    create_section = _create_section,
)

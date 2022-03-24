"""# Providers

Defines providers and related types used throughout the rules in this
repository.

Most users will not need to use these providers to simply create Xcode projects,
but if you want to write your own custom rules that interact with these
rules, then you will use these providers to communicate between them.
"""

InputFileAttributesInfo = provider(
    "Specifies how input files of a target are collected.",
    fields = {
        "other_collector": """\
An optional lambda that is passed the target being processed and returns a
`list` of `File`s that will end up in `InputFilesInfo.other`. If any of the
files are generated, they will also end up in `InputFilesInfo.generated`.
""",
        "excluded": """\
A sequence of attribute names to not collect `File`s from.
""",
        "hdrs": """\
A sequence of attribute names to collect `File`s from for the
`InputFilesInfo.hdrs` field.
""",
        "non_arc_srcs": """\
A sequence of attribute names to collect `File`s from for the
`InputFilesInfo.non_arc_srcs` field.
""",
        "srcs": """\
A sequence of attribute names to collect `File`s from for the
`InputFilesInfo.srcs` field.
""",
    },
)

InputFilesInfo = provider(
    "Provides information about input files of a target.",
    fields = {
        "generated": """\
A `list` of generated `File`s that are inputs to this target. These files are
also included in the other catagories (e.g. `srcs` or `other`). They are
included in their own field for ease of access.
""",
        "hdrs": """\
A `list` of `File`s that are inputs to this target's `hdrs`-like attributes.
""",
        "non_arc_srcs": """\
A `list` of `File`s that are inputs to this target's `non_arc_srcs`-like
attributes.
""",
        "non_generated": """\
A list of non-generated `File`s that are inputs to this target.
""",
        "other": """\
A `list` of `File`s that are inputs to this target that didn't fall into one of
the more specific (e.g. `srcs`) catagories.
""",
        "srcs": """\
A `list` of `File`s that are inputs to this target's `srcs`-like attributes.
""",
        "transitive_non_generated": """\
A list of `depset`s of non-generated `File`s that are inputs to this target's
transitive dependencies.
""",
    },
)

XcodeProjInfo = provider(
    "Provides information needed to generate an Xcode project.",
    fields = {
        "defines": """\
A value returned from `_process_defines()` that contains the defines set by
this target that should be propagated to dependent targets.
""",
        "dependencies": """\
A `list` of target ids (see the `target` `struct`) that this target directly
depends on.
""",
        "extra_files": """\
A `depset` of `File`s that should be added to the Xcode project, but not
associated with any targets.
""",
        "generated_inputs": """\
A `depset` of generated `File`s that are used by the Xcode project.
""",
        "linker_inputs": "A `depset` of `LinkerInput`s for this target.",
        "potential_target_merges": """\
A `depset` of structs with 'src' and 'dest' fields. The 'src' field is the id of
the target that can be merged into the target with the id of the 'dest' field.
""",
        "required_links": """\
A `depset` of all static library files that are linked into top-level targets
besides their primary top-level targets.
""",
        "search_paths": """\
A value returned from `_process_search_paths()` that contains the search
paths needed by this target. These search paths should be added to the search
paths of any target that depends on this target.
""",
        "target": """\
A `struct` that contains information about the current target that is
potentially needed by the dependent targets.
""",
        "xcode_targets": """\
A `depset` of partial json `dict` strings (e.g. a single '"Key": "Value"'
without the enclosing braces), which potentially will become targets in the
Xcode project.
""",
    },
)

XcodeProjOutputInfo = provider(
    "Provides information about the outputs of the `xcodeproj` rule.",
    fields = {
        "installer": "The xcodeproj installer",
        "root_dirs": "The root directories file",
        "spec": "The json spec",
        "xcodeproj": "The xcodeproj file",
    },
)

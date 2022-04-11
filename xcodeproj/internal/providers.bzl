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
        "bundle_imports": """\
A sequence of attribute names to collect `File`s from for `bundle_imports`-like
attributes.
""",
        "excluded": """\
A sequence of attribute names to not collect `File`s from. This should generally
be `deps` and `deps`-like attributes. The goal is to exclude attributes that
have generated products (e.g. ".swiftmodule" or ".a" files) as outputs.
""",
        "hdrs": """\
A sequence of attribute names to collect `File`s from for the `hdrs`-like
attributes.
""",
        "non_arc_srcs": """\
A sequence of attribute names to collect `File`s from for `non_arc_srcs`-like
attributes.
""",
        "pch": """\
An attribute name (or `None`) to collect `File`s from for the `pch`-like
attribute.
""",
        "resources": """\
A sequence of attribute names to collect `File`s from for the `resources`-like
attributes.
""",
        "srcs": """\
A sequence of attribute names to collect `File`s from for `srcs`-like
attributes.
""",
        "structured_resources": """\
A sequence of attribute names to collect `File`s from for
`structured_resources`-like attributes.
""",
        "target_type": "See `XcodeProjInfo.target_type`.",
        "xcode_targets": """\
A `dict` mapping attribute names to target type strings (i.e. "resource" or
"compile"). Only Xcode targets from the specified attributes with the specified
target type are allowed to propagate.
""",
    },
)

target_type = struct(
    compile = "compile",
    resources = "resources",
)

XcodeProjInfo = provider(
    "Provides information needed to generate an Xcode project.",
    fields = {
        "dependencies": """\
A `list` of target ids (see the `target` `struct`) that this target directly
depends on.
""",
        "inputs": """\
A value returned from `input_files.collect()`, that contains the input files
for this target. It also includes the two extra fields that collect all of the
generated `Files` and all of the `Files` that should be added to the Xcode
project, but are not associated with any targets.
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
        "resource_bundles": """\
A `depset` of all resource bundle product paths (these are made up, but a key
that the generator uses) that haven't been added to an Xcode target yet.
""",
        "search_paths": """\
A value returned from `_process_search_paths()`, that contains the search
paths needed by this target. These search paths should be added to the search
paths of any target that depends on this target.
""",
        "static_framework_files": """\
A `depset` of all static framework files that are linked into this target.
""",
        "target": """\
A `struct` that contains information about the current target that is
potentially needed by the dependent targets.
""",
        "target_type": """\
A string that categorizes the type of the current target. This will be one of
"compile", "resources", or `None`. Even if this target doesn't produce an Xcode
target, it can still have a non-`None` value for this field.
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

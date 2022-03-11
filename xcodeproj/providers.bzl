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
        "excluded": """\
A sequence of attribute names to not collect `File`s from.
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

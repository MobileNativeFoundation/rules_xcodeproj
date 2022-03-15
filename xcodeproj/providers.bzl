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

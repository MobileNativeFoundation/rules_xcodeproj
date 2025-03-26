"""
swift_library(
    ...
    aspect_hints = [":library_extra_files"],
    ...
)

xcodeproj_extra_files(
    name = "library_extra_files",
    files = [...],
)
"""

XcodeProjExtraFilesHintInfo = provider(
    doc = """
    """,
    fields = {
        "files": "List of files to include in the extra files.",
    },
)

def _xcodeproj_extra_files_impl(ctx):
    return [XcodeProjExtraFilesHintInfo(files = depset(ctx.files.files))]

xcodeproj_extra_files = rule(
    attrs = {
        "files": attr.label_list(allow_files = True),
    },
    implementation = _xcodeproj_extra_files_impl,
)

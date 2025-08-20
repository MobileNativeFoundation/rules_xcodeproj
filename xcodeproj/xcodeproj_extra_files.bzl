"""Rule for providing extra files from targets to the project generator"""

load("//xcodeproj/internal:providers.bzl", "XcodeProjExtraFilesHintInfo")

def _xcodeproj_extra_files_impl(ctx):
    """Create a provider to surface extra files via an aspect hint.

    Args:
        ctx: The rule context.

    Returns:
        A `XcodeProjExtraFilesHintInfo` provider.
    """
    return [XcodeProjExtraFilesHintInfo(files = depset(ctx.files.files))]

xcodeproj_extra_files = rule(
    doc = """\
This rule is used to surface extra files that should be included in the Xcode
project navigator, but otherwise aren't inputs to a target. The provider
created by this rule should be attached to the related target via an aspect
hint.

**EXAMPLE**

```starlark
load("@rules_xcodeproj//xcodeproj:xcodeproj_extra_files.bzl", "xcodeproj_extra_files")

swift_library(
    ...
    aspect_hints = [":library_extra_files"],
    ...
)

# Display the README.md file located alongside the Swift library in Xcode
xcodeproj_extra_files(
    name = "library_extra_files",
    files = ["README.md"],
)
```
""",
    implementation = _xcodeproj_extra_files_impl,
    attrs = {
        "files": attr.label_list(
            doc = "The list of extra files to surface in the Xcode navigator.",
            allow_files = True,
        ),
    },
)

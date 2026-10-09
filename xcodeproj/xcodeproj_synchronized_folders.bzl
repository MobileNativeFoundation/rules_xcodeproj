"""Rule for showing a target's source folders as synchronized folders"""

load("//xcodeproj/internal:providers.bzl", "XcodeProjSynchronizedFoldersHintInfo")

def _xcodeproj_synchronized_folders_impl(ctx):
    """Create a provider to surface synchronized folders via an aspect hint.

    Args:
        ctx: The rule context.

    Returns:
        A `XcodeProjSynchronizedFoldersHintInfo` provider.
    """
    for folder in ctx.attr.folders:
        if not folder or folder.startswith("/") or ".." in folder.split("/"):
            fail("{}: folder '{}' must be a path relative to a package".format(
                ctx.label,
                folder,
            ))
    return [XcodeProjSynchronizedFoldersHintInfo(
        folders = tuple(ctx.attr.folders),
    )]

xcodeproj_synchronized_folders = rule(
    doc = """\
This rule is used to show a target's source folders in Xcode as synchronized
folders (Xcode 16's buildable folders), whose contents Xcode keeps up to date on
its own: files added to such a folder appear in the target without regenerating
the project. The provider created by this rule should be attached to the
related target via an aspect hint.

The folders are relative to the package of the target that the hint is attached
to, so one hint can be shared by targets in different packages that use the
same layout. The target's sources inside the folders are shown by the folders
instead of individually.

Bazel still only compiles the target's `srcs`, so they should be every source
file in the folders, typically with a `glob`; otherwise a file added in Xcode
appears in the target but isn't built.

**EXAMPLE**

```starlark
load(
    "@rules_xcodeproj//xcodeproj:xcodeproj_synchronized_folders.bzl",
    "xcodeproj_synchronized_folders",
)

swift_library(
    ...
    srcs = glob(["Sources/**/*.swift"]),
    aspect_hints = [":sources_folder"],
    ...
)

# Show `Sources` as a synchronized folder of the Swift library in Xcode
xcodeproj_synchronized_folders(
    name = "sources_folder",
    folders = ["Sources"],
)
```
""",
    implementation = _xcodeproj_synchronized_folders_impl,
    attrs = {
        "folders": attr.string_list(
            doc = """\
The folders to show as synchronized folders, relative to the package of the
target that the hint is attached to.
""",
            mandatory = True,
        ),
    },
)

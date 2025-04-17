"""# Aspect Hints

Some comment...

```starlark
load("@rules_xcodeproj//xcodeproj:xcodeproj_extra_files.bzl", "xcodeproj_extra_files")
```
"""

load("//xcodeproj:xcodeproj_extra_files.bzl", _xcodeproj_extra_files = "xcodeproj_extra_files")

xcodeproj_extra_files = _xcodeproj_extra_files

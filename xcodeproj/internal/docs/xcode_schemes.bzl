"""# Custom Xcode schemes

To use these functions, `load` the `xcode_schemes` module from
`xcodeproj/xcodeproj.bzl`:

```starlark
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcode_schemes",
)
```
"""

load("//xcodeproj/internal:xcode_schemes.bzl", _xcode_schemes = "xcode_schemes")

xcode_schemes = _xcode_schemes

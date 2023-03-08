"""# Custom Xcode schemes

To use these functions, `load` the `xcode_schemes` module from
`xcodeproj/defs.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_schemes")
```
"""

load("//xcodeproj/internal:xcode_schemes.bzl", _xcode_schemes = "xcode_schemes")

xcode_schemes = _xcode_schemes

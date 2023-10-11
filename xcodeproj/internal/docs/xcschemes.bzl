"""# Custom Xcode schemes (Incremental generation mode)

To use these functions, `load` the `xcschemes` module from `xcodeproj/defs.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcschemes")
```
"""

load("//xcodeproj/internal/xcschemes:xcschemes.bzl", _xcschemes = "xcschemes")

xcschemes = _xcschemes

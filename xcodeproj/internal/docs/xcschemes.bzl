"""# Custom Xcode schemes

To use these functions, `load` the `xcschemes` module from
`xcodeproj/xcschemes.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:xcschemes.bzl", "xcschemes")
```
"""

load("//xcodeproj:xcschemes.bzl", _xcschemes = "xcschemes")

xcschemes = _xcschemes

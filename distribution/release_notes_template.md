## What’s Changed

### Since %LAST_TAG%

* TBD

**Below are the changes that were in %LAST_TAG%.**

### ⚠️ Breaking changes ⚠️

* TBD

### New

* TBD

### Adjusted

* TBD

### Fixed

* TBD

### Ruleset Development Changes

* TBD

### Full Changelog

https://github.com/buildbuddy-io/rules_xcodeproj/compare/%LAST_MINOR_TAG%...%CURRENT_TAG%

## Contributors

* TBD

## Bzlmod Snippet

```starlark
bazel_dep(name = "rules_xcodeproj", version = "%CURRENT_TAG%")
```

`release.tar.gz`’s `integrity`: `%INTEGRITY%`

## Workspace Snippet

Please use the release asset (`release.tar.gz`) from your Bazel `WORKSPACE` instead of GitHub's source asset to reduce download size and improve reproducibility.

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_xcodeproj",
    integrity = "%INTEGRITY%",
    url = "https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/download/%CURRENT_TAG%/release.tar.gz",
)

load(
    "@rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
```

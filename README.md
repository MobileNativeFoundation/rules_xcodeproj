# rules_xcodeproj

This repository contains rules for [Bazel](https://bazel.build) that can be
used to generate Xcode projects.

If you run into any problems with these rules, please
[file an issue](https://github.com/buildbuddy-io/rules_xcodeproj/issues/new/choose)!

## Compatibility

- Xcode 13.2.1
- Bazel 5.0.0 and above
- rules_swift 0.26.0 and above
- rules_apple 0.33.0 and above

Please refer to the
[release notes](https://github.com/buildbuddy-io/rules_xcodeproj/releases) for a
given release to see which versions it is compatible with.

## Quick setup

Add the following to your `WORKSPACE` file to add the external repositories,
replacing the version number in the `url` attribute with the version of the
rules you wish to depend on:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/archive/refs/heads/main.tar.gz",
    strip_prefix = "rules_xcodeproj-main",
)

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()

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

## Examples

Minimal example:

```python
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)

swift_library(
    name = "Lib",
    srcs = glob(["**/*.swift"]),
)

ios_application(
    name = "App",
    bundle_id = "com.example.app",
    families = ["iphone", "ipad"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    deps = [":Lib"],
)

xcodeproj(
    name = "xcodeproj",
    project_name = "App",
    targets = [
        ":App",
    ],
    tags = ["manual"],
)
```

You can then create the Xcode project with:

```shell
bazel run //:xcodeproj
```

The generated project will be in the workspace at `App.xcodeproj`.

See the [examples](examples) directory for sample setups.

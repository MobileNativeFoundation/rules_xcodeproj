<p align="center">
  <img src="https://user-images.githubusercontent.com/158658/161647598-223361dc-030d-431a-b4fe-d92592ed5530.png" height="255">
</p>

# rules_xcodeproj

This repository contains rules for [Bazel](https://bazel.build) that can be
used to generate Xcode projects from targets in your workspace.

If you run into any problems with these rules, please check if
[another issue already exists][issues] and comment on it, and if not,
[file an issue][file-an-issue]!

[issues]: https://github.com/buildbuddy-io/rules_xcodeproj/issues
[file-an-issue]: https://github.com/buildbuddy-io/rules_xcodeproj/issues/new/choose

## Features

- [x] Build Bazel targets with Xcode (_not_ Bazel), with full support for:
  - [x] Indexing (i.e. autocomplete, syntax highlighting, jump to
    definition)
  - [x] Debugging
  - [x] Inline warnings and errors
  - [x] Fix-its
  - [x] Tests (Unit and UI)
  - [x] SwiftUI Previews

**Note:** Not all rules are supported yet, and the rules that are supported
don't have full support yet. See the
[1.0 Project](https://github.com/orgs/buildbuddy-io/projects/2/views/3)
for details on progress towards the 1.0 release. Here are a few of the planned
high level features:

- [ ] [Support all Core C/C++/Obj-C, rules_apple, and rules_swift rules](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/1)
- [ ] [Build Bazel targets with Bazel, in Xcode](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/2)
- [ ] [Easier target discovery and focused projects](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/3)

## Compatibility

- macOS 12.0-12.3
- Xcode 13.0-13.3
- Bazel 5.1.0
- rules_swift 0.27.0
- rules_apple 0.34.0

More versions of these tools and rulesets might be supported, but these are the
ones we've officially tested with.

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

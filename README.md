<p align="center">
  <img src="https://user-images.githubusercontent.com/158658/161647598-223361dc-030d-431a-b4fe-d92592ed5530.png" height="255">
</p>

# rules_xcodeproj

This repository contains rules for [Bazel](https://bazel.build) that can be
used to generate Xcode projects from targets in your workspace.

If you run into any problems with these rules, please check our
[FAQ](/doc/faq.md), check if [another issue already exists][issues] and comment
on it, or [file a new issue][file-an-issue]!

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

We've also documented the [high level design](/doc/design/high-level.md) of the
rules.

## Compatibility

- macOS 12.0-12.4
- Xcode 13.0-13.3.1
- Bazel 5.2.0
- rules_swift post-0.27.0 (a release with https://github.com/bazelbuild/rules_swift/commit/8d4b096b90e47095755e47c27e749ae9b9f83e81)
- rules_apple post-0.34.2 (a release with https://github.com/bazelbuild/rules_apple/commit/029eab0a6bbb4147d227d623721b205eb62aca9c)

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
    sha256 = "5a902801e2337fc14faeb2613d70202f2dd4755bba3d94ba068c1f622edba89e",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.3.0/release.tar.gz",
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

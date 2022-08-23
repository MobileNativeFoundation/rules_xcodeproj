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

- [x] Multiple ways of building your project in Xcode
  - [x] Build your Bazel targets with Xcode, _not_ Bazel
    (a.k.a. Build with Xcode or BwX mode)
  - [x] Build your Bazel targets with Bazel (a.k.a Build with Bazel or BwB mode)
- [x] Full support for Xcode features:
  - [x] Indexing (i.e. autocomplete, syntax highlighting, jump to
    definition)
  - [x] Debugging
  - [x] Inline warnings and errors
  - [x] Fix-its (currently only BwX)
  - [x] Test selection and running
  - [x] Embedded Targets (App Clips, App Extensions, and Watch Apps)
  - [x] SwiftUI Previews
- [x] Focused Projects
  - [x] Include a subset of your targets in Xcode
  - [x] Unfocused targets are built with Bazel
  - [x] Works in BwX mode as well!

**Note:** Not all rules are supported yet, and the rules that are supported
don't have full support yet. See the
[1.0 Project](https://github.com/orgs/buildbuddy-io/projects/2/views/3)
for details on progress towards the 1.0 release. Here are a few of the remaining
planned high level features:

- [ ] [Supporting all Core C/C++/Obj-C, rules_apple, and rules_swift rules](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/4)
- [ ] [Multiple Xcode configurations](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/9)
- [ ] [Frameworks](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/14)

We've also documented the [high level design](/doc/design/high-level.md) of the
rules.

## Compatibility

- macOS 12.0-12.4
- Xcode 13.0-13.4.1
- Bazel 5.2.0-5.3.0
- rules_swift 1.0.0-1.1.0
- rules_apple 1.0.1-1.1.0

More versions of these tools and rulesets might be supported, but these are the
ones we've officially tested with.

## Quick setup

Add the following to your `WORKSPACE` file to add the external repositories,
replacing the version number in the `url` attribute with the version of the
rules you wish to depend on:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "a647ad9ee6664a78377cf5707331966b6788be09d1fea48045a61bc450c8f1b1",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.7.0/release.tar.gz",
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
    tags = ["manual"],
    top_level_targets = [
        ":App",
    ],
)
```

You can then create the Xcode project with:

```shell
bazel run //:xcodeproj
```

The generated project will be in the workspace at `App.xcodeproj`.

See the [examples](examples) directory for sample setups.

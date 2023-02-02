<p align="center">
  <img src="https://user-images.githubusercontent.com/158658/161647598-223361dc-030d-431a-b4fe-d92592ed5530.png" width="255">
</p>

# rules_xcodeproj

This repository contains rules for [Bazel](https://bazel.build) that can be
used to generate Xcode projects from targets in your workspace.

If you run into any problems with these rules, please check our
[FAQ](/docs/faq.md), check if [another issue already exists][issues] and comment
on it, or [file a new issue][file-an-issue]!

[issues]: https://github.com/buildbuddy-io/rules_xcodeproj/issues
[file-an-issue]: https://github.com/buildbuddy-io/rules_xcodeproj/issues/new/choose

## Features

- [x] Full support for Xcode features:
  - [x] Indexing (i.e. autocomplete, syntax highlighting, jump to definition)
  - [x] Debugging
  - [x] Runtime sanitizers
  - [x] Inline warnings and errors
  - [x] Fix-its (currently only in BwX mode)
  - [x] Test selection and running
  - [x] Embedded Targets (App Clips, App Extensions, and Watch Apps)
  - [X] Dynamic frameworks
  - [x] SwiftUI Previews
- [x] Focused Projects
  - [x] Include a subset of your targets in Xcode
  - [x] Unfocused targets are built with Bazel
  - [x] Works in BwX mode as well!
- [x] Comprehensive Bazel rules support
  - [x] Core Bazel C/C++/Objective-C
  - [x] rules_swift
  - [x] rules_apple
  - [x] rules_ios
  - [x] Most likely your custom rules as well!
- [x] Minimal configuration needed (see the [usage](#usage) section below)
- [x] Multiple ways of building your project in Xcode
  - [x] Build your Bazel targets with Bazel (a.k.a Build with Bazel or BwB mode)
  - [x] Build your Bazel targets with Xcode, _not_ Bazel
    (a.k.a. Build with Xcode or BwX mode)[^bwx_warning]
- [x] It “just works”

[^bwx_warning]: Build with Bazel mode is the build mode with first class
  support. We will try to make Build with Xcode mode work with every project, but
  there are limitations that can
  [make the experience subpar](/docs/faq.md#why-do-some-of-my-swift_librarys-compile-twice-in-bwx-mode),
  or not work at all. We recommend using BwB mode if possible.

We’ve also documented the [high-level design goals](/docs/design-goals.md) of
the ruleset.

## Projects using rules_xcodeproj

- Cash App
- Envoy Mobile
- Ergatta
- Lyft
- [Mercari](https://engineering.mercari.com/blog/entry/20221215-16cdd59909/)
- Robinhood
- [Slack](https://www.youtube.com/watch?v=wy3Q38VJ5uQ)
- Spotify
- SwiftLint
- Ten Ten
- Tinder

If you are also using rules_xcodeproj for your project, feel free to open a PR
to include it in the list above.

## Compatibility

| rules_xcodeproj | Bazel | [rules_apple][1] | [rules_swift][2] | Xcode | macOS | Supporting Branch |
| :-------------: | :---: | :--------------: | :--------------: | :---: | :---: | :---------------: |
| 1.x | 5.3–6.x  | 1.0.1–2.x | 1.x | 13.3–14.x | 12–13.x | `main` |

More versions of these tools and rulesets might be supported, but these are the
ones we’ve officially tested with.

[1]: https://github.com/bazelbuild/rules_apple
[2]: https://github.com/bazelbuild/rules_swift

## Installation

From the
[release you wish to use](https://github.com/buildbuddy-io/rules_xcodeproj/releases),
copy the Bzlmod or WORKSPACE snippet into your repository.

## Usage

Please see the documentation in the [docs](docs/README.md) directory and
examples in the [examples](examples/README.md) directory.

### BazelCon 2022

<a href="https://youtu.be/B__SHnz3K3c" title="YouTube - How to integrate Bazel with Xcode using rules_xcodeproj"><img src="https://img.youtube.com/vi/B__SHnz3K3c/maxresdefault.jpg" alt="YouTube - How to integrate Bazel with Xcode using rules_xcodeproj" width="640"></a>

### Simple iOS example

Given a root level `BUILD` file:
```python
load(
  "@build_bazel_rules_apple//apple:ios.bzl",
  "ios_application",
  "ios_unit_test",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
)

xcodeproj(
    name = "xcodeproj",
    project_name = "App",
    tags = ["manual"],
    top_level_targets = [
        top_level_target(":App", target_environments = ["device", "simulator"]),
        ":Tests",
    ],
)

ios_application(
    name = "App",
    bundle_id = "com.example.app",
    families = ["iphone", "ipad"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    deps = [":Lib"],
)

swift_library(
    name = "Lib",
    srcs = glob(["src/*.swift"]),
)

ios_unit_test(
    name = "Tests",
    bundle_id = "com.example.tests",
    minimum_os_version = "15.0",
    test_host = "//App",
    visibility = ["//visibility:public"],
    deps = [":TestLib"],
)

swift_library(
    name = "TestLib",
    srcs = glob(["test/*.swift"]),
)
```

You can then create the Xcode project with:

```shell
bazel run //:xcodeproj
```

The generated project will be in the workspace next to the `BUILD` file at
`App.xcodeproj`.

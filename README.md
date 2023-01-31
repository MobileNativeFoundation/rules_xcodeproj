<p align="center">
  <img src="https://user-images.githubusercontent.com/158658/161647598-223361dc-030d-431a-b4fe-d92592ed5530.png" height="255">
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

- [x] Multiple ways of building your project in Xcode
  - [x] Build your Bazel targets with Xcode, _not_ Bazel
    (a.k.a. Build with Xcode or BwX mode)
  - [x] Build your Bazel targets with Bazel (a.k.a Build with Bazel or BwB mode)
- [x] Full support for Xcode features:
  - [x] Indexing (i.e. autocomplete, syntax highlighting, jump to
    definition)
  - [x] Debugging
  - [x] Runtime sanitizers
  - [x] Inline warnings and errors
  - [x] Fix-its (currently only BwX)
  - [x] Test selection and running
  - [x] Embedded Targets (App Clips, App Extensions, and Watch Apps)
  - [X] Dynamic frameworks
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
- [ ] [Distribution rules](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/18)
- [ ] [Multiple Xcode configurations](https://github.com/buildbuddy-io/rules_xcodeproj/milestone/17)

We've also documented the [high level design](/docs/design/high-level.md) of the
rules.

## Projects using rules_xcodeproj

- [Envoy Mobile](https://github.com/envoyproxy/envoy-mobile)
- Ergatta
- Lyft
- [Mercari](https://engineering.mercari.com/blog/entry/20221215-16cdd59909/)
- Robinhood
- [Slack](https://www.youtube.com/watch?v=wy3Q38VJ5uQ)
- Spotify
- [SwiftLint](https://github.com/realm/SwiftLint)
- Ten Ten
- Tinder

If you are also using rules_xcodeproj for your project, feel free to open a PR
to include it in the list above.

## Compatibility

| Versions | Bazel | [rules_apple][1] | [rules_swift][2] | Xcode | macOS | Branch |
| :------: | :---: | :--------------: | :--------------: | :---: | :---: | :----: |
| 1.x | 5.3–6.x  | 1.0.1–2.x | 1.x | 13.3–14.x | 12–13.x | `main` |

More versions of these tools and rulesets might be supported, but these are the
ones we've officially tested with.

[1]: https://github.com/bazelbuild/rules_apple
[2]: https://github.com/bazelbuild/rules_swift

## Installation

From the
[release you wish to use](https://github.com/buildbuddy-io/rules_xcodeproj/releases),
copy the Bzlmod or WORKSPACE snippet into your repository.

## Usage

Please see the documentation in the [docs](docs/README.md) directory and
examples in the [examples](examples/README.md) directory.

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

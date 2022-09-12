# Bazel rules and macros

### Usage

To use these rules and macros in your `BUILD` files, `load` them from
`xcodeproj/xcodeproj.bzl`.

For example, to use the `xcodeproj` rule, you would need to use
this `load` statement:

```starlark
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
```

### Index

- [Core](#core)
  - [`xcodeproj`](#xcodeproj)
  - [`top_level_target`](#top_level_target)
- [Custom Xcode schemes](#custom-xcode-schemes)
  - [`xcode_schemes.scheme`](#xcode_schemes.scheme)
  - [`xcode_schemes.build_action`](#xcode_schemes.build_action)
  - [`xcode_schemes.build_target`](#xcode_schemes.build_target)
  - [`xcode_schemes.build_for`](#xcode_schemes.build_for)
  - [`xcode_schemes.launch_action`](#xcode_schemes.launch_action)
  - [`xcode_schemes.test_action`](#xcode_schemes.test_action)
- [Xcode build settings](#xcode-build-settings)
  - [`xcode_provisioning_profile`](#xcode_provisioning_profile)
- [Providers](#providers)
  - [`XcodeProjAutomaticTargetProcessingInfo`](#XcodeProjAutomaticTargetProcessingInfo)
  - [`XcodeProjInfo`](#XcodeProjInfo)

# Core

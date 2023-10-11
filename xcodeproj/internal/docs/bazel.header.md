# Bazel rules and macros

### Usage

To use these rules and macros in your `BUILD` files, `load` them from
`xcodeproj/defs.bzl`.

For example, to use the [`xcodeproj`](#xcodeproj) rule, you would need to use
this `load` statement:

```starlark
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
```

### Index

- [Core](#core)
  - [`xcodeproj`](#xcodeproj)
  - [`top_level_target`](#top_level_target)
  - [`top_level_targets`](#top_level_targets)
  - [`project_options`](#project_options)
- [Custom Xcode schemes (Legacy generation mode)](#custom-xcode-schemes-legacy-generation-mode)
  - [`xcode_schemes.scheme`](#xcode_schemes.scheme)
  - [`xcode_schemes.build_action`](#xcode_schemes.build_action)
  - [`xcode_schemes.build_target`](#xcode_schemes.build_target)
  - [`xcode_schemes.build_for`](#xcode_schemes.build_for)
  - [`xcode_schemes.launch_action`](#xcode_schemes.launch_action)
  - [`xcode_schemes.profile_action`](#xcode_schemes.profile_action)
  - [`xcode_schemes.test_action`](#xcode_schemes.test_action)
  - [`xcode_schemes.diagnostics`](#xcode_schemes.diagnostics)
  - [`xcode_schemes.sanitizers`](#xcode_schemes.sanitizers)
  - [`xcode_schemes.pre_post_action`](#xcode_schemes.pre_post_action)
- [Custom Xcode schemes (Incremental generation mode)](#custom-xcode-schemes-incremental-generation-mode)
  - [`xcschemes.scheme`](#xcschemes.scheme)
  - [`xcschemes.test`](#xcschemes.test)
  - [`xcschemes.run`](#xcschemes.run)
  - [`xcschemes.profile`](#xcschemes.profile)
  - [`xcschemes.launch_target`](#xcschemes.launch_target)
  - [`xcschemes.test_target`](#xcschemes.test_target)
  - [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target)
  - [`xcschemes.top_level_anchor_build_target`](#xcschemes.top_level_anchor_build_target)
  - [`xcschemes.library_target`](#xcschemes.library_target)
  - [`xcschemes.arg`](#xcschemes.arg)
  - [`xcschemes.env_value`](#xcschemes.env_value)
  - [`xcschemes.pre_post_actions.build_script`](#xcschemes.pre_post_actions.build_script)
  - [`xcschemes.pre_post_actions.launch_script`](#xcschemes.pre_post_actions.launch_script)
- [Xcode build settings](#xcode-build-settings)
  - [`xcode_provisioning_profile`](#xcode_provisioning_profile)
- [Providers](#providers)
  - [`XcodeProjAutomaticTargetProcessingInfo`](#XcodeProjAutomaticTargetProcessingInfo)
  - [`XcodeProjInfo`](#XcodeProjInfo)

# Core

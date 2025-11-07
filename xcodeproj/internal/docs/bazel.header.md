# Bazel rules and macros

### Usage

To use these rules and macros in your `BUILD` files, `load` them from their
respective bzl file.

For example, to use the [`xcodeproj`](#xcodeproj) rule, you would need to use
this `load` statement:

```starlark
load("@rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")
```

### Index

- [Core](#core)
  - [`xcodeproj`](#xcodeproj)
  - [`top_level_target`](#top_level_target)
  - [`top_level_targets`](#top_level_targets)
  - [`project_options`](#project_options)
- [Custom Xcode schemes](#custom-xcode-schemes)
  - [`xcschemes.scheme`](#xcschemes.scheme)
  - [`xcschemes.test`](#xcschemes.test)
  - [`xcschemes.run`](#xcschemes.run)
  - [`xcschemes.profile`](#xcschemes.profile)
  - [`xcschemes.launch_target`](#xcschemes.launch_target)
  - [`xcschemes.test_target`](#xcschemes.test_target)
  - [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target)
  - [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target)
  - [`xcschemes.library_target`](#xcschemes.library_target)
  - [`xcschemes.arg`](#xcschemes.arg)
  - [`xcschemes.env_value`](#xcschemes.env_value)
  - [`xcschemes.pre_post_actions.build_script`](#xcschemes.pre_post_actions.build_script)
  - [`xcschemes.pre_post_actions.launch_script`](#xcschemes.pre_post_actions.launch_script)
  - [`xcschemes.autogeneration_config`](#xcschemes.autogeneration_config)
- [Xcode build settings](#xcode-build-settings)
  - [`xcode_provisioning_profile`](#xcode_provisioning_profile)
- [Providers](#providers)
  - [`XcodeProjAutomaticTargetProcessingInfo`](#XcodeProjAutomaticTargetProcessingInfo)
  - [`XcodeProjInfo`](#XcodeProjInfo)
- [Aspect Hints](#aspect-hints)
  - [`xcodeproj_extra_files`](#xcodeproj_extra_files)

# Core

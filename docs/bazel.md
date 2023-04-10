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
- [Custom Xcode schemes](#custom-xcode-schemes)
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
- [Xcode build settings](#xcode-build-settings)
  - [`xcode_provisioning_profile`](#xcode_provisioning_profile)
- [Providers](#providers)
  - [`XcodeProjAutomaticTargetProcessingInfo`](#XcodeProjAutomaticTargetProcessingInfo)
  - [`XcodeProjInfo`](#XcodeProjInfo)

# Core


<a id="xcodeproj"></a>

## xcodeproj

<pre>
xcodeproj(<a href="#xcodeproj-name">name</a>, <a href="#xcodeproj-adjust_schemes_for_swiftui_previews">adjust_schemes_for_swiftui_previews</a>, <a href="#xcodeproj-archived_bundles_allowed">archived_bundles_allowed</a>,
          <a href="#xcodeproj-associated_extra_files">associated_extra_files</a>, <a href="#xcodeproj-bazel_path">bazel_path</a>, <a href="#xcodeproj-bazel_env">bazel_env</a>, <a href="#xcodeproj-build_mode">build_mode</a>, <a href="#xcodeproj-config">config</a>,
          <a href="#xcodeproj-default_xcode_configuration">default_xcode_configuration</a>, <a href="#xcodeproj-extra_files">extra_files</a>, <a href="#xcodeproj-fail_for_invalid_extra_files_targets">fail_for_invalid_extra_files_targets</a>,
          <a href="#xcodeproj-focused_targets">focused_targets</a>, <a href="#xcodeproj-install_directory">install_directory</a>, <a href="#xcodeproj-ios_device_cpus">ios_device_cpus</a>, <a href="#xcodeproj-ios_simulator_cpus">ios_simulator_cpus</a>,
          <a href="#xcodeproj-minimum_xcode_version">minimum_xcode_version</a>, <a href="#xcodeproj-post_build">post_build</a>, <a href="#xcodeproj-pre_build">pre_build</a>, <a href="#xcodeproj-project_name">project_name</a>, <a href="#xcodeproj-project_options">project_options</a>,
          <a href="#xcodeproj-scheme_autogeneration_mode">scheme_autogeneration_mode</a>, <a href="#xcodeproj-schemes">schemes</a>, <a href="#xcodeproj-temporary_directory">temporary_directory</a>, <a href="#xcodeproj-top_level_targets">top_level_targets</a>,
          <a href="#xcodeproj-tvos_device_cpus">tvos_device_cpus</a>, <a href="#xcodeproj-tvos_simulator_cpus">tvos_simulator_cpus</a>, <a href="#xcodeproj-unfocused_targets">unfocused_targets</a>, <a href="#xcodeproj-watchos_device_cpus">watchos_device_cpus</a>,
          <a href="#xcodeproj-watchos_simulator_cpus">watchos_simulator_cpus</a>, <a href="#xcodeproj-xcode_configurations">xcode_configurations</a>, <a href="#xcodeproj-kwargs">kwargs</a>)
</pre>

Creates an `.xcodeproj` file in the workspace when run.

This is a wrapper macro for the
[actual `xcodeproj` rule](../xcodeproj/internal/xcodeproj_rule.bzl), which
can't be used directly. All public API is documented below. The `kwargs`
argument will pass forward values for globally available attributes (e.g.
`visibility`, `features`, etc.) to the underlying rule.

**EXAMPLE**

```starlark
xcodeproj(
    name = "xcodeproj",
    project_name = "App",
    tags = ["manual"],
    top_level_targets = [
        top_level_target(":App", target_environments = ["device", "simulator"]),
        ":Tests",
    ],
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcodeproj-name"></a>name |  A unique name for this target.   |  none |
| <a id="xcodeproj-adjust_schemes_for_swiftui_previews"></a>adjust_schemes_for_swiftui_previews |  Optional. Whether to adjust schemes in BwB mode to explicitly include transitive dependencies that are able to run SwiftUI Previews. For example, this changes a scheme for an single application target to also include any app clip, app extension, framework, or watchOS app dependencies. Defaults to <code>True</code>.   |  <code>True</code> |
| <a id="xcodeproj-archived_bundles_allowed"></a>archived_bundles_allowed |  This argument is deprecated and is now a no-op. It will be removed in a future release. Adjust the setting of <code>--define=apple.experimental.tree_artifact_outputs</code> on <code>build:rules_xcodeproj</code> in your <code>.bazelrc</code> or <code>xcodeproj.bazelrc</code> file.   |  <code>None</code> |
| <a id="xcodeproj-associated_extra_files"></a>associated_extra_files |  Optional. A <code>dict</code> of files to be added to the project. The key is a <code>string</code> value representing the label of the target the files should be associated with, and the value is a <code>list</code> of <code>File</code>s. These files won't be added to the project if the target is unfocused.   |  <code>{}</code> |
| <a id="xcodeproj-bazel_path"></a>bazel_path |  Optional. The path the <code>bazel</code> binary or wrapper script. If the path is relative it will be resolved using the <code>PATH</code> environment variable that is set when generating the project. If you want to specify a path to a workspace-relative binary, you must prepend the path with <code>./</code> (e.g. <code>"./bazelw"</code>).   |  <code>"bazel"</code> |
| <a id="xcodeproj-bazel_env"></a>bazel_env |  Optional. A <code>dict</code> of environment variables to set when invoking <code>bazel_path</code>. This is useful for setting environment variables that are required for Bazel actions to run successfully, such as <code>JAVA_HOME</code> or <code>ANDROID_HOME</code>. It's also useful if <code>bazel_path</code> itself (if it's a wrapper) needs certain environment variables. The keys are the names of the environment variables, and the values are the values of the environment variables. If a value is <code>None</code>, the environment variable will be picked up from the current environment. If project generation succeeds, but building inside of Xcode fails because of missing environment variables, you probably have to set them here. If <code>PATH</code> is not specified, it will default to <code>/usr/bin:/bin</code>, so you don't have to specify it unless you want to user a different value   |  <code>{"PATH": "/usr/bin:/bin"}</code> |
| <a id="xcodeproj-build_mode"></a>build_mode |  Optional. The build mode the generated project should use.<br><br>If this is set to <code>"xcode"</code>, the project will use the Xcode build system to build targets. Generated files and unfocused targets (see the <code>focused_targets</code> and <code>unfocused_targets</code> arguments) will be built with Bazel.<br><br>If this is set to <code>"bazel"</code>, the project will use Bazel to build targets, inside of Xcode. The Xcode build system still unavoidably orchestrates some things at a high level.   |  <code>"bazel"</code> |
| <a id="xcodeproj-config"></a>config |  Optional. The Bazel config to use when generating the project or invoking <code>bazel</code> inside of Xcode. This is the basename of multiple configs. For example, if this is set to <code>"projectx_xcodeproj"</code>, then the following configs will be available for you to adjust in your <code>.bazelrc</code> file: <code>projectx_xcodeproj</code>, <code>projectx_xcodeproj_generator</code>, <code>projectx_xcodeproj_indexbuild</code>, and <code>projectx_xcodeproj_swiftuipreviews</code>.<br><br>See the [usage guide](usage.md#bazel-configs) for more information on adjusting Bazel configs.   |  <code>"rules_xcodeproj"</code> |
| <a id="xcodeproj-default_xcode_configuration"></a>default_xcode_configuration |  Optional. The name of the the Xcode configuration to use when building, if not overridden by custom schemes. If not set, the first Xcode configuration alphabetically will be used. Use [<code>xcode_configurations</code>](#xcodeproj-xcode_configurations) to adjust Xcode configurations.   |  <code>None</code> |
| <a id="xcodeproj-extra_files"></a>extra_files |  Optional. A <code>list</code> of extra <code>File</code>s to be added to the project.   |  <code>[]</code> |
| <a id="xcodeproj-fail_for_invalid_extra_files_targets"></a>fail_for_invalid_extra_files_targets |  Optional. Determines wether, when processing targets, invalid extra files without labels will fail or just emit a warning. Defaults to <code>True</code>.   |  <code>True</code> |
| <a id="xcodeproj-focused_targets"></a>focused_targets |  Optional. A <code>list</code> of target labels as <code>string</code> values. If specified, only these targets will be included in the generated project; all other targets will be excluded, as if they were listed explicitly in the <code>unfocused_targets</code> argument. The labels must match transitive dependencies of the targets specified in the <code>top_level_targets</code> argument.   |  <code>[]</code> |
| <a id="xcodeproj-install_directory"></a>install_directory |  Optional. The directory where the generated project will be written to. The path is relative to the workspace root. Defaults to the directory that the <code>xcodeproj</code> target is declared in (e.g. if the <code>xcodeproj</code> target is declared in <code>//foo/bar:BUILD</code> then the default value is <code>"foo/bar"</code>). Use <code>""</code> to have the project generated in the workspace root.   |  <code>None</code> |
| <a id="xcodeproj-ios_device_cpus"></a>ios_device_cpus |  Optional. The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't iOS targets.   |  <code>"arm64"</code> |
| <a id="xcodeproj-ios_simulator_cpus"></a>ios_simulator_cpus |  Optional. The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't iOS targets.   |  <code>None</code> |
| <a id="xcodeproj-minimum_xcode_version"></a>minimum_xcode_version |  Optional. The minimum Xcode version that the generated project supports. Newer Xcode versions can support newer features, so setting this to the highest value you can will enable the most features. The value is the dot separated version number (e.g. "13.4.1", "14", "14.1"). Defaults to whichever version of Xcode that Bazel uses during project generation.   |  <code>None</code> |
| <a id="xcodeproj-post_build"></a>post_build |  The text of a script that will be run after the build. For example: <code>./post-build.sh</code>, <code>"$SRCROOT/post-build.sh"</code>.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the <code>$SRCROOT</code> directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure <code>$ACTION == build</code>.   |  <code>None</code> |
| <a id="xcodeproj-pre_build"></a>pre_build |  The text of a script that will be run before the build. For example: <code>./pre-build.sh</code>, <code>"$SRCROOT/pre-build.sh"</code>.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the <code>$SRCROOT</code> directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure <code>$ACTION == build</code>.   |  <code>None</code> |
| <a id="xcodeproj-project_name"></a>project_name |  Optional. The name to use for the <code>.xcodeproj</code> file. If not specified, the value of the <code>name</code> argument is used.   |  <code>None</code> |
| <a id="xcodeproj-project_options"></a>project_options |  Optional. A value returned by <code>project_options</code>.   |  <code>None</code> |
| <a id="xcodeproj-scheme_autogeneration_mode"></a>scheme_autogeneration_mode |  Optional. Specifies how Xcode schemes are automatically generated.<br><br>- <code>auto</code>: If no custom schemes are specified, via <code>schemes</code>, an   Xcode scheme will be created for every buildable target. If custom   schemes are provided, no autogenerated schemes will be created.<br><br>- <code>none</code>: No schemes are automatically generated.<br><br>- <code>all</code>: A scheme is generated for every buildable target even if   custom schemes are provided.   |  <code>"auto"</code> |
| <a id="xcodeproj-schemes"></a>schemes |  Optional. A <code>list</code> of values returned by <code>xcode_schemes.scheme</code>. Target labels listed in the schemes need to be from the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument. This and the <code>scheme_autogeneration_mode</code> argument together customize how schemes for those targets are generated.   |  <code>[]</code> |
| <a id="xcodeproj-temporary_directory"></a>temporary_directory |  This argument is deprecated and is now a no-op. It will be removed in a future release.   |  <code>None</code> |
| <a id="xcodeproj-top_level_targets"></a>top_level_targets |  A <code>list</code> of a list of top-level targets. Each target can be specified as either a <code>Label</code> (or label-like <code>string</code>), a value returned by <code>top_level_target</code>, or a value returned by <code>top_level_targets</code>.   |  none |
| <a id="xcodeproj-tvos_device_cpus"></a>tvos_device_cpus |  Optional. The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't tvOS targets.   |  <code>"arm64"</code> |
| <a id="xcodeproj-tvos_simulator_cpus"></a>tvos_simulator_cpus |  Optional. The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't tvOS targets.   |  <code>None</code> |
| <a id="xcodeproj-unfocused_targets"></a>unfocused_targets |  Optional. A <code>list</code> of target labels as <code>string</code> values. Any targets in the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with a matching label will be excluded from the generated project. This overrides any targets specified in the <code>focused_targets</code> argument.   |  <code>[]</code> |
| <a id="xcodeproj-watchos_device_cpus"></a>watchos_device_cpus |  Optional. The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't watchOS targets.   |  <code>"arm64_32"</code> |
| <a id="xcodeproj-watchos_simulator_cpus"></a>watchos_simulator_cpus |  Optional. The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't watchOS targets.   |  <code>None</code> |
| <a id="xcodeproj-xcode_configurations"></a>xcode_configurations |  Optional. A <code>dict</code> mapping Xcode configuration names to transition settings dictionaries. For example, <code>{"Dev": {"//command_line_option:compilation_mode": "dbg"}, "AppStore": {"//command_line_option:compilation_mode": "opt"}}</code>, would create the "Dev" and "AppStore" configurations, setting <code>--compilation_mode</code> to <code>dbg</code> and <code>opt</code> respectively.<br><br>Refer to the [bazel documentation](https://bazel.build/extending/config#defining) on how to define the transition settings dictionary.   |  <code>{"Debug": {}}</code> |
| <a id="xcodeproj-kwargs"></a>kwargs |  Additional arguments to pass to the underlying <code>xcodeproj</code> rule specified by <code>xcodeproj_rule</code>.   |  none |




<a id="top_level_target"></a>

## top_level_target

<pre>
top_level_target(<a href="#top_level_target-label">label</a>, <a href="#top_level_target-target_environments">target_environments</a>)
</pre>

Constructs a top-level target for use in `xcodeproj.top_level_targets`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="top_level_target-label"></a>label |  A <code>Label</code> or label-like string for the target.   |  none |
| <a id="top_level_target-target_environments"></a>target_environments |  Optional. A <code>list</code> of target environment strings (see <code>@build_bazel_apple_support//constraints:target_environment</code>; <code>"catalyst"</code> is not currently supported). The target will be configured for each environment.<br><br>If multiple environments are specified, then a single combined Xcode target will be created if possible. If the configured targets are the same for each environment (e.g. macOS for <code>["device", "simulator"]</code>), they will appear as separate but similar Xcode targets. If no environments are specified, the <code>"simulator"</code> environment will be used.   |  <code>["simulator"]</code> |

**RETURNS**

A `struct` containing fields for the provided arguments.


<a id="top_level_targets"></a>

## top_level_targets

<pre>
top_level_targets(<a href="#top_level_targets-labels">labels</a>, <a href="#top_level_targets-target_environments">target_environments</a>)
</pre>

Constructs a list of top-level target for use in     `xcodeproj.top_level_targets`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="top_level_targets-labels"></a>labels |  A <code>list</code> of <code>Label</code> or label-like string for the targets.   |  none |
| <a id="top_level_targets-target_environments"></a>target_environments |  Optional. See [<code>top_level_target.target_environments</code>](#top_level_target-target_environments).   |  <code>["simulator"]</code> |

**RETURNS**

A `list` of values returned from `top_level_target`.




<a id="project_options"></a>

## project_options

<pre>
project_options(<a href="#project_options-development_region">development_region</a>, <a href="#project_options-indent_width">indent_width</a>, <a href="#project_options-organization_name">organization_name</a>, <a href="#project_options-tab_width">tab_width</a>, <a href="#project_options-uses_tabs">uses_tabs</a>)
</pre>

Project options for use in `xcodeproj.project_options`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="project_options-development_region"></a>development_region |  Optional. The development region for the project. Defaults to <code>"en"</code>.   |  <code>"en"</code> |
| <a id="project_options-indent_width"></a>indent_width |  Optional. The number of spaces to use for indentation.   |  <code>None</code> |
| <a id="project_options-organization_name"></a>organization_name |  Optional. Populates the <code>ORGANIZATIONNAME</code> attribute for the project.   |  <code>None</code> |
| <a id="project_options-tab_width"></a>tab_width |  Optional. The number of spaces to use for tabs.   |  <code>None</code> |
| <a id="project_options-uses_tabs"></a>uses_tabs |  Optional. Whether to use tabs for indentation.   |  <code>None</code> |

**RETURNS**

A `struct` containing fields for the provided arguments.


# Custom Xcode schemes

To use these functions, `load` the `xcode_schemes` module from
`xcodeproj/defs.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_schemes")
```


<a id="xcode_schemes.scheme"></a>

## xcode_schemes.scheme

<pre>
xcode_schemes.scheme(<a href="#xcode_schemes.scheme-name">name</a>, <a href="#xcode_schemes.scheme-build_action">build_action</a>, <a href="#xcode_schemes.scheme-launch_action">launch_action</a>, <a href="#xcode_schemes.scheme-profile_action">profile_action</a>, <a href="#xcode_schemes.scheme-test_action">test_action</a>)
</pre>

Returns a `struct` representing an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.scheme-name"></a>name |  The user-visible name for the scheme as a <code>string</code>.   |  none |
| <a id="xcode_schemes.scheme-build_action"></a>build_action |  Optional. A value returned by <code>xcode_schemes.build_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-launch_action"></a>launch_action |  Optional. A value returned by <code>xcode_schemes.launch_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-profile_action"></a>profile_action |  Optional. A value returned by <code>xcode_schemes.profile_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-test_action"></a>test_action |  Optional. A value returned by <code>xcode_schemes.test_action</code>.   |  <code>None</code> |

**RETURNS**

A `struct` representing an Xcode scheme.


<a id="xcode_schemes.build_action"></a>

## xcode_schemes.build_action

<pre>
xcode_schemes.build_action(<a href="#xcode_schemes.build_action-targets">targets</a>, <a href="#xcode_schemes.build_action-pre_actions">pre_actions</a>, <a href="#xcode_schemes.build_action-post_actions">post_actions</a>)
</pre>

Constructs a build action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_action-targets"></a>targets |  A <code>sequence</code> of elements that are either <code>struct</code> values as created by <code>xcode_schemes.build_target</code>, or a target label as a <code>string</code> value.   |  none |
| <a id="xcode_schemes.build_action-pre_actions"></a>pre_actions |  A <code>sequence</code> of <code>struct</code> values as created by <code>xcode_schemes.pre_action</code>.   |  <code>[]</code> |
| <a id="xcode_schemes.build_action-post_actions"></a>post_actions |  A <code>sequence</code> of <code>struct</code> values as created by <code>xcode_schemes.post_action</code>.   |  <code>[]</code> |

**RETURNS**

A `struct` representing a build action.


<a id="xcode_schemes.build_target"></a>

## xcode_schemes.build_target

<pre>
xcode_schemes.build_target(<a href="#xcode_schemes.build_target-label">label</a>, <a href="#xcode_schemes.build_target-build_for">build_for</a>)
</pre>

Constructs a build target for an Xcode scheme's build action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_target-label"></a>label |  A target label as a <code>string</code> value.   |  none |
| <a id="xcode_schemes.build_target-build_for"></a>build_for |  Optional. The settings that dictate when Xcode will build the target. It is a value returned by <code>xcode_schemes.build_for</code>.   |  <code>None</code> |

**RETURNS**

A `struct` representing a build target.


<a id="xcode_schemes.build_for"></a>

## xcode_schemes.build_for

<pre>
xcode_schemes.build_for(<a href="#xcode_schemes.build_for-running">running</a>, <a href="#xcode_schemes.build_for-testing">testing</a>, <a href="#xcode_schemes.build_for-profiling">profiling</a>, <a href="#xcode_schemes.build_for-archiving">archiving</a>, <a href="#xcode_schemes.build_for-analyzing">analyzing</a>)
</pre>

Construct a `struct` representing the settings that dictate when Xcode     will build a target.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_for-running"></a>running |  Optional. A <code>bool</code> specifying whether to build for the running phase.   |  <code>None</code> |
| <a id="xcode_schemes.build_for-testing"></a>testing |  Optional. A <code>bool</code> specifying whether to build for the testing phase.   |  <code>None</code> |
| <a id="xcode_schemes.build_for-profiling"></a>profiling |  Optional. A <code>bool</code> specifying whether to build for the profiling phase.   |  <code>None</code> |
| <a id="xcode_schemes.build_for-archiving"></a>archiving |  Optional. A <code>bool</code> specifying whether to build for the archiving phase.   |  <code>None</code> |
| <a id="xcode_schemes.build_for-analyzing"></a>analyzing |  Optional. A <code>bool</code> specifying whether to build for the analyzing phase.   |  <code>None</code> |

**RETURNS**

A `struct`.


<a id="xcode_schemes.launch_action"></a>

## xcode_schemes.launch_action

<pre>
xcode_schemes.launch_action(<a href="#xcode_schemes.launch_action-target">target</a>, <a href="#xcode_schemes.launch_action-args">args</a>, <a href="#xcode_schemes.launch_action-build_configuration">build_configuration</a>, <a href="#xcode_schemes.launch_action-diagnostics">diagnostics</a>, <a href="#xcode_schemes.launch_action-env">env</a>, <a href="#xcode_schemes.launch_action-working_directory">working_directory</a>)
</pre>

Constructs a launch action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.launch_action-target"></a>target |  A target label as a <code>string</code> value.   |  none |
| <a id="xcode_schemes.launch_action-args"></a>args |  Optional. A <code>list</code> of <code>string</code> arguments that should be passed to the target when executed.   |  <code>None</code> |
| <a id="xcode_schemes.launch_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action. If not set, then the configuration determined by <code>xcodeproj.default_xcode_configuration</code> will be used.   |  <code>None</code> |
| <a id="xcode_schemes.launch_action-diagnostics"></a>diagnostics |  Optional. A value returned by <code>xcode_schemes.diagnostics</code>.   |  <code>None</code> |
| <a id="xcode_schemes.launch_action-env"></a>env |  Optional. A <code>dict</code> of <code>string</code> values that will be set as environment variables when the target is executed.   |  <code>None</code> |
| <a id="xcode_schemes.launch_action-working_directory"></a>working_directory |  Optional. A <code>string</code> that will be set as the custom working directory in the Xcode scheme's launch action. Relative paths will be relative to the value of <code>target</code>'s <code>BUILT_PRODUCTS_DIR</code>, which is unique to it.   |  <code>None</code> |

**RETURNS**

A `struct` representing a launch action.


<a id="xcode_schemes.profile_action"></a>

## xcode_schemes.profile_action

<pre>
xcode_schemes.profile_action(<a href="#xcode_schemes.profile_action-target">target</a>, <a href="#xcode_schemes.profile_action-args">args</a>, <a href="#xcode_schemes.profile_action-build_configuration">build_configuration</a>, <a href="#xcode_schemes.profile_action-env">env</a>, <a href="#xcode_schemes.profile_action-working_directory">working_directory</a>)
</pre>

Constructs a profile action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.profile_action-target"></a>target |  A target label as a <code>string</code> value.   |  none |
| <a id="xcode_schemes.profile_action-args"></a>args |  Optional. A <code>list</code> of <code>string</code> arguments that should be passed to the target when executed. If both this and <code>env</code> are <code>None</code> (not just empty), then the launch action's arguments will be inherited.   |  <code>None</code> |
| <a id="xcode_schemes.profile_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action. If not set, then the configuration determined by <code>xcodeproj.default_xcode_configuration</code> will be used.   |  <code>None</code> |
| <a id="xcode_schemes.profile_action-env"></a>env |  Optional. A <code>dict</code> of <code>string</code> values that will be set as environment variables when the target is executed. If both this and <code>args</code> are <code>None</code> (not just empty), then the launch action's environment variables will be inherited.   |  <code>None</code> |
| <a id="xcode_schemes.profile_action-working_directory"></a>working_directory |  Optional. A <code>string</code> that will be set as the custom working directory in the Xcode scheme's launch action. Relative paths will be relative to the value of <code>target</code>'s <code>BUILT_PRODUCTS_DIR</code>, which is unique to it.   |  <code>None</code> |

**RETURNS**

A `struct` representing a profile action.


<a id="xcode_schemes.test_action"></a>

## xcode_schemes.test_action

<pre>
xcode_schemes.test_action(<a href="#xcode_schemes.test_action-targets">targets</a>, <a href="#xcode_schemes.test_action-args">args</a>, <a href="#xcode_schemes.test_action-build_configuration">build_configuration</a>, <a href="#xcode_schemes.test_action-diagnostics">diagnostics</a>, <a href="#xcode_schemes.test_action-env">env</a>,
                          <a href="#xcode_schemes.test_action-expand_variables_based_on">expand_variables_based_on</a>, <a href="#xcode_schemes.test_action-pre_actions">pre_actions</a>, <a href="#xcode_schemes.test_action-post_actions">post_actions</a>)
</pre>

Constructs a test action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.test_action-targets"></a>targets |  A <code>sequence</code> of target labels as <code>string</code> values.   |  none |
| <a id="xcode_schemes.test_action-args"></a>args |  Optional. A <code>list</code> of <code>string</code> arguments that should be passed to the target when executed. If both this and <code>env</code> are <code>None</code> (not just empty), then the launch action's arguments will be inherited.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action. If not set, then the configuration determined by <code>xcodeproj.default_xcode_configuration</code> will be used.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-diagnostics"></a>diagnostics |  Optional. A value returned by <code>xcode_schemes.diagnostics</code>.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-env"></a>env |  Optional. A <code>dict</code> of <code>string</code> values that will be set as environment variables when the target is executed. If both this and <code>args</code> are <code>None</code> (not just empty), then the launch action's environment variables will be inherited.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-expand_variables_based_on"></a>expand_variables_based_on |  Optional. One of the specified test target labels. If no value is provided, one of the test targets will be selected. If no expansion context is desired, use the <code>string</code> value <code>none</code>.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-pre_actions"></a>pre_actions |  Optional. A <code>sequence</code> of <code>struct</code> values as created by <code>xcode_schemes.pre_post_action</code>.   |  <code>[]</code> |
| <a id="xcode_schemes.test_action-post_actions"></a>post_actions |  Optional. A <code>sequence</code> of <code>struct</code> values as created by <code>xcode_schemes.pre_post_action</code>.   |  <code>[]</code> |

**RETURNS**

A `struct` representing a test action.


<a id="xcode_schemes.diagnostics"></a>

## xcode_schemes.diagnostics

<pre>
xcode_schemes.diagnostics(<a href="#xcode_schemes.diagnostics-sanitizers">sanitizers</a>)
</pre>

Constructs the scheme's diagnostics.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.diagnostics-sanitizers"></a>sanitizers |  Optional. A <code>struct</code> value as created by <code>xcode_schemes.sanitizers</code>.   |  <code>None</code> |

**RETURNS**

A `struct` representing scheme's diagnostics.


<a id="xcode_schemes.sanitizers"></a>

## xcode_schemes.sanitizers

<pre>
xcode_schemes.sanitizers(<a href="#xcode_schemes.sanitizers-address">address</a>, <a href="#xcode_schemes.sanitizers-thread">thread</a>, <a href="#xcode_schemes.sanitizers-undefined_behavior">undefined_behavior</a>)
</pre>

Constructs the scheme's sanitizers' default state. The state can also be modified in Xcode.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.sanitizers-address"></a>address |  Optional. A boolean value representing whether the address sanitizer should be enabled or not.   |  <code>False</code> |
| <a id="xcode_schemes.sanitizers-thread"></a>thread |  Optional. A boolean value representing whether the thread sanitizer should be enabled or not.   |  <code>False</code> |
| <a id="xcode_schemes.sanitizers-undefined_behavior"></a>undefined_behavior |  Optional. A boolean value representing whether the undefined behavior sanitizer should be enabled or not.   |  <code>False</code> |


<a id="xcode_schemes.pre_post_action"></a>

## xcode_schemes.pre_post_action

<pre>
xcode_schemes.pre_post_action(<a href="#xcode_schemes.pre_post_action-name">name</a>, <a href="#xcode_schemes.pre_post_action-script">script</a>, <a href="#xcode_schemes.pre_post_action-expand_variables_based_on">expand_variables_based_on</a>)
</pre>

Constructs a pre or post action for a step of the scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.pre_post_action-name"></a>name |  Title of the script.   |  <code>"Run Script"</code> |
| <a id="xcode_schemes.pre_post_action-script"></a>script |  The script text.   |  none |
| <a id="xcode_schemes.pre_post_action-expand_variables_based_on"></a>expand_variables_based_on |  Optional. The label of the target that environment variables will expand based on.   |  none |

**RETURNS**

A `struct` representing a scheme's step pre or post action.


# Xcode build settings

Rules that provide additional information to the [`xcodeproj`](#xcodeproj) rule,
so that it can properly determine values for various Xcode build settings.


<a id="xcode_provisioning_profile"></a>

## xcode_provisioning_profile

<pre>
xcode_provisioning_profile(<a href="#xcode_provisioning_profile-name">name</a>, <a href="#xcode_provisioning_profile-managed_by_xcode">managed_by_xcode</a>, <a href="#xcode_provisioning_profile-profile_name">profile_name</a>, <a href="#xcode_provisioning_profile-provisioning_profile">provisioning_profile</a>, <a href="#xcode_provisioning_profile-team_id">team_id</a>)
</pre>

This rule declares a target that you can pass to the `provisioning_profile`
attribute of rules that require it. It wraps another provisioning profile
target, either a `File` or a rule like rules_apple's
`local_provisioning_profile`, and allows specifying additional information to
adjust Xcode related build settings related to code signing.

If you are already using `local_provisioning_profile`, or another rule that
returns the `AppleProvisioningProfileInfo` provider, you don't need to use this
rule, unless you want to enable Xcode's "Automatic Code Signing" feature. If you
are using a `File`, then this rule is needed in order to set the
`DEVELOPER_TEAM` build setting via the `team_id` attribute.

**EXAMPLE**

```starlark
ios_application(
   ...
   provisioning_profile = ":xcode_profile",
   ...
)

xcode_provisioning_profile(
   name = "xcode_profile",
   managed_by_xcode = True,
   provisioning_profile = ":provisioning_profile",
)

local_provisioning_profile(
    name = "provisioning_profile",
    profile_name = "iOS Team Provisioning Profile: com.example.app",
    team_id = "A12B3CDEFG",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="xcode_provisioning_profile-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="xcode_provisioning_profile-managed_by_xcode"></a>managed_by_xcode |  Whether the provisioning profile is managed by Xcode. If <code>True</code>, "Automatic Code Signing" will be enabled in Xcode, and the profile name will be ignored. Xcode will add devices to profiles automatically via the currently logged in Apple Developer Account, and otherwise fully manage the profile. If <code>False</code>, "Manual Code Signing" will be enabled in Xcode, and the profile name will be used to determine which profile to use.<br><br>If <code>xcodeproj.build_mode != "xcode"</code>, then Xcode will still manage the profile when this is <code>True</code>, but otherwise won't use it to actually sign the binary. Instead Bazel will perform the code signing with the file set to <code>provisioning_profile</code>. Using rules_apple's <code>local_provisioning_profile</code> as the target set to <code>provisioning_profile</code> will then allow Bazel to code sign with the Xcode managed profile.   | Boolean | required |  |
| <a id="xcode_provisioning_profile-profile_name"></a>profile_name |  When <code>managed_by_xcode</code> is <code>False</code>, the <code>PROVISIONING_PROFILE_SPECIFIER</code> Xcode build setting will be set to this value. If this is <code>None</code> (the default), and <code>provisioning_profile</code> returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then <code>AppleProvisioningProfileInfo.profile_name</code> will be used instead.   | String | optional | <code>""</code> |
| <a id="xcode_provisioning_profile-provisioning_profile"></a>provisioning_profile |  The <code>File</code> that Bazel will use when code signing. If the target returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then it will provide default values for <code>profile_name</code> and <code>team_id</code>.<br><br>When <code>xcodeproj.build_mode = "xcode"</code>, the actual file isn't used directly by Xcode, but in order to satisfy Bazel constraints this can't be <code>None</code>.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="xcode_provisioning_profile-team_id"></a>team_id |  The <code>DEVELOPER_TEAM</code> Xcode build setting will be set to this value. If this is <code>None</code> (the default), and <code>provisioning_profile</code> returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then <code>AppleProvisioningProfileInfo.team_id</code> will be used instead.   | String | optional | <code>""</code> |


# Providers

[Providers](https://bazel.build/rules/lib/Provider) that are used throughout
the rules in this repository.

Most users will not need to use these providers to simply create Xcode projects,
but if you want to write your own custom rules that interact with these
rules, then you will use these providers to communicate between them.


<a id="XcodeProjAutomaticTargetProcessingInfo"></a>

## XcodeProjAutomaticTargetProcessingInfo

<pre>
XcodeProjAutomaticTargetProcessingInfo(<a href="#XcodeProjAutomaticTargetProcessingInfo-all_attrs">all_attrs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-alternate_icons">alternate_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-app_icons">app_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-args">args</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-bazel_build_mode_error">bazel_build_mode_error</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bundle_id">bundle_id</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-codesignopts">codesignopts</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files">collect_uncategorized_files</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-deps">deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-entitlements">entitlements</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-env">env</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists">exported_symbols_lists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-hdrs">hdrs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-implementation_deps">implementation_deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-infoplists">infoplists</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-launchdplists">launchdplists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-link_mnemonics">link_mnemonics</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs">non_arc_srcs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-pch">pch</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-provisioning_profile">provisioning_profile</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-should_generate_target">should_generate_target</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-srcs">srcs</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-target_type">target_type</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return a `XcodeProjInfo` provider instance instead.

**Warning:** This provider currently has an unstable API and may change in the
future. If you are using this provider, please let us know so we can prioritize
stabilizing it.


**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjAutomaticTargetProcessingInfo-all_attrs"></a>all_attrs |  -    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-alternate_icons"></a>alternate_icons |  An attribute name (or <code>None</code>) to collect the application alternate icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-app_icons"></a>app_icons |  An attribute name (or <code>None</code>) to collect the application icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-args"></a>args |  A <code>List</code> (or <code>None</code>) representing the command line arguments that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bazel_build_mode_error"></a>bazel_build_mode_error |  If <code>build_mode = "bazel"</code>, then if this is non-<code>None</code>, it will be raised as an error during analysis.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bundle_id"></a>bundle_id |  An attribute name (or <code>None</code>) to collect the bundle id string from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-codesignopts"></a>codesignopts |  An attribute name (or <code>None</code>) to collect the <code>codesignopts</code> <code>list</code> from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files"></a>collect_uncategorized_files |  Whether to collect files from uncategorized attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-deps"></a>deps |  A sequence of attribute names to collect <code>Target</code>s from for <code>deps</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-entitlements"></a>entitlements |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>entitlements</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-env"></a>env |  A <code>dict</code> representing the environment variables that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists"></a>exported_symbols_lists |  A sequence of attribute names to collect <code>File</code>s from for the <code>exported_symbols_lists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-hdrs"></a>hdrs |  A sequence of attribute names to collect <code>File</code>s from for <code>hdrs</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-implementation_deps"></a>implementation_deps |  A sequence of attribute names to collect <code>Target</code>s from for <code>implementation_deps</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-infoplists"></a>infoplists |  A sequence of attribute names to collect <code>File</code>s from for the <code>infoplists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-launchdplists"></a>launchdplists |  A sequence of attribute names to collect <code>File</code>s from for the <code>launchdplists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-link_mnemonics"></a>link_mnemonics |  A sequence of mnemonic (action) names to gather link parameters. The first action that matches any of the mnemonics is used.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs"></a>non_arc_srcs |  A sequence of attribute names to collect <code>File</code>s from for <code>non_arc_srcs</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-pch"></a>pch |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>pch</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-provisioning_profile"></a>provisioning_profile |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>provisioning_profile</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-should_generate_target"></a>should_generate_target |  Whether or an Xcode target should be generated for this target. Even if this value is <code>False</code>, setting values for the other attributes can cause inputs to be collected and shown in the Xcode project.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-srcs"></a>srcs |  A sequence of attribute names to collect <code>File</code>s from for <code>srcs</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-target_type"></a>target_type |  See <code>XcodeProjInfo.target_type</code>.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-xcode_targets"></a>xcode_targets |  A <code>dict</code> mapping attribute names to target type strings (i.e. "resource" or "compile"). Only Xcode targets from the specified attributes with the specified target type are allowed to propagate.    |


<a id="XcodeProjInfo"></a>

## XcodeProjInfo

<pre>
XcodeProjInfo(<a href="#XcodeProjInfo-args">args</a>, <a href="#XcodeProjInfo-compilation_providers">compilation_providers</a>, <a href="#XcodeProjInfo-dependencies">dependencies</a>, <a href="#XcodeProjInfo-envs">envs</a>, <a href="#XcodeProjInfo-extension_infoplists">extension_infoplists</a>, <a href="#XcodeProjInfo-hosted_targets">hosted_targets</a>,
              <a href="#XcodeProjInfo-inputs">inputs</a>, <a href="#XcodeProjInfo-is_top_level_target">is_top_level_target</a>, <a href="#XcodeProjInfo-label">label</a>, <a href="#XcodeProjInfo-labels">labels</a>, <a href="#XcodeProjInfo-lldb_context">lldb_context</a>,
              <a href="#XcodeProjInfo-mergable_xcode_library_targets">mergable_xcode_library_targets</a>, <a href="#XcodeProjInfo-potential_target_merges">potential_target_merges</a>, <a href="#XcodeProjInfo-outputs">outputs</a>, <a href="#XcodeProjInfo-replacement_labels">replacement_labels</a>,
              <a href="#XcodeProjInfo-resource_bundle_informations">resource_bundle_informations</a>, <a href="#XcodeProjInfo-rule_kind">rule_kind</a>, <a href="#XcodeProjInfo-search_paths">search_paths</a>, <a href="#XcodeProjInfo-target_type">target_type</a>,
              <a href="#XcodeProjInfo-transitive_dependencies">transitive_dependencies</a>, <a href="#XcodeProjInfo-xcode_required_targets">xcode_required_targets</a>, <a href="#XcodeProjInfo-xcode_target">xcode_target</a>, <a href="#XcodeProjInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides information needed to generate an Xcode project.

**Warning:** This provider currently has an unstable API and may change in the
future. If you are using this provider, please let us know so we can prioritize
stabilizing it.


**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjInfo-args"></a>args |  A <code>depset</code> of <code>struct</code>s with <code>id</code> and <code>arg</code> fields. The <code>id</code> field is the target id of the target and <code>arg</code> values for the target (if applicable).    |
| <a id="XcodeProjInfo-compilation_providers"></a>compilation_providers |  A value returned from <code>compilation_providers.collect_for_{non_,}top_level</code>.    |
| <a id="XcodeProjInfo-dependencies"></a>dependencies |  A <code>depset</code> of target ids (see the <code>target</code> <code>struct</code>) that this target directly depends on.    |
| <a id="XcodeProjInfo-envs"></a>envs |  A <code>depset</code> of <code>struct</code>s with <code>id</code> and <code>env</code> fields. The <code>id</code> field is the target id of the target and <code>env</code> values for the target (if applicable).    |
| <a id="XcodeProjInfo-extension_infoplists"></a>extension_infoplists |  A <code>depset</code> of <code>struct</code>s with 'id' and 'infoplist' fields. The 'id' field is the target id of the application extension target. The 'infoplist' field is a <code>File</code> for the Info.plist for the target.    |
| <a id="XcodeProjInfo-hosted_targets"></a>hosted_targets |  A <code>depset</code> of <code>struct</code>s with 'host' and 'hosted' fields. The 'host' field is the target id of the hosting target. The 'hosted' field is the target id of the hosted target.    |
| <a id="XcodeProjInfo-inputs"></a>inputs |  A value returned from <code>input_files.collect</code>, that contains the input files for this target. It also includes the two extra fields that collect all of the generated <code>Files</code> and all of the <code>Files</code> that should be added to the Xcode project, but are not associated with any targets.    |
| <a id="XcodeProjInfo-is_top_level_target"></a>is_top_level_target |  Whether this target is a top-level target. Top-level targets are targets that are valid to be listed in the <code>top_level_targets</code> attribute of <code>xcodeproj</code>. In particular, this means that they aren't library targets, which when specified in <code>top_level_targets</code> cause duplicate mis-configured targets to be added to the project.    |
| <a id="XcodeProjInfo-label"></a>label |  The <code>Label</code> of the target.    |
| <a id="XcodeProjInfo-labels"></a>labels |  A <code>depset</code> of <code>Labels</code> for the target and its transitive dependencies.    |
| <a id="XcodeProjInfo-lldb_context"></a>lldb_context |  A value returned from <code>lldb_context.collect</code>.    |
| <a id="XcodeProjInfo-mergable_xcode_library_targets"></a>mergable_xcode_library_targets |  A <code>List</code> of <code>struct</code>s with 'id' and 'product_path' fields. The 'id' field is the id of the target. The 'product_path' is the path to the target's product.    |
| <a id="XcodeProjInfo-potential_target_merges"></a>potential_target_merges |  A <code>depset</code> of <code>struct</code>s with 'src' and 'dest' fields. The 'src' field is the id of the target that can be merged into the target with the id of the 'dest' field.    |
| <a id="XcodeProjInfo-outputs"></a>outputs |  A value returned from <code>output_files.collect</code>, that contains information about the output files for this target and its transitive dependencies.    |
| <a id="XcodeProjInfo-replacement_labels"></a>replacement_labels |  A <code>depset</code> of <code>struct</code>s with <code>id</code> and <code>label</code> fields. The <code>id</code> field is the target id of the target that have its label (and name) be replaced with the label in the <code>label</code> field.    |
| <a id="XcodeProjInfo-resource_bundle_informations"></a>resource_bundle_informations |  A <code>depset</code> of <code>struct</code>s with information used to generate resource bundles, which couldn't be collected from <code>AppleResourceInfo</code> alone.    |
| <a id="XcodeProjInfo-rule_kind"></a>rule_kind |  The ctx.rule.kind of the target.    |
| <a id="XcodeProjInfo-search_paths"></a>search_paths |  A value returned from <code>_process_search_paths</code>, that contains the search paths needed by this target. These search paths should be added to the search paths of any target that depends on this target.    |
| <a id="XcodeProjInfo-target_type"></a>target_type |  A string that categorizes the type of the current target. This will be one of "compile", "resources", or <code>None</code>. Even if this target doesn't produce an Xcode target, it can still have a non-<code>None</code> value for this field.    |
| <a id="XcodeProjInfo-transitive_dependencies"></a>transitive_dependencies |  A <code>depset</code> of target ids (see the <code>target</code> <code>struct</code>) that this target transitively depends on.    |
| <a id="XcodeProjInfo-xcode_required_targets"></a>xcode_required_targets |  A <code>depset</code> of values returned from <code>xcode_targets.make</code> for targets that need to be in projects that have <code>build_mode = "xcode"</code>. This means that they can't be unfocused in BwX mode, and if requested it will be ignored.    |
| <a id="XcodeProjInfo-xcode_target"></a>xcode_target |  An optional value returned from <code>xcode_targets.make</code>.    |
| <a id="XcodeProjInfo-xcode_targets"></a>xcode_targets |  A <code>depset</code> of values returned from <code>xcode_targets.make</code>, which potentially will become targets in the Xcode project.    |



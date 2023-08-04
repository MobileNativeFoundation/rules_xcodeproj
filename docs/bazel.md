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
| <a id="xcodeproj-adjust_schemes_for_swiftui_previews"></a>adjust_schemes_for_swiftui_previews |  Optional. Whether to adjust schemes in BwB mode to explicitly include transitive dependencies that are able to run SwiftUI Previews.<br><br>For example, this changes a scheme for an single application target to also include any app clip, app extension, framework, or watchOS app dependencies.   |  `True` |
| <a id="xcodeproj-archived_bundles_allowed"></a>archived_bundles_allowed |  This argument is deprecated and is now a no-op. It will be removed in a future release. Adjust the setting of `--define=apple.experimental.tree_artifact_outputs` on `build:rules_xcodeproj` in your `.bazelrc` or `xcodeproj.bazelrc` file.   |  `None` |
| <a id="xcodeproj-associated_extra_files"></a>associated_extra_files |  Optional. A `dict` of files to be added to the project.<br><br>The key is a `string` value representing the label of the target the files should be associated with, and the value is a `list` of `File`s. These files won't be added to the project if the target is unfocused.   |  `{}` |
| <a id="xcodeproj-bazel_path"></a>bazel_path |  Optional. The path the `bazel` binary or wrapper script.<br><br>If the path is relative it will be resolved using the `PATH` environment variable that is set when generating the project. If you want to specify a path to a workspace-relative binary, you must prepend the path with `./` (e.g. `"./bazelw"`).   |  `"bazel"` |
| <a id="xcodeproj-bazel_env"></a>bazel_env |  Optional. A `dict` of environment variables to set when invoking `bazel_path`.<br><br>This is useful for setting environment variables that are required for Bazel actions to run successfully, such as `JAVA_HOME` or `ANDROID_HOME`. It's also useful if `bazel_path` itself (if it's a wrapper) needs certain environment variables.<br><br>The keys are the names of the environment variables, and the values are the values of the environment variables. If a value is `None`, the environment variable will be picked up from the current environment.<br><br>If project generation succeeds, but building inside of Xcode fails because of missing environment variables, you probably have to set them here.<br><br>If `PATH` is not specified, it will default to `/bin:/usr/bin`, so you don't have to specify it unless you want to user a different value.   |  `{"PATH": "/bin:/usr/bin"}` |
| <a id="xcodeproj-build_mode"></a>build_mode |  Optional. The build mode the generated project should use.<br><br>If this is set to `"xcode"`, the project will use the Xcode build system to build targets. Generated files and unfocused targets (see the `focused_targets` and `unfocused_targets` arguments) will be built with Bazel.<br><br>If this is set to `"bazel"`, the project will use Bazel to build targets, inside of Xcode. The Xcode build system still unavoidably orchestrates some things at a high level.   |  `"bazel"` |
| <a id="xcodeproj-config"></a>config |  Optional. The Bazel config to use when generating the project or invoking `bazel` inside of Xcode.<br><br>This is the basename of multiple configs. For example, if this is set to `"projectx_xcodeproj"`, then the following configs will be available for you to adjust in your `.bazelrc` file:<br><br><ul> <li>`projectx_xcodeproj`</li> <li>`projectx_xcodeproj_generator`</li> <li>`projectx_xcodeproj_indexbuild`</li> <li>`projectx_xcodeproj_swiftuipreviews`</li> </ul><br><br>See the [usage guide](usage.md#bazel-configs) for more information on adjusting Bazel configs.   |  `"rules_xcodeproj"` |
| <a id="xcodeproj-default_xcode_configuration"></a>default_xcode_configuration |  Optional. The name of the the Xcode configuration to use when building, if not overridden by custom schemes.<br><br>If not set, the first Xcode configuration alphabetically will be used. Use [`xcode_configurations`](#xcodeproj-xcode_configurations) to adjust Xcode configurations.   |  `None` |
| <a id="xcodeproj-extra_files"></a>extra_files |  Optional. A `list` of extra `File`s to be added to the project.   |  `[]` |
| <a id="xcodeproj-fail_for_invalid_extra_files_targets"></a>fail_for_invalid_extra_files_targets |  Optional. Determines wether, when processing targets, invalid extra files without labels will fail or just emit a warning.   |  `True` |
| <a id="xcodeproj-focused_targets"></a>focused_targets |  Optional. A `list` of target labels as `string` values.<br><br>If specified, only these targets will be included in the generated project; all other targets will be excluded, as if they were listed explicitly in the `unfocused_targets` argument. The labels must match transitive dependencies of the targets specified in the `top_level_targets` argument.   |  `[]` |
| <a id="xcodeproj-install_directory"></a>install_directory |  Optional. The directory where the generated project will be written to.<br><br>The path is relative to the workspace root.<br><br>Defaults to the directory that the `xcodeproj` target is declared in (e.g. if the `xcodeproj` target is declared in `//foo/bar:BUILD` then the default value is `"foo/bar"`). Use `""` to have the project generated in the workspace root.   |  `None` |
| <a id="xcodeproj-ios_device_cpus"></a>ios_device_cpus |  Optional. The value to use for `--ios_multi_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't iOS targets.   |  `"arm64"` |
| <a id="xcodeproj-ios_simulator_cpus"></a>ios_simulator_cpus |  Optional. The value to use for `--ios_multi_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't iOS targets.   |  `None` |
| <a id="xcodeproj-minimum_xcode_version"></a>minimum_xcode_version |  Optional. The minimum Xcode version that the generated project supports.<br><br>Newer Xcode versions can support newer features, so setting this to the highest value you can will enable the most features. The value is the dot separated version number (e.g. "13.4.1", "14", "14.1").<br><br>Defaults to whichever version of Xcode that Bazel uses during project generation.   |  `None` |
| <a id="xcodeproj-post_build"></a>post_build |  The text of a script that will be run after the build.<br><br>For example: `./post-build.sh`, `"$SRCROOT/post-build.sh"`.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure `$ACTION == build`.   |  `None` |
| <a id="xcodeproj-pre_build"></a>pre_build |  The text of a script that will be run before the build.<br><br>For example: `./pre-build.sh`, `"$SRCROOT/pre-build.sh"`.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure `$ACTION == build`.   |  `None` |
| <a id="xcodeproj-project_name"></a>project_name |  Optional. The name to use for the `.xcodeproj` file.<br><br>If not specified, the value of the `name` argument is used.   |  `None` |
| <a id="xcodeproj-project_options"></a>project_options |  Optional. A value returned by `project_options`.   |  `None` |
| <a id="xcodeproj-scheme_autogeneration_mode"></a>scheme_autogeneration_mode |  Optional. Specifies how Xcode schemes are automatically generated:<br><br><ul> <li>   `auto`: If no custom schemes are specified, via `schemes`, an   Xcode scheme will be created for every buildable target. If custom   schemes are provided, no autogenerated schemes will be created. </li> <li>   `none`: No schemes are automatically generated. </li> <li>   `all`: A scheme is generated for every buildable target even if   custom schemes are provided. </li> </ul>   |  `"auto"` |
| <a id="xcodeproj-schemes"></a>schemes |  Optional. A `list` of values returned by `xcode_schemes.scheme`.<br><br>Target labels listed in the schemes need to be from the transitive dependencies of the targets specified in the `top_level_targets` argument. This and the `scheme_autogeneration_mode` argument together customize how schemes for those targets are generated.   |  `[]` |
| <a id="xcodeproj-temporary_directory"></a>temporary_directory |  This argument is deprecated and is now a no-op. It will be removed in a future release.   |  `None` |
| <a id="xcodeproj-top_level_targets"></a>top_level_targets |  A `list` of a list of top-level targets.<br><br>Each target can be specified as either a `Label` (or label-like `string`), a value returned by `top_level_target`, or a value returned by `top_level_targets`.   |  none |
| <a id="xcodeproj-tvos_device_cpus"></a>tvos_device_cpus |  Optional. The value to use for `--tvos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't tvOS targets.   |  `"arm64"` |
| <a id="xcodeproj-tvos_simulator_cpus"></a>tvos_simulator_cpus |  Optional. The value to use for `--tvos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't tvOS targets.   |  `None` |
| <a id="xcodeproj-unfocused_targets"></a>unfocused_targets |  Optional. A `list` of target labels as `string` values.<br><br>Any targets in the transitive dependencies of the targets specified in the `top_level_targets` argument with a matching label will be excluded from the generated project. This overrides any targets specified in the `focused_targets` argument.   |  `[]` |
| <a id="xcodeproj-watchos_device_cpus"></a>watchos_device_cpus |  Optional. The value to use for `--watchos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't watchOS targets.   |  `"arm64_32"` |
| <a id="xcodeproj-watchos_simulator_cpus"></a>watchos_simulator_cpus |  Optional. The value to use for `--watchos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't watchOS targets.   |  `None` |
| <a id="xcodeproj-xcode_configurations"></a>xcode_configurations |  Optional. A `dict` mapping Xcode configuration names to transition settings dictionaries. For example:<br><br><pre><code class="language-starlark">{&#10;    "Dev": {&#10;        "//command_line_option:compilation_mode": "dbg",&#10;    },&#10;    "AppStore": {&#10;        "//command_line_option:compilation_mode": "opt",&#10;    },&#10;}</code></pre><br><br>would create the "Dev" and "AppStore" configurations, setting `--compilation_mode` to `dbg` and `opt` respectively.<br><br>Refer to the [bazel documentation](https://bazel.build/extending/config#defining) on how to define the transition settings dictionary.   |  `{"Debug": {}}` |
| <a id="xcodeproj-kwargs"></a>kwargs |  Additional arguments to pass to the underlying `xcodeproj` rule specified by `xcodeproj_rule`.   |  none |




<a id="top_level_target"></a>

## top_level_target

<pre>
top_level_target(<a href="#top_level_target-label">label</a>, <a href="#top_level_target-target_environments">target_environments</a>)
</pre>

Constructs a top-level target for use in `xcodeproj.top_level_targets`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="top_level_target-label"></a>label |  A `Label` or label-like string for the target.   |  none |
| <a id="top_level_target-target_environments"></a>target_environments |  Optional. A `list` of target environment strings (see `@build_bazel_apple_support//constraints:target_environment`; `"catalyst"` is not currently supported). The target will be configured for each environment.<br><br>If multiple environments are specified, then a single combined Xcode target will be created if possible. If the configured targets are the same for each environment (e.g. macOS for `["device", "simulator"]`), they will appear as separate but similar Xcode targets. If no environments are specified, the `"simulator"` environment will be used.   |  `["simulator"]` |

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
| <a id="top_level_targets-labels"></a>labels |  A `list` of `Label` or label-like string for the targets.   |  none |
| <a id="top_level_targets-target_environments"></a>target_environments |  Optional. See [`top_level_target.target_environments`](#top_level_target-target_environments).   |  `["simulator"]` |

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
| <a id="project_options-development_region"></a>development_region |  Optional. The development region for the project.   |  `"en"` |
| <a id="project_options-indent_width"></a>indent_width |  Optional. The number of spaces to use for indentation.   |  `None` |
| <a id="project_options-organization_name"></a>organization_name |  Optional. Populates the `ORGANIZATIONNAME` attribute for the project.   |  `None` |
| <a id="project_options-tab_width"></a>tab_width |  Optional. The number of spaces to use for tabs.   |  `None` |
| <a id="project_options-uses_tabs"></a>uses_tabs |  Optional. Whether to use tabs for indentation.   |  `None` |

**RETURNS**

A `dict` containing fields for the provided arguments.


# Custom Xcode schemes

To use these functions, `load` the `xcode_schemes` module from
`xcodeproj/defs.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_schemes")
```

<a id="xcode_schemes.build_action"></a>

## xcode_schemes.build_action

<pre>
xcode_schemes.build_action(<a href="#xcode_schemes.build_action-targets">targets</a>, <a href="#xcode_schemes.build_action-pre_actions">pre_actions</a>, <a href="#xcode_schemes.build_action-post_actions">post_actions</a>)
</pre>

Constructs a build action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_action-targets"></a>targets |  A `sequence` of elements that are either `struct` values as created by `xcode_schemes.build_target`, or a target label as a `string` value.   |  none |
| <a id="xcode_schemes.build_action-pre_actions"></a>pre_actions |  A `sequence` of `struct` values as created by `xcode_schemes.pre_action`.   |  `[]` |
| <a id="xcode_schemes.build_action-post_actions"></a>post_actions |  A `sequence` of `struct` values as created by `xcode_schemes.post_action`.   |  `[]` |

**RETURNS**

A `struct` representing a build action.


<a id="xcode_schemes.build_for"></a>

## xcode_schemes.build_for

<pre>
xcode_schemes.build_for(<a href="#xcode_schemes.build_for-running">running</a>, <a href="#xcode_schemes.build_for-testing">testing</a>, <a href="#xcode_schemes.build_for-profiling">profiling</a>, <a href="#xcode_schemes.build_for-archiving">archiving</a>, <a href="#xcode_schemes.build_for-analyzing">analyzing</a>)
</pre>

Construct a `struct` representing the settings that dictate when Xcode     will build a target.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_for-running"></a>running |  Optional. A `bool` specifying whether to build for the running phase.   |  `None` |
| <a id="xcode_schemes.build_for-testing"></a>testing |  Optional. A `bool` specifying whether to build for the testing phase.   |  `None` |
| <a id="xcode_schemes.build_for-profiling"></a>profiling |  Optional. A `bool` specifying whether to build for the profiling phase.   |  `None` |
| <a id="xcode_schemes.build_for-archiving"></a>archiving |  Optional. A `bool` specifying whether to build for the archiving phase.   |  `None` |
| <a id="xcode_schemes.build_for-analyzing"></a>analyzing |  Optional. A `bool` specifying whether to build for the analyzing phase.   |  `None` |

**RETURNS**

A `struct`.


<a id="xcode_schemes.build_target"></a>

## xcode_schemes.build_target

<pre>
xcode_schemes.build_target(<a href="#xcode_schemes.build_target-label">label</a>, <a href="#xcode_schemes.build_target-build_for">build_for</a>)
</pre>

Constructs a build target for an Xcode scheme's build action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_target-label"></a>label |  A target label as a `string` value.   |  none |
| <a id="xcode_schemes.build_target-build_for"></a>build_for |  Optional. The settings that dictate when Xcode will build the target. It is a value returned by `xcode_schemes.build_for`.   |  `None` |

**RETURNS**

A `struct` representing a build target.


<a id="xcode_schemes.diagnostics"></a>

## xcode_schemes.diagnostics

<pre>
xcode_schemes.diagnostics(<a href="#xcode_schemes.diagnostics-sanitizers">sanitizers</a>)
</pre>

Constructs the scheme's diagnostics.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.diagnostics-sanitizers"></a>sanitizers |  Optional. A `struct` value as created by `xcode_schemes.sanitizers`.   |  `None` |

**RETURNS**

A `struct` representing scheme's diagnostics.


<a id="xcode_schemes.launch_action"></a>

## xcode_schemes.launch_action

<pre>
xcode_schemes.launch_action(<a href="#xcode_schemes.launch_action-target">target</a>, <a href="#xcode_schemes.launch_action-args">args</a>, <a href="#xcode_schemes.launch_action-build_configuration">build_configuration</a>, <a href="#xcode_schemes.launch_action-diagnostics">diagnostics</a>, <a href="#xcode_schemes.launch_action-env">env</a>, <a href="#xcode_schemes.launch_action-working_directory">working_directory</a>)
</pre>

Constructs a launch action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.launch_action-target"></a>target |  A target label as a `string` value.   |  none |
| <a id="xcode_schemes.launch_action-args"></a>args |  Optional. A `list` of `string` arguments that should be passed to the target when executed.   |  `None` |
| <a id="xcode_schemes.launch_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action.<br><br>If not set, then the configuration determined by `xcodeproj.default_xcode_configuration` will be used.   |  `None` |
| <a id="xcode_schemes.launch_action-diagnostics"></a>diagnostics |  Optional. A value returned by `xcode_schemes.diagnostics`.   |  `None` |
| <a id="xcode_schemes.launch_action-env"></a>env |  Optional. A `dict` of `string` values that will be set as environment variables when the target is executed.   |  `None` |
| <a id="xcode_schemes.launch_action-working_directory"></a>working_directory |  Optional. A `string` that will be set as the custom working directory in the Xcode scheme's launch action. Relative paths will be relative to the value of `target`'s `BUILT_PRODUCTS_DIR`, which is unique to it.   |  `None` |

**RETURNS**

A `struct` representing a launch action.


<a id="xcode_schemes.pre_post_action"></a>

## xcode_schemes.pre_post_action

<pre>
xcode_schemes.pre_post_action(<a href="#xcode_schemes.pre_post_action-name">name</a>, <a href="#xcode_schemes.pre_post_action-script">script</a>, <a href="#xcode_schemes.pre_post_action-expand_variables_based_on">expand_variables_based_on</a>)
</pre>

Constructs a pre or post action for a step of the scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.pre_post_action-name"></a>name |  Title of the script.   |  `"Run Script"` |
| <a id="xcode_schemes.pre_post_action-script"></a>script |  The script text.   |  none |
| <a id="xcode_schemes.pre_post_action-expand_variables_based_on"></a>expand_variables_based_on |  Optional. The label of the target that environment variables will expand based on.   |  none |

**RETURNS**

A `struct` representing a scheme's step pre or post action.


<a id="xcode_schemes.profile_action"></a>

## xcode_schemes.profile_action

<pre>
xcode_schemes.profile_action(<a href="#xcode_schemes.profile_action-target">target</a>, <a href="#xcode_schemes.profile_action-args">args</a>, <a href="#xcode_schemes.profile_action-build_configuration">build_configuration</a>, <a href="#xcode_schemes.profile_action-env">env</a>, <a href="#xcode_schemes.profile_action-working_directory">working_directory</a>)
</pre>

Constructs a profile action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.profile_action-target"></a>target |  A target label as a `string` value.   |  none |
| <a id="xcode_schemes.profile_action-args"></a>args |  Optional. A `list` of `string` arguments that should be passed to the target when executed.<br><br>If both this and `env` are `None` (not just empty), then the launch action's arguments will be inherited.   |  `None` |
| <a id="xcode_schemes.profile_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action.<br><br>If not set, then the configuration determined by `xcodeproj.default_xcode_configuration` will be used.   |  `None` |
| <a id="xcode_schemes.profile_action-env"></a>env |  Optional. A `dict` of `string` values that will be set as environment variables when the target is executed.<br><br>If both this and `args` are `None` (not just empty), then the launch action's environment variables will be inherited.   |  `None` |
| <a id="xcode_schemes.profile_action-working_directory"></a>working_directory |  Optional. A `string` that will be set as the custom working directory in the Xcode scheme's launch action.<br><br>Relative paths will be relative to the value of `target`'s `BUILT_PRODUCTS_DIR`, which is unique to it.   |  `None` |

**RETURNS**

A `struct` representing a profile action.


<a id="xcode_schemes.sanitizers"></a>

## xcode_schemes.sanitizers

<pre>
xcode_schemes.sanitizers(<a href="#xcode_schemes.sanitizers-address">address</a>, <a href="#xcode_schemes.sanitizers-thread">thread</a>, <a href="#xcode_schemes.sanitizers-undefined_behavior">undefined_behavior</a>)
</pre>

Constructs the scheme's sanitizers' default state. The state can also be modified in Xcode.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.sanitizers-address"></a>address |  Optional. A boolean value representing whether the address sanitizer should be enabled or not.   |  `False` |
| <a id="xcode_schemes.sanitizers-thread"></a>thread |  Optional. A boolean value representing whether the thread sanitizer should be enabled or not.   |  `False` |
| <a id="xcode_schemes.sanitizers-undefined_behavior"></a>undefined_behavior |  Optional. A boolean value representing whether the undefined behavior sanitizer should be enabled or not.   |  `False` |


<a id="xcode_schemes.scheme"></a>

## xcode_schemes.scheme

<pre>
xcode_schemes.scheme(<a href="#xcode_schemes.scheme-name">name</a>, <a href="#xcode_schemes.scheme-build_action">build_action</a>, <a href="#xcode_schemes.scheme-launch_action">launch_action</a>, <a href="#xcode_schemes.scheme-profile_action">profile_action</a>, <a href="#xcode_schemes.scheme-test_action">test_action</a>)
</pre>

Returns a `struct` representing an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.scheme-name"></a>name |  The user-visible name for the scheme as a `string`.   |  none |
| <a id="xcode_schemes.scheme-build_action"></a>build_action |  Optional. A value returned by `xcode_schemes.build_action`.   |  `None` |
| <a id="xcode_schemes.scheme-launch_action"></a>launch_action |  Optional. A value returned by `xcode_schemes.launch_action`.   |  `None` |
| <a id="xcode_schemes.scheme-profile_action"></a>profile_action |  Optional. A value returned by `xcode_schemes.profile_action`.   |  `None` |
| <a id="xcode_schemes.scheme-test_action"></a>test_action |  Optional. A value returned by `xcode_schemes.test_action`.   |  `None` |

**RETURNS**

A `struct` representing an Xcode scheme.


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
| <a id="xcode_schemes.test_action-targets"></a>targets |  A `sequence` of target labels as `string` values.   |  none |
| <a id="xcode_schemes.test_action-args"></a>args |  Optional. A `list` of `string` arguments that should be passed to the target when executed.<br><br>If both this and `env` are `None` (not just empty), then the launch action's arguments will be inherited.   |  `None` |
| <a id="xcode_schemes.test_action-build_configuration"></a>build_configuration |  Optional. The name of the Xcode configuration to use for this action.<br><br>If not set, then the configuration determined by `xcodeproj.default_xcode_configuration` will be used.   |  `None` |
| <a id="xcode_schemes.test_action-diagnostics"></a>diagnostics |  Optional. A value returned by `xcode_schemes.diagnostics`.   |  `None` |
| <a id="xcode_schemes.test_action-env"></a>env |  Optional. A `dict` of `string` values that will be set as environment variables when the target is executed.<br><br>If both this and `args` are `None` (not just empty), then the launch action's environment variables will be inherited.   |  `None` |
| <a id="xcode_schemes.test_action-expand_variables_based_on"></a>expand_variables_based_on |  Optional. One of the specified test target labels.<br><br>If no value is provided, one of the test targets will be selected. If no expansion context is desired, use the `string` value `none`.   |  `None` |
| <a id="xcode_schemes.test_action-pre_actions"></a>pre_actions |  Optional. A `sequence` of `struct` values as created by `xcode_schemes.pre_post_action`.   |  `[]` |
| <a id="xcode_schemes.test_action-post_actions"></a>post_actions |  Optional. A `sequence` of `struct` values as created by `xcode_schemes.pre_post_action`.   |  `[]` |

**RETURNS**

A `struct` representing a test action.


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
| <a id="xcode_provisioning_profile-managed_by_xcode"></a>managed_by_xcode |  Whether the provisioning profile is managed by Xcode. If `True`, "Automatic Code Signing" will be enabled in Xcode, and the profile name will be ignored. Xcode will add devices to profiles automatically via the currently logged in Apple Developer Account, and otherwise fully manage the profile. If `False`, "Manual Code Signing" will be enabled in Xcode, and the profile name will be used to determine which profile to use.<br><br>If `xcodeproj.build_mode != "xcode"`, then Xcode will still manage the profile when this is `True`, but otherwise won't use it to actually sign the binary. Instead Bazel will perform the code signing with the file set to `provisioning_profile`. Using rules_apple's `local_provisioning_profile` as the target set to `provisioning_profile` will then allow Bazel to code sign with the Xcode managed profile.   | Boolean | required |  |
| <a id="xcode_provisioning_profile-profile_name"></a>profile_name |  When `managed_by_xcode` is `False`, the `PROVISIONING_PROFILE_SPECIFIER` Xcode build setting will be set to this value. If this is `None` (the default), and `provisioning_profile` returns the `AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does), then `AppleProvisioningProfileInfo.profile_name` will be used instead.   | String | optional |  `""`  |
| <a id="xcode_provisioning_profile-provisioning_profile"></a>provisioning_profile |  The `File` that Bazel will use when code signing. If the target returns the `AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does), then it will provide default values for `profile_name` and `team_id`.<br><br>When `xcodeproj.build_mode = "xcode"`, the actual file isn't used directly by Xcode, but in order to satisfy Bazel constraints this can't be `None`.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="xcode_provisioning_profile-team_id"></a>team_id |  The `DEVELOPER_TEAM` Xcode build setting will be set to this value. If this is `None` (the default), and `provisioning_profile` returns the `AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does), then `AppleProvisioningProfileInfo.team_id` will be used instead.   | String | optional |  `""`  |


# Providers

[Providers](https://bazel.build/rules/lib/Provider) that are used throughout
the rules in this repository.

Most users will not need to use these providers to simply create Xcode projects,
but if you want to write your own custom rules that interact with these
rules, then you will use these providers to communicate between them.

<a id="XcodeProjAutomaticTargetProcessingInfo"></a>

## XcodeProjAutomaticTargetProcessingInfo

<pre>
XcodeProjAutomaticTargetProcessingInfo(<a href="#XcodeProjAutomaticTargetProcessingInfo-alternate_icons">alternate_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-app_icons">app_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-args">args</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bundle_id">bundle_id</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-codesignopts">codesignopts</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files">collect_uncategorized_files</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-deps">deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-entitlements">entitlements</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-env">env</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists">exported_symbols_lists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-hdrs">hdrs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-implementation_deps">implementation_deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-infoplists">infoplists</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-launchdplists">launchdplists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-link_mnemonics">link_mnemonics</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs">non_arc_srcs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-pch">pch</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-provisioning_profile">provisioning_profile</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-should_generate_target">should_generate_target</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-srcs">srcs</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-target_type">target_type</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return an `XcodeProjInfo` provider instance instead.

> **Warning**
>
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjAutomaticTargetProcessingInfo-alternate_icons"></a>alternate_icons |  An attribute name (or `None`) to collect the application alternate icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-app_icons"></a>app_icons |  An attribute name (or `None`) to collect the application icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-args"></a>args |  A `List` (or `None`) representing the command line arguments that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bundle_id"></a>bundle_id |  An attribute name (or `None`) to collect the bundle id string from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-codesignopts"></a>codesignopts |  An attribute name (or `None`) to collect the `codesignopts` `list` from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files"></a>collect_uncategorized_files |  Whether to collect files from uncategorized attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-deps"></a>deps |  A sequence of attribute names to collect `Target`s from for `deps`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-entitlements"></a>entitlements |  An attribute name (or `None`) to collect `File`s from for the `entitlements`-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-env"></a>env |  A `dict` representing the environment variables that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists"></a>exported_symbols_lists |  A sequence of attribute names to collect `File`s from for the `exported_symbols_lists`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-hdrs"></a>hdrs |  A sequence of attribute names to collect `File`s from for `hdrs`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-implementation_deps"></a>implementation_deps |  A sequence of attribute names to collect `Target`s from for `implementation_deps`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-infoplists"></a>infoplists |  A sequence of attribute names to collect `File`s from for the `infoplists`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-launchdplists"></a>launchdplists |  A sequence of attribute names to collect `File`s from for the `launchdplists`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-link_mnemonics"></a>link_mnemonics |  A sequence of mnemonic (action) names to gather link parameters. The first action that matches any of the mnemonics is used.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs"></a>non_arc_srcs |  A sequence of attribute names to collect `File`s from for `non_arc_srcs`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-pch"></a>pch |  An attribute name (or `None`) to collect `File`s from for the `pch`-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-provisioning_profile"></a>provisioning_profile |  An attribute name (or `None`) to collect `File`s from for the `provisioning_profile`-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-should_generate_target"></a>should_generate_target |  Whether or an Xcode target should be generated for this target. Even if this value is `False`, setting values for the other attributes can cause inputs to be collected and shown in the Xcode project.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-srcs"></a>srcs |  A sequence of attribute names to collect `File`s from for `srcs`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-target_type"></a>target_type |  See `XcodeProjInfo.target_type`.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-xcode_targets"></a>xcode_targets |  A `dict` mapping attribute names to target type strings (i.e. "resource" or "compile"). Only Xcode targets from the specified attributes with the specified target type are allowed to propagate.    |


<a id="XcodeProjInfo"></a>

## XcodeProjInfo

<pre>
XcodeProjInfo(<a href="#XcodeProjInfo-args">args</a>, <a href="#XcodeProjInfo-compilation_providers">compilation_providers</a>, <a href="#XcodeProjInfo-dependencies">dependencies</a>, <a href="#XcodeProjInfo-envs">envs</a>, <a href="#XcodeProjInfo-extension_infoplists">extension_infoplists</a>, <a href="#XcodeProjInfo-hosted_targets">hosted_targets</a>,
              <a href="#XcodeProjInfo-inputs">inputs</a>, <a href="#XcodeProjInfo-label">label</a>, <a href="#XcodeProjInfo-labels">labels</a>, <a href="#XcodeProjInfo-lldb_context">lldb_context</a>, <a href="#XcodeProjInfo-mergable_xcode_library_targets">mergable_xcode_library_targets</a>,
              <a href="#XcodeProjInfo-potential_target_merges">potential_target_merges</a>, <a href="#XcodeProjInfo-outputs">outputs</a>, <a href="#XcodeProjInfo-replacement_labels">replacement_labels</a>, <a href="#XcodeProjInfo-resource_bundle_informations">resource_bundle_informations</a>,
              <a href="#XcodeProjInfo-non_top_level_rule_kind">non_top_level_rule_kind</a>, <a href="#XcodeProjInfo-target_type">target_type</a>, <a href="#XcodeProjInfo-transitive_dependencies">transitive_dependencies</a>, <a href="#XcodeProjInfo-xcode_required_targets">xcode_required_targets</a>,
              <a href="#XcodeProjInfo-xcode_target">xcode_target</a>, <a href="#XcodeProjInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides information needed to generate an Xcode project.

> **Warning**
>
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjInfo-args"></a>args |  A `depset` of `struct`s with `id` and `arg` fields. The `id` field is the target id of the target and `arg` values for the target (if applicable).    |
| <a id="XcodeProjInfo-compilation_providers"></a>compilation_providers |  A value returned from `compilation_providers.collect_for_{non_,}top_level`.    |
| <a id="XcodeProjInfo-dependencies"></a>dependencies |  A `depset` of target ids (see `xcode_target.id`) that this target directly depends on.    |
| <a id="XcodeProjInfo-envs"></a>envs |  A `depset` of `struct`s with `id` and `env` fields. The `id` field is the target id of the target and `env` values for the target (if applicable).    |
| <a id="XcodeProjInfo-extension_infoplists"></a>extension_infoplists |  A `depset` of `struct`s with 'id' and 'infoplist' fields. The 'id' field is the target id of the application extension target. The 'infoplist' field is a `File` for the Info.plist for the target.    |
| <a id="XcodeProjInfo-hosted_targets"></a>hosted_targets |  A `depset` of `struct`s with 'host' and 'hosted' fields. The 'host' field is the target id of the hosting target. The 'hosted' field is the target id of the hosted target.    |
| <a id="XcodeProjInfo-inputs"></a>inputs |  A value returned from `input_files.collect`, that contains the input files for this target. It also includes the two extra fields that collect all of the generated `Files` and all of the `Files` that should be added to the Xcode project, but are not associated with any targets.    |
| <a id="XcodeProjInfo-label"></a>label |  The `Label` of the target.    |
| <a id="XcodeProjInfo-labels"></a>labels |  A `depset` of `Labels` for the target and its transitive dependencies.    |
| <a id="XcodeProjInfo-lldb_context"></a>lldb_context |  A value returned from `lldb_context.collect`.    |
| <a id="XcodeProjInfo-mergable_xcode_library_targets"></a>mergable_xcode_library_targets |  A `List` of `struct`s with 'id' and 'product_path' fields. The 'id' field is the id of the target. The 'product_path' is the path to the target's product.    |
| <a id="XcodeProjInfo-potential_target_merges"></a>potential_target_merges |  A `depset` of `struct`s with 'src' and 'dest' fields. The 'src' field is the id of the target that can be merged into the target with the id of the 'dest' field.    |
| <a id="XcodeProjInfo-outputs"></a>outputs |  A value returned from `output_files.collect`, that contains information about the output files for this target and its transitive dependencies.    |
| <a id="XcodeProjInfo-replacement_labels"></a>replacement_labels |  A `depset` of `struct`s with `id` and `label` fields. The `id` field is the target id of the target that have its label (and name) be replaced with the label in the `label` field.    |
| <a id="XcodeProjInfo-resource_bundle_informations"></a>resource_bundle_informations |  A `depset` of `struct`s with information used to generate resource bundles, which couldn't be collected from `AppleResourceInfo` alone.    |
| <a id="XcodeProjInfo-non_top_level_rule_kind"></a>non_top_level_rule_kind |  If this target is not a top-level target, this is the value from `ctx.rule.kind`, otherwise it is `None`. Top-level targets are targets that are valid to be listed in the `top_level_targets` attribute of `xcodeproj`. In particular, this means that they aren't library targets, which when specified in `top_level_targets` cause duplicate mis-configured targets to be added to the project.    |
| <a id="XcodeProjInfo-target_type"></a>target_type |  A string that categorizes the type of the current target. This will be one of "compile", "resources", or `None`. Even if this target doesn't produce an Xcode target, it can still have a non-`None` value for this field.    |
| <a id="XcodeProjInfo-transitive_dependencies"></a>transitive_dependencies |  A `depset` of target ids (see `xcode_target.id`) that this target transitively depends on.    |
| <a id="XcodeProjInfo-xcode_required_targets"></a>xcode_required_targets |  A `depset` of values returned from `xcode_targets.make` for targets that need to be in projects that have `build_mode = "xcode"`. This means that they can't be unfocused in BwX mode, and if requested it will be ignored.    |
| <a id="XcodeProjInfo-xcode_target"></a>xcode_target |  A value returned from `xcode_targets.make` if this target can produce an Xcode target.    |
| <a id="XcodeProjInfo-xcode_targets"></a>xcode_targets |  A `depset` of values returned from `xcode_targets.make`, which potentially will become targets in the Xcode project.    |



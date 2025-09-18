# Bazel rules and macros

### Usage

To use these rules and macros in your `BUILD` files, `load` them from their
respective bzl file.

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
- [Custom Xcode schemes (Incremental generation mode)](#custom-xcode-schemes-incremental-generation-mode)
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
- [Xcode build settings](#xcode-build-settings)
  - [`xcode_provisioning_profile`](#xcode_provisioning_profile)
- [Providers](#providers)
  - [`XcodeProjAutomaticTargetProcessingInfo`](#XcodeProjAutomaticTargetProcessingInfo)
  - [`XcodeProjInfo`](#XcodeProjInfo)
- [Aspect Hints](#aspect-hints)
  - [`xcodeproj_extra_files`](#xcodeproj_extra_files)

# Core


<a id="xcodeproj"></a>

## xcodeproj

<pre>
xcodeproj(<a href="#xcodeproj-name">name</a>, <a href="#xcodeproj-associated_extra_files">associated_extra_files</a>, <a href="#xcodeproj-bazel_path">bazel_path</a>, <a href="#xcodeproj-bazel_env">bazel_env</a>, <a href="#xcodeproj-config">config</a>, <a href="#xcodeproj-default_xcode_configuration">default_xcode_configuration</a>,
          <a href="#xcodeproj-extra_files">extra_files</a>, <a href="#xcodeproj-focused_targets">focused_targets</a>, <a href="#xcodeproj-import_index_build_indexstores">import_index_build_indexstores</a>, <a href="#xcodeproj-install_directory">install_directory</a>,
          <a href="#xcodeproj-ios_device_cpus">ios_device_cpus</a>, <a href="#xcodeproj-ios_simulator_cpus">ios_simulator_cpus</a>, <a href="#xcodeproj-minimum_xcode_version">minimum_xcode_version</a>, <a href="#xcodeproj-post_build">post_build</a>, <a href="#xcodeproj-pre_build">pre_build</a>,
          <a href="#xcodeproj-project_name">project_name</a>, <a href="#xcodeproj-project_options">project_options</a>, <a href="#xcodeproj-scheme_autogeneration_mode">scheme_autogeneration_mode</a>, <a href="#xcodeproj-scheme_autogeneration_config">scheme_autogeneration_config</a>,
          <a href="#xcodeproj-target_name_mode">target_name_mode</a>, <a href="#xcodeproj-top_level_targets">top_level_targets</a>, <a href="#xcodeproj-tvos_device_cpus">tvos_device_cpus</a>, <a href="#xcodeproj-tvos_simulator_cpus">tvos_simulator_cpus</a>,
          <a href="#xcodeproj-unfocused_targets">unfocused_targets</a>, <a href="#xcodeproj-visionos_device_cpus">visionos_device_cpus</a>, <a href="#xcodeproj-visionos_simulator_cpus">visionos_simulator_cpus</a>, <a href="#xcodeproj-watchos_device_cpus">watchos_device_cpus</a>,
          <a href="#xcodeproj-watchos_simulator_cpus">watchos_simulator_cpus</a>, <a href="#xcodeproj-xcode_configurations">xcode_configurations</a>, <a href="#xcodeproj-xcschemes">xcschemes</a>, <a href="#xcodeproj-kwargs">kwargs</a>)
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
| <a id="xcodeproj-associated_extra_files"></a>associated_extra_files |  Optional. A `dict` of files to be added to the project.<br><br>The key is a `string` value representing the label of the target the files should be associated with, and the value is a `list` of `File`s. These files won't be added to the project if the target is unfocused.   |  `{}` |
| <a id="xcodeproj-bazel_path"></a>bazel_path |  Optional. The path the `bazel` binary or wrapper script.<br><br>If the path is relative it will be resolved using the `PATH` environment variable that is set when generating the project. If you want to specify a path to a workspace-relative binary, you must prepend the path with `./` (e.g. `"./bazelw"`).   |  `"bazel"` |
| <a id="xcodeproj-bazel_env"></a>bazel_env |  Optional. A `dict` of environment variables to set when invoking `bazel_path`.<br><br>This is useful for setting environment variables that are required for Bazel actions to run successfully, such as `JAVA_HOME` or `ANDROID_HOME`. It's also useful if `bazel_path` itself (if it's a wrapper) needs certain environment variables.<br><br>The keys are the names of the environment variables, and the values are the values of the environment variables. If a value is `None`, the environment variable will be resolved from the current environment as the project is generated. If a value references environment variables, those will be resolved from the current environment as the project is generated. If you want to use a literal `$` in a value, you must escape it with two backslashes.<br><br>If project generation succeeds, but building inside of Xcode fails because of missing environment variables, you probably have to set them here.<br><br>If `PATH` is not specified, it will default to `/bin:/usr/bin`, so you don't have to specify it unless you want to use a different value.<br><br>If `LANG` is not specified, it will default to `en_US.UTF-8`, so you don't have to specify it unless you want to use a different value.   |  `{"LANG": "en_US.UTF-8", "PATH": "/bin:/usr/bin"}` |
| <a id="xcodeproj-config"></a>config |  Optional. The Bazel config to use when generating the project or invoking `bazel` inside of Xcode.<br><br>This is the basename of multiple configs. For example, if this is set to `"projectx_xcodeproj"`, then the following configs will be available for you to adjust in your `.bazelrc` file:<br><br><ul> <li>`projectx_xcodeproj`</li> <li>`projectx_xcodeproj_generator`</li> <li>`projectx_xcodeproj_indexbuild`</li> <li>`projectx_xcodeproj_swiftuipreviews`</li> </ul><br><br>See the [usage guide](usage.md#bazel-configs) for more information on adjusting Bazel configs.   |  `"rules_xcodeproj"` |
| <a id="xcodeproj-default_xcode_configuration"></a>default_xcode_configuration |  Optional. The name of the the Xcode configuration to use when building, if not overridden by custom schemes.<br><br>If not set, the first Xcode configuration alphabetically will be used. Use [`xcode_configurations`](#xcodeproj-xcode_configurations) to adjust Xcode configurations.   |  `None` |
| <a id="xcodeproj-extra_files"></a>extra_files |  Optional. A `list` of extra `File`s to be added to the project.   |  `[]` |
| <a id="xcodeproj-focused_targets"></a>focused_targets |  Optional. A `list` of target labels as `string` values.<br><br>If specified, only these targets will be included in the generated project; all other targets will be excluded, as if they were listed explicitly in the `unfocused_targets` argument. The labels must match transitive dependencies of the targets specified in the `top_level_targets` argument.   |  `[]` |
| <a id="xcodeproj-import_index_build_indexstores"></a>import_index_build_indexstores |  Optional. Whether to import the index stores generated by Index Build.<br><br>This is useful if you want to use the index stores generated by Index Build to speed up Xcode's indexing process. You may not want this enabled if the additional work (mainly disk IO) of importing the index stores is not worth it for your project.<br><br>This only applies when using `generation_mode = "incremental"`.   |  `True` |
| <a id="xcodeproj-install_directory"></a>install_directory |  Optional. The directory where the generated project will be written to.<br><br>The path is relative to the workspace root.<br><br>Defaults to the directory that the `xcodeproj` target is declared in (e.g. if the `xcodeproj` target is declared in `//foo/bar:BUILD` then the default value is `"foo/bar"`). Use `""` to have the project generated in the workspace root.   |  `None` |
| <a id="xcodeproj-ios_device_cpus"></a>ios_device_cpus |  Optional. The value to use for `--ios_multi_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't iOS targets.   |  `"arm64"` |
| <a id="xcodeproj-ios_simulator_cpus"></a>ios_simulator_cpus |  Optional. The value to use for `--ios_multi_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't iOS targets.   |  `None` |
| <a id="xcodeproj-minimum_xcode_version"></a>minimum_xcode_version |  Optional. The minimum Xcode version that the generated project supports.<br><br>Newer Xcode versions can support newer features, so setting this to the highest value you can will enable the most features. The value is the dot separated version number (e.g. "13.4.1", "14", "14.1").<br><br>Defaults to whichever version of Xcode that Bazel uses during project generation.   |  `None` |
| <a id="xcodeproj-post_build"></a>post_build |  The text of a script that will be run after the build.<br><br>For example: `./post-build.sh`, `"$SRCROOT/post-build.sh"`.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure `$ACTION == build`.   |  `None` |
| <a id="xcodeproj-pre_build"></a>pre_build |  The text of a script that will be run before the build.<br><br>For example: `./pre-build.sh`, `"$SRCROOT/pre-build.sh"`.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.<br><br>Currently this script will be run as part of Index Build. If you don't want that (which is probably the case), you should add a check to ensure `$ACTION == build`.   |  `None` |
| <a id="xcodeproj-project_name"></a>project_name |  Optional. The name to use for the `.xcodeproj` file.<br><br>If not specified, the value of the `name` argument is used.   |  `None` |
| <a id="xcodeproj-project_options"></a>project_options |  Optional. A value returned by `project_options`.   |  `None` |
| <a id="xcodeproj-scheme_autogeneration_mode"></a>scheme_autogeneration_mode |  Optional. Specifies how Xcode schemes are automatically generated:<br><br><ul> <li>   `auto`: If no custom schemes are specified, via `schemes`, an   Xcode scheme will be created for every buildable target. If custom   schemes are provided, no autogenerated schemes will be created. </li> <li>   `none`: No schemes are automatically generated. </li> <li>   `all`: A scheme is generated for every buildable target even if   custom schemes are provided. </li> </ul>   |  `"auto"` |
| <a id="xcodeproj-scheme_autogeneration_config"></a>scheme_autogeneration_config |  Optional. A value returned by [`xcschemes.autogeneration_config`](#xcschemes.autogeneration_config).<br><br>Allows further configuration of `scheme_autogeneration_mode`.   |  `{}` |
| <a id="xcodeproj-target_name_mode"></a>target_name_mode |  Optional. Specifies how Xcode targets names are represented:<br><br><ul> <li>   `auto`: Use the product name if it is available and there is no collision.    Otherwise select the target name from the label.    And if there is a collision, use the full label. </li> <li>   `label`: Always use full label for Xcode targets names. </li> </ul>   |  `"auto"` |
| <a id="xcodeproj-top_level_targets"></a>top_level_targets |  A `list` of a list of top-level targets.<br><br>Each target can be specified as either a `Label` (or label-like `string`), a value returned by `top_level_target`, or a value returned by `top_level_targets`.   |  none |
| <a id="xcodeproj-tvos_device_cpus"></a>tvos_device_cpus |  Optional. The value to use for `--tvos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't tvOS targets.   |  `"arm64"` |
| <a id="xcodeproj-tvos_simulator_cpus"></a>tvos_simulator_cpus |  Optional. The value to use for `--tvos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `sim_arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't tvOS targets.   |  `None` |
| <a id="xcodeproj-unfocused_targets"></a>unfocused_targets |  Optional. A `list` of target labels as `string` values.<br><br>Any targets in the transitive dependencies of the targets specified in the `top_level_targets` argument with a matching label will be excluded from the generated project. This overrides any targets specified in the `focused_targets` argument.   |  `[]` |
| <a id="xcodeproj-visionos_device_cpus"></a>visionos_device_cpus |  Optional. The value to use for `--visionos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't visionOS targets.   |  `"arm64"` |
| <a id="xcodeproj-visionos_simulator_cpus"></a>visionos_simulator_cpus |  Optional. The value to use for `--visionos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't visionOS targets.   |  `"sim_arm64"` |
| <a id="xcodeproj-watchos_device_cpus"></a>watchos_device_cpus |  Optional. The value to use for `--watchos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"device"` `target_environment`, even if they aren't watchOS targets.   |  `"arm64_32"` |
| <a id="xcodeproj-watchos_simulator_cpus"></a>watchos_simulator_cpus |  Optional. The value to use for `--watchos_cpus` when building the transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`.<br><br>If no value is specified, it defaults to the simulator cpu that goes with `--host_cpu` (i.e. `arm64` on Apple Silicon and `x86_64` on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the `top_level_targets` argument with the `"simulator"` `target_environment`, even if they aren't watchOS targets.   |  `None` |
| <a id="xcodeproj-xcode_configurations"></a>xcode_configurations |  Optional. A `dict` mapping Xcode configuration names to transition settings dictionaries. For example:<br><br><pre><code class="language-starlark">{&#10;    "Dev": {&#10;        "//command_line_option:compilation_mode": "dbg",&#10;    },&#10;    "AppStore": {&#10;        "//command_line_option:compilation_mode": "opt",&#10;    },&#10;}</code></pre><br><br>would create the "Dev" and "AppStore" configurations, setting `--compilation_mode` to `dbg` and `opt` respectively.<br><br>Refer to the [bazel documentation](https://bazel.build/extending/config#defining) on how to define the transition settings dictionary.   |  `{"Debug": {}}` |
| <a id="xcodeproj-xcschemes"></a>xcschemes |  Optional. A `list` of values returned by `xcschemes.scheme`.<br><br>This and the `scheme_autogeneration_mode` argument together customize how schemes for targets are generated.   |  `[]` |
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

A `list` of values from `top_level_target`.




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

To use these functions, `load` the `xcschemes` module from
`xcodeproj/xcschemes.bzl`:

```starlark
load("@rules_xcodeproj//xcodeproj:xcschemes.bzl", "xcschemes")
```

<a id="xcschemes.arg"></a>

## xcschemes.arg

<pre>
xcschemes.arg(<a href="#xcschemes.arg-value">value</a>, <a href="#xcschemes.arg-enabled">enabled</a>, <a href="#xcschemes.arg-literal_string">literal_string</a>)
</pre>

Defines a command-line argument.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.arg-value"></a>value |  Positional. The command-line argument.<br><br>Arguments with quotes, spaces, or newlines will be escaped. You should not use additional quotes around arguments with spaces. If you include quotes around your argument, those quotes will be part of the argument.   |  none |
| <a id="xcschemes.arg-enabled"></a>enabled |  Whether the command-line argument is enabled.<br><br>If `True`, the checkbox for the argument will be checked in the scheme. An unchecked checkbox means Xcode won't include that argument when running a target.   |  `True` |
| <a id="xcschemes.arg-literal_string"></a>literal_string |  Whether `value` should be interpreted as a literal string.<br><br>If `True`, any spaces will be escaped. This means that `value` will be passed to the launch target as a single string. If `False`, any spaces will not be escaped. This is useful to group multiple arguments under a single checkbox in Xcode.   |  `True` |


<a id="xcschemes.autogeneration.test"></a>

## xcschemes.autogeneration.test

<pre>
xcschemes.autogeneration.test(<a href="#xcschemes.autogeneration.test-options">options</a>)
</pre>

Creates a value for the `test` argument of `xcschemes.autogeneration_config`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.autogeneration.test-options"></a>options |  Test options for autogeneration.<br><br>Defaults to `None`.   |  `None` |

**RETURNS**

An opaque value for the
  [`test`](user-content-xcschemes.autogeneration_config-test)
  argument of `xcschemes.autogeneration_config`.


<a id="xcschemes.autogeneration_config"></a>

## xcschemes.autogeneration_config

<pre>
xcschemes.autogeneration_config(<a href="#xcschemes.autogeneration_config-scheme_name_exclude_patterns">scheme_name_exclude_patterns</a>, <a href="#xcschemes.autogeneration_config-test">test</a>)
</pre>

Creates a value for the [`scheme_autogeneration_config`](xcodeproj-scheme_autogeneration_config) attribute of `xcodeproj`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.autogeneration_config-scheme_name_exclude_patterns"></a>scheme_name_exclude_patterns |  A `list` of regex patterns used to skip creating matching autogenerated schemes.<br><br>Example:<br><br><pre><code class="language-starlark">xcodeproj(&#10;    ...&#10;    scheme_name_exclude_patterns = xcschemes.autogeneration_config(&#10;        scheme_name_exclude_patterns = [&#10;            ".*somePattern.*",&#10;            "^AnotherPattern.*",&#10;        ],&#10;    ),&#10;)</code></pre>   |  `None` |
| <a id="xcschemes.autogeneration_config-test"></a>test |  Options to use for the test action.<br><br>Example:<br><br>```starlark xcodeproj(     ...     scheme_autogeneration_config = xcschemes.autogeneration_config(         test = xcschemes.autogeneration.test(             options = xcschemes.test_options(                 app_language = "en",                 app_region = "US",             )         )     ) )   |  `None` |

**RETURNS**

An opaque value for the [`scheme_autogeneration_config`](xcodeproj-scheme_autogeneration_config) attribute of `xcodeproj`.


<a id="xcschemes.diagnostics"></a>

## xcschemes.diagnostics

<pre>
xcschemes.diagnostics(<a href="#xcschemes.diagnostics-address_sanitizer">address_sanitizer</a>, <a href="#xcschemes.diagnostics-thread_sanitizer">thread_sanitizer</a>, <a href="#xcschemes.diagnostics-undefined_behavior_sanitizer">undefined_behavior_sanitizer</a>,
                      <a href="#xcschemes.diagnostics-main_thread_checker">main_thread_checker</a>, <a href="#xcschemes.diagnostics-thread_performance_checker">thread_performance_checker</a>)
</pre>

Defines the diagnostics to enable.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.diagnostics-address_sanitizer"></a>address_sanitizer |  Whether to enable Address Sanitizer.<br><br>If `True`, [`thread_sanitizer`](#xcschemes.diagnostics-thread_sanitizer) must be `False`.   |  `False` |
| <a id="xcschemes.diagnostics-thread_sanitizer"></a>thread_sanitizer |  Whether to enable Thread Sanitizer.<br><br>If `True`, [`address_sanitizer`](#xcschemes.diagnostics-address_sanitizer) must be `False`.   |  `False` |
| <a id="xcschemes.diagnostics-undefined_behavior_sanitizer"></a>undefined_behavior_sanitizer |  Whether to enable Undefined Behavior Sanitizer.   |  `False` |
| <a id="xcschemes.diagnostics-main_thread_checker"></a>main_thread_checker |  Whether to enable Main Thread Checker.   |  `True` |
| <a id="xcschemes.diagnostics-thread_performance_checker"></a>thread_performance_checker |  Whether to enable Thread Performance Checker.   |  `True` |


<a id="xcschemes.env_value"></a>

## xcschemes.env_value

<pre>
xcschemes.env_value(<a href="#xcschemes.env_value-value">value</a>, <a href="#xcschemes.env_value-enabled">enabled</a>)
</pre>

Defines an environment variable value.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.env_value-value"></a>value |  Positional. The environment variable value.<br><br>Values with quotes, spaces, or newlines will be escaped. You should not use additional quotes around values with spaces. If you include quotes around your value, those quotes will be part of the value.   |  none |
| <a id="xcschemes.env_value-enabled"></a>enabled |  Whether the environment variable is enabled.<br><br>If `True`, the checkbox for the environment variable will be checked in the scheme. An unchecked checkbox means Xcode won't include that environment variable when running a target.   |  `True` |


<a id="xcschemes.launch_path"></a>

## xcschemes.launch_path

<pre>
xcschemes.launch_path(<a href="#xcschemes.launch_path-path">path</a>, <a href="#xcschemes.launch_path-post_actions">post_actions</a>, <a href="#xcschemes.launch_path-pre_actions">pre_actions</a>, <a href="#xcschemes.launch_path-working_directory">working_directory</a>)
</pre>

Defines the launch path for a pre-built executable.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.launch_path-path"></a>path |  Positional. The launch path for a launch target.<br><br>The path must be an absolute path to an executable file. It will be set as the runnable within a launch action.   |  none |
| <a id="xcschemes.launch_path-post_actions"></a>post_actions |  Post-actions to run when running the launch path.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.launch_path-pre_actions"></a>pre_actions |  Pre-actions to run when running the launch path.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.launch_path-working_directory"></a>working_directory |  The working directory to use when running the launch target.<br><br>If not set, the Xcode default working directory will be used (i.e. some directory in `DerivedData`).   |  `None` |


<a id="xcschemes.launch_target"></a>

## xcschemes.launch_target

<pre>
xcschemes.launch_target(<a href="#xcschemes.launch_target-label">label</a>, <a href="#xcschemes.launch_target-extension_host">extension_host</a>, <a href="#xcschemes.launch_target-library_targets">library_targets</a>, <a href="#xcschemes.launch_target-post_actions">post_actions</a>, <a href="#xcschemes.launch_target-pre_actions">pre_actions</a>,
                        <a href="#xcschemes.launch_target-target_environment">target_environment</a>, <a href="#xcschemes.launch_target-working_directory">working_directory</a>)
</pre>

Defines a launch target.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.launch_target-label"></a>label |  Positional. The label string of the target to launch when running.   |  none |
| <a id="xcschemes.launch_target-extension_host"></a>extension_host |  The label string of an extension host for the launch target.<br><br>If [`label`](#xcschemes.launch_target-label) is an app extension, this must be set to the label string of a target that bundles the app extension. Otherwise, this must be `None`.   |  `None` |
| <a id="xcschemes.launch_target-library_targets"></a>library_targets |  Additional library targets to build when running.<br><br>Library targets must be transitive dependencies of the launch target.<br><br>Each element of the `list` can be a label string or a value returned by [`xcschemes.library_target`](#xcschemes.library_target). If an element is a label string, it will be transformed into `xcschemes.library_target(label_str)`. For example, <pre><code>xcschemes.launch_target(&#10;    &hellip;&#10;    library_targets = [&#10;        "//Modules/Lib1",&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.launch_target(&#10;    &hellip;&#10;    library_targets = [&#10;        xcschemes.library_target("//Modules/Lib1"),&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.launch_target-post_actions"></a>post_actions |  Post-actions to run when building or running the launch target.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.launch_target-pre_actions"></a>pre_actions |  Pre-actions to run when building or running the launch target.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.launch_target-target_environment"></a>target_environment |  The [target environment](#top_level_target-target_environments) to use when determining which version of the launch target [`label`](#xcschemes.launch_target-label) refers to.<br><br>If not set, the default target environment will be used (i.e. `"simulator"` if it's one of the available target environments, otherwise `"device"`).   |  `None` |
| <a id="xcschemes.launch_target-working_directory"></a>working_directory |  The working directory to use when running the launch target.<br><br>If not set, the Xcode default working directory will be used (i.e. some directory in `DerivedData`).   |  `None` |


<a id="xcschemes.library_target"></a>

## xcschemes.library_target

<pre>
xcschemes.library_target(<a href="#xcschemes.library_target-label">label</a>, <a href="#xcschemes.library_target-post_actions">post_actions</a>, <a href="#xcschemes.library_target-pre_actions">pre_actions</a>)
</pre>

Defines a library target to build.

A library target is any target not classified as a top-level target.
Normally these targets are created with rules similar to `swift_library`
or `objc_library`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.library_target-label"></a>label |  Positional. The label string of the library target.<br><br>This must be a library target (i.e. not a top-level target); use the `build_targets` attribute of [`profile`](#xcschemes.profile-build_targets), [`run`](#xcschemes.run-build_targets), or [`test`](#xcschemes.test-build_targets) to add top-level build targets.   |  none |
| <a id="xcschemes.library_target-post_actions"></a>post_actions |  Post-actions to run when building or running the action this build target is a part of.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.library_target-pre_actions"></a>pre_actions |  Pre-actions to run when building or running the action this build target is a part of.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |


<a id="xcschemes.pre_post_actions.build_script"></a>

## xcschemes.pre_post_actions.build_script

<pre>
xcschemes.pre_post_actions.build_script(<a href="#xcschemes.pre_post_actions.build_script-title">title</a>, <a href="#xcschemes.pre_post_actions.build_script-order">order</a>, <a href="#xcschemes.pre_post_actions.build_script-script_text">script_text</a>)
</pre>

Defines a pre-action or post-action script to run when building.

This action will appear in the Pre-actions or Post-actions section of the
Build section of the scheme.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.pre_post_actions.build_script-title"></a>title |  The title of the action.   |  `"Run Script"` |
| <a id="xcschemes.pre_post_actions.build_script-order"></a>order |  The relative order of the action within the section it appears in.<br><br>If `None`, the action will be added to the end of the section, in an unspecified but deterministic order. Otherwise, the order should be an integer. Smaller order values will run before larger order values. rules_xcodeproj created actions (e.g. "Update .lldbinit and copy dSYMs") use order values 0, -100, -200, etc.   |  `None` |
| <a id="xcschemes.pre_post_actions.build_script-script_text"></a>script_text |  The script text.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.   |  none |


<a id="xcschemes.pre_post_actions.launch_script"></a>

## xcschemes.pre_post_actions.launch_script

<pre>
xcschemes.pre_post_actions.launch_script(<a href="#xcschemes.pre_post_actions.launch_script-title">title</a>, <a href="#xcschemes.pre_post_actions.launch_script-order">order</a>, <a href="#xcschemes.pre_post_actions.launch_script-script_text">script_text</a>)
</pre>

Defines a pre-action or post-action script to run when running.

This action will appear in the Pre-actions or Post-actions section of the
Test, Run, or Profile section of the scheme.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.pre_post_actions.launch_script-title"></a>title |  The title of the action.   |  `"Run Script"` |
| <a id="xcschemes.pre_post_actions.launch_script-order"></a>order |  The relative order of the action within the section it appears in.<br><br>If `None`, the action will be added to the end of the section, in an unspecified but deterministic order. Otherwise, the order should be an integer. Smaller order values will run before larger order values. rules_xcodeproj created actions (e.g. "Update .lldbinit and copy dSYMs") use order values 0, -100, -200, etc.   |  `None` |
| <a id="xcschemes.pre_post_actions.launch_script-script_text"></a>script_text |  The script text.<br><br>The script will be run in Bazel's execution root, so you probably want to change to the `$SRCROOT` directory in the script.   |  none |


<a id="xcschemes.profile"></a>

## xcschemes.profile

<pre>
xcschemes.profile(<a href="#xcschemes.profile-args">args</a>, <a href="#xcschemes.profile-build_targets">build_targets</a>, <a href="#xcschemes.profile-env">env</a>, <a href="#xcschemes.profile-env_include_defaults">env_include_defaults</a>, <a href="#xcschemes.profile-launch_target">launch_target</a>,
                  <a href="#xcschemes.profile-use_run_args_and_env">use_run_args_and_env</a>, <a href="#xcschemes.profile-xcode_configuration">xcode_configuration</a>)
</pre>

Defines the Profile action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.profile-args"></a>args |  Command-line arguments to use when profiling the launch target.<br><br>If `"inherit"`, then the arguments will be supplied by the launch target (e.g. [`cc_binary.args`](https://bazel.build/reference/be/common-definitions#binary.args)). Otherwise, the `list` of arguments will be set as provided, and `None` or `[]` will result in no command-line arguments.<br><br>Each element of the `list` can either be a string or a value returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a string, it will be transformed into `xcschemes.arg(element)`. For example, <pre><code>xcschemes.profile(&#10;    args = [&#10;        "-arg1",&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.profile(&#10;    args = [&#10;        xcschemes.arg("-arg1"),&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.profile-build_targets"></a>build_targets |  Additional targets to build when profiling.<br><br>Each element of the `list` can be a label string, a value returned by [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target), or a value returned by [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target). If an element is a label string, it will be transformed into `xcschemes.top_level_build_target(label_str)`. For example, <pre><code>xcschemes.profile(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        "//App:Test",&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.profile(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        xcschemes.top_level_build_target("//App:Test"),&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.profile-env"></a>env |  Environment variables to use when profiling the launch target.<br><br>If set to `"inherit"`, then the environment variables will be supplied by the launch target (e.g. [`cc_binary.env`](https://bazel.build/reference/be/common-definitions#binary.env)). Otherwise, the `dict` of environment variables will be set as provided, and `None` or `{}` will result in no environment variables.<br><br>Each value of the `dict` can either be a string or a value returned by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a string, it will be transformed into `xcschemes.env_value(value)`. For example, <pre><code>xcschemes.profile(&#10;    env = {&#10;        "VAR1": "value 1",&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.profile(&#10;    env = {&#10;        "VAR1": xcschemes.env_value("value 1"),&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.profile-env_include_defaults"></a>env_include_defaults |  Whether to include the rules_xcodeproj provided default Bazel environment variables (e.g. `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in addition to any set by [`env`](#xcschemes.profile-env). This does not apply to [`xcschemes.launch_path`](#xcschemes.launch_path)s.   |  `True` |
| <a id="xcschemes.profile-launch_target"></a>launch_target |  The target to launch when profiling.<br><br>Can be `None`, a label string, a value returned by [`xcschemes.launch_target`](#xcschemes.launch_target), or a value returned by [`xcschemes.launch_path`](#xcschemes.launch_path). If a label string, `xcschemes.launch_target(label_str)` will be used. If `None`, `xcschemes.launch_target()` will be used, which means no launch target will be set (i.e. the `Executable` dropdown will be set to `None`).   |  `None` |
| <a id="xcschemes.profile-use_run_args_and_env"></a>use_run_args_and_env |  Whether the `Use the Run action's arguments and environment variables` checkbox is checked.<br><br>If `True`, command-line arguments and environment variables will still be set as defined by [`args`](#xcschemes.profile-args) and [`env`](#xcschemes.profile-env), but will be ignored by Xcode unless you manually uncheck this checkbox in the scheme. If `None`, `True` will be used if [`args`](#xcschemes.profile-args) and [`env`](#xcschemes.profile-env) are both `"inherit"`, otherwise `False` will be used.<br><br>A value of `True` will be ignored (i.e. treated as `False`) if [`run.launch_target`](#xcschemes.run-launch_target) is not set to a target.   |  `None` |
| <a id="xcschemes.profile-xcode_configuration"></a>xcode_configuration |  The name of the Xcode configuration to use to build the targets referenced in the Profile action (i.e in the [`build_targets`](#xcschemes.profile-build_targets) and [`launch_target`](#xcschemes.profile-launch_target) attributes).<br><br>If not set, the value of [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration) is used.   |  `None` |


<a id="xcschemes.run"></a>

## xcschemes.run

<pre>
xcschemes.run(<a href="#xcschemes.run-args">args</a>, <a href="#xcschemes.run-build_targets">build_targets</a>, <a href="#xcschemes.run-diagnostics">diagnostics</a>, <a href="#xcschemes.run-env">env</a>, <a href="#xcschemes.run-env_include_defaults">env_include_defaults</a>, <a href="#xcschemes.run-launch_target">launch_target</a>,
              <a href="#xcschemes.run-xcode_configuration">xcode_configuration</a>)
</pre>

Defines the Run action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.run-args"></a>args |  Command-line arguments to use when running the launch target.<br><br>If `"inherit"`, then the arguments will be supplied by the launch target (e.g. [`cc_binary.args`](https://bazel.build/reference/be/common-definitions#binary.args)). Otherwise, the `list` of arguments will be set as provided, and `None` or `[]` will result in no command-line arguments.<br><br>Each element of the `list` can either be a string or a value returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a string, it will be transformed into `xcschemes.arg(element)`. For example, <pre><code>xcschemes.run(&#10;    args = [&#10;        "-arg1",&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.run(&#10;    args = [&#10;        xcschemes.arg("-arg1"),&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.run-build_targets"></a>build_targets |  Additional targets to build when running.<br><br>Each element of the `list` can be a label string, a value returned by [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target), or a value returned by [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target). If an element is a label string, it will be transformed into `xcschemes.top_level_build_target(label_str)`. For example, <pre><code>xcschemes.run(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        "//App:Test",&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.run(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        xcschemes.top_level_build_target("//App:Test"),&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.run-diagnostics"></a>diagnostics |  The diagnostics to enable when running the launch target.<br><br>Can be `None` or a value returned by [`xcschemes.diagnostics`](#xcschemes.diagnostics). If `None`, `xcschemes.diagnostics()` will be used, which means no diagnostics will be enabled.   |  `None` |
| <a id="xcschemes.run-env"></a>env |  Environment variables to use when running the launch target.<br><br>If set to `"inherit"`, then the environment variables will be supplied by the launch target (e.g. [`cc_binary.env`](https://bazel.build/reference/be/common-definitions#binary.env)). Otherwise, the `dict` of environment variables will be set as provided, and `None` or `{}` will result in no environment variables.<br><br>Each value of the `dict` can either be a string or a value returned by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a string, it will be transformed into `xcschemes.env_value(value)`. For example, <pre><code>xcschemes.run(&#10;    env = {&#10;        "VAR1": "value 1",&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.run(&#10;    env = {&#10;        "VAR1": xcschemes.env_value("value 1"),&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.run-env_include_defaults"></a>env_include_defaults |  Whether to include the rules_xcodeproj provided default Bazel environment variables (e.g. `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in addition to any set by [`env`](#xcschemes.run-env). This does not apply to [`xcschemes.launch_path`](#xcschemes.launch_path)s.   |  `True` |
| <a id="xcschemes.run-launch_target"></a>launch_target |  The target to launch when running.<br><br>Can be `None`, a label string, a value returned by [`xcschemes.launch_target`](#xcschemes.launch_target), or a value returned by [`xcschemes.launch_path`](#xcschemes.launch_path). If a label string, `xcschemes.launch_target(label_str)` will be used. If `None`, `xcschemes.launch_target()` will be used, which means no launch target will be set (i.e. the `Executable` dropdown will be set to `None`).   |  `None` |
| <a id="xcschemes.run-xcode_configuration"></a>xcode_configuration |  The name of the Xcode configuration to use to build the targets referenced in the Run action (i.e in the [`build_targets`](#xcschemes.run-build_targets) and [`launch_target`](#xcschemes.run-launch_target) attributes).<br><br>If not set, the value of [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration) is used.   |  `None` |


<a id="xcschemes.scheme"></a>

## xcschemes.scheme

<pre>
xcschemes.scheme(<a href="#xcschemes.scheme-name">name</a>, <a href="#xcschemes.scheme-profile">profile</a>, <a href="#xcschemes.scheme-run">run</a>, <a href="#xcschemes.scheme-test">test</a>)
</pre>

Defines a custom scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.scheme-name"></a>name |  Positional. The name of the scheme.   |  none |
| <a id="xcschemes.scheme-profile"></a>profile |  A value returned by [`xcschemes.profile`](#xcschemes.profile), or the string `"same_as_run"`.<br><br>If `"same_as_run"`, the same targets will be built for the Profile action as are built for the Run action (defined by [`xcschemes.run`](#xcschemes.run)). If `None`, `xcschemes.profile()` will be used, which means no targets will be built for the Profile action.   |  `"same_as_run"` |
| <a id="xcschemes.scheme-run"></a>run |  A value returned by [`xcschemes.run`](#xcschemes.run).<br><br>If `None`, `xcschemes.run()` will be used, which means no targets will be built for the Run action, except for `build_targets` and `library_targets` specified in [`xcschemes.profile`](#xcschemes.profile) and [`xcschemes.test`](#xcschemes.test).   |  `None` |
| <a id="xcschemes.scheme-test"></a>test |  A value returned by [`xcschemes.test`](#xcschemes.test).<br><br>If `None`, `xcschemes.test()` will be used, which means no targets will be built for the Test action.   |  `None` |


<a id="xcschemes.test"></a>

## xcschemes.test

<pre>
xcschemes.test(<a href="#xcschemes.test-args">args</a>, <a href="#xcschemes.test-build_targets">build_targets</a>, <a href="#xcschemes.test-diagnostics">diagnostics</a>, <a href="#xcschemes.test-env">env</a>, <a href="#xcschemes.test-env_include_defaults">env_include_defaults</a>, <a href="#xcschemes.test-test_options">test_options</a>,
               <a href="#xcschemes.test-test_targets">test_targets</a>, <a href="#xcschemes.test-use_run_args_and_env">use_run_args_and_env</a>, <a href="#xcschemes.test-xcode_configuration">xcode_configuration</a>)
</pre>

Defines the Test action.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.test-args"></a>args |  Command-line arguments to use when testing.<br><br>If `"inherit"`, then the arguments will be supplied by the test targets (e.g. [`cc_test.args`](https://bazel.build/reference/be/common-definitions#binary.args)), as long as every test target has the same arguments. Otherwise, the `list` of arguments will be set as provided, and `None` or `[]` will result in no command-line arguments.<br><br>Each element of the `list` can either be a string or a value returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a string, it will be transformed into `xcschemes.arg(element)`. For example, <pre><code>xcschemes.test(&#10;    args = [&#10;        "-arg1",&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.test(&#10;    args = [&#10;        xcschemes.arg("-arg1"),&#10;        xcschemes.arg("-arg2", enabled = False),&#10;    ],&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.test-build_targets"></a>build_targets |  Additional targets to build when testing.<br><br>Each element of the `list` can be a label string, a value returned by [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target), or a value returned by [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target). If an element is a label string, it will be transformed into `xcschemes.top_level_build_target(label_str)`. For example, <pre><code>xcschemes.test(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        "//App:Test",&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.test(&#10;    build_targets = [&#10;        xcschemes.top_level_anchor_target(&#10;            "//App",&#10;            &hellip;&#10;        ),&#10;        xcschemes.top_level_build_target("//App:Test"),&#10;        xcschemes.top_level_build_target(&#10;            "//CommandLineTool",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.test-diagnostics"></a>diagnostics |  The diagnostics to enable when testing.<br><br>Can be `None` or a value returned by [`xcschemes.diagnostics`](#xcschemes.diagnostics). If `None`, `xcschemes.diagnostics()` will be used, which means no diagnostics will be enabled.   |  `None` |
| <a id="xcschemes.test-env"></a>env |  Environment variables to use when testing.<br><br>If set to `"inherit"`, then the environment variables will be supplied by the test targets (e.g. [`ios_unit_test.env`](https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_unit_test-env)), as long as every test target has the same environment variables. Otherwise, the `dict` of environment variables will be set as provided, and `None` or `{}` will result in no environment variables.<br><br>Each value of the `dict` can either be a string or a value returned by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a string, it will be transformed into `xcschemes.env_value(value)`. For example, <pre><code>xcschemes.test(&#10;    env = {&#10;        "VAR1": "value 1",&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.test(&#10;    env = {&#10;        "VAR1": xcschemes.env_value("value 1"),&#10;        "VAR 2": xcschemes.env_value("value2", enabled = False),&#10;    },&#10;)</code></pre>   |  `"inherit"` |
| <a id="xcschemes.test-env_include_defaults"></a>env_include_defaults |  Whether to include the rules_xcodeproj provided default Bazel environment variables (e.g. `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in addition to any set by [`env`](#xcschemes.test-env).   |  `True` |
| <a id="xcschemes.test-test_options"></a>test_options |  The test options to set for testing. Can be `None` or a value returned by [`xcschemes.test_options`](#xcschemes.test_options). If `None`, `xcschemes.test_options()` will be used, which means no additional test options be set.   |  `None` |
| <a id="xcschemes.test-test_targets"></a>test_targets |  The test targets to build, and possibly run, when testing.<br><br>Each element of the `list` can be a label string or a value returned by [`xcschemes.test_target`](#xcschemes.test_target). If an element is a label string, it will be transformed into `xcschemes.test_target(label_str)`. For example, <pre><code>xcschemes.test(&#10;    test_targets = [&#10;        "//App:Test1",&#10;        xcschemes.test_target(&#10;            "//App:Test2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.test(&#10;    test_targets = [&#10;        xcschemes.test_target("//App:Test1"),&#10;        xcschemes.test_target(&#10;            "//App:Test2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.test-use_run_args_and_env"></a>use_run_args_and_env |  Whether the `Use the Run action's arguments and environment variables` checkbox is checked.<br><br>If `True`, command-line arguments and environment variables will still be set as defined by [`args`](#xcschemes.test-args) and [`env`](#xcschemes.test-env), but will be ignored by Xcode unless you manually uncheck this checkbox in the scheme. If `None`, `True` will be used if [`args`](#xcschemes.test-args) and [`env`](#xcschemes.test-env) are both `"inherit"`, otherwise `False` will be used.<br><br>A value of `True` will be ignored (i.e. treated as `False`) if [`run.launch_target`](#xcschemes.run-launch_target) is not set to a target.   |  `None` |
| <a id="xcschemes.test-xcode_configuration"></a>xcode_configuration |  The name of the Xcode configuration to use to build the targets referenced in the Test action (i.e in the [`build_targets`](#xcschemes.test-build_targets) and [`test_targets`](#xcschemes.test-test_targets) attributes).<br><br>If not set, the value of [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration) is used.   |  `None` |


<a id="xcschemes.test_options"></a>

## xcschemes.test_options

<pre>
xcschemes.test_options(<a href="#xcschemes.test_options-app_language">app_language</a>, <a href="#xcschemes.test_options-app_region">app_region</a>)
</pre>

Defines the test options for a custom scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.test_options-app_language"></a>app_language |  Language to set in scheme.<br><br>Defaults to system settings if not set.   |  `None` |
| <a id="xcschemes.test_options-app_region"></a>app_region |  Region to set in scheme.<br><br>Defaults to system settings if not set.   |  `None` |


<a id="xcschemes.test_target"></a>

## xcschemes.test_target

<pre>
xcschemes.test_target(<a href="#xcschemes.test_target-label">label</a>, <a href="#xcschemes.test_target-enabled">enabled</a>, <a href="#xcschemes.test_target-library_targets">library_targets</a>, <a href="#xcschemes.test_target-post_actions">post_actions</a>, <a href="#xcschemes.test_target-pre_actions">pre_actions</a>,
                      <a href="#xcschemes.test_target-target_environment">target_environment</a>)
</pre>

Defines a test target.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.test_target-label"></a>label |  Positional. The label string of the test target.   |  none |
| <a id="xcschemes.test_target-enabled"></a>enabled |  Whether the test target is enabled.<br><br>If `True`, the checkbox for the test target will be checked in the scheme. An unchecked checkbox means Xcode won't run this test target when testing.   |  `True` |
| <a id="xcschemes.test_target-library_targets"></a>library_targets |  Additional library targets to build when testing.<br><br>Library targets must be transitive dependencies of the test target. They must not be top-level targets; use [`build_targets`](#xcschemes.test-build_targets) for those.<br><br>Each element of the `list` can be a label string or a value returned by [`xcschemes.library_target`](#xcschemes.library_target). If an element is a label string, it will be transformed into `xcschemes.library_target(label_str)`. For example, <pre><code>xcschemes.test_target(&#10;    &hellip;&#10;    library_targets = [&#10;        "//Modules/Lib1",&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.test_target(&#10;    &hellip;&#10;    library_targets = [&#10;        xcschemes.library_target("//Modules/Lib1"),&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.test_target-post_actions"></a>post_actions |  Post-actions to run when building or running the test target.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.test_target-pre_actions"></a>pre_actions |  Pre-actions to run when building or running the test target.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.test_target-target_environment"></a>target_environment |  The [target environment](#top_level_target-target_environments) to use when determining which version of the test target [`label`](#xcschemes.launch_target-label) refers to.<br><br>If not set, the default target environment will be used (i.e. `"simulator"` if it's one of the available target environments, otherwise `"device"`).   |  `None` |


<a id="xcschemes.top_level_anchor_target"></a>

## xcschemes.top_level_anchor_target

<pre>
xcschemes.top_level_anchor_target(<a href="#xcschemes.top_level_anchor_target-label">label</a>, <a href="#xcschemes.top_level_anchor_target-extension_host">extension_host</a>, <a href="#xcschemes.top_level_anchor_target-library_targets">library_targets</a>, <a href="#xcschemes.top_level_anchor_target-target_environment">target_environment</a>)
</pre>

Defines a top-level anchor target for library build targets.

Use this function to define library targets to build, when you don't want
to also build the top-level target that depends on them. If you also want to
build the top-level target, use
[`top_level_build_target`](#xcschemes.top_level_build_target-library_targets)
instead.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.top_level_anchor_target-label"></a>label |  Positional. The label string of the top-level target.<br><br>This must be a top-level target (i.e. not a library target); use the `library_targets` attribute of [`launch_target`](#xcschemes.launch_target-library_targets), [`test_target`](#xcschemes.test_target-library_targets), [`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets), or [`top_level_build_target`](#xcschemes.top_level_build_target-library_targets) to add library build targets.   |  none |
| <a id="xcschemes.top_level_anchor_target-extension_host"></a>extension_host |  The label string of an extension host for the top-level target.<br><br>If [`label`](#xcschemes.top_level_build_target-label) is an app extension, this must be set to the label string of a target that bundles the app extension. Otherwise, this must be `None`.   |  `None` |
| <a id="xcschemes.top_level_anchor_target-library_targets"></a>library_targets |  The library targets to build.<br><br>Library targets must be transitive dependencies of the top-level anchor target. They must not be top-level targets; instead, set additional values in the `build_targets` attribute that this `top_level_build_target` is defined in.<br><br>Each element of the `list` can be a label string or a value returned by [`xcschemes.library_target`](#xcschemes.library_target). If an element is a label string, it will be transformed into `xcschemes.library_target(label_str)`. For example, <pre><code>xcschemes.top_level_anchor_target(&#10;    &hellip;&#10;    library_targets = [&#10;        "//Modules/Lib1",&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.top_level_anchor_target(&#10;    &hellip;&#10;    library_targets = [&#10;        xcschemes.library_target("//Modules/Lib1"),&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  none |
| <a id="xcschemes.top_level_anchor_target-target_environment"></a>target_environment |  The [target environment](#top_level_target-target_environments) to use when determining which version of the top-level target [`label`](#xcschemes.top_level_build_target-label) refers to.<br><br>If not set, the default target environment will be used (i.e. `"simulator"` if it's one of the available target environments, otherwise `"device"`).   |  `None` |


<a id="xcschemes.top_level_build_target"></a>

## xcschemes.top_level_build_target

<pre>
xcschemes.top_level_build_target(<a href="#xcschemes.top_level_build_target-label">label</a>, <a href="#xcschemes.top_level_build_target-extension_host">extension_host</a>, <a href="#xcschemes.top_level_build_target-library_targets">library_targets</a>, <a href="#xcschemes.top_level_build_target-post_actions">post_actions</a>, <a href="#xcschemes.top_level_build_target-pre_actions">pre_actions</a>,
                                 <a href="#xcschemes.top_level_build_target-target_environment">target_environment</a>)
</pre>

Defines a top-level target to build.

Use this function to define a top-level target, and optionally transitive
library targets, to build. If you don't want to build the top-level target,
and only want to build the transitive library targets, use
[`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets)
instead.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcschemes.top_level_build_target-label"></a>label |  Positional. The label string of the top-level target.<br><br>This must be a top-level target (i.e. not a library target); use the `library_targets` attribute of [`launch_target`](#xcschemes.launch_target-library_targets), [`test_target`](#xcschemes.test_target-library_targets), [`top_level_build_target`](#xcschemes.top_level_build_target-library_targets), or [`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets) to add library build targets.   |  none |
| <a id="xcschemes.top_level_build_target-extension_host"></a>extension_host |  The label string of an extension host for the top-level target.<br><br>If [`label`](#xcschemes.top_level_build_target-label) is an app extension, this must be set to the label string of a target that bundles the app extension. Otherwise, this must be `None`.   |  `None` |
| <a id="xcschemes.top_level_build_target-library_targets"></a>library_targets |  Additional library targets to build.<br><br>Library targets must be transitive dependencies of the top-level build target. They must not be top-level targets; instead, set additional values in the `build_targets` attribute that this `top_level_build_target` is defined in.<br><br>Each element of the `list` can be a label string or a value returned by [`xcschemes.library_target`](#xcschemes.library_target). If an element is a label string, it will be transformed into `xcschemes.library_target(label_str)`. For example, <pre><code>xcschemes.top_level_build_target(&#10;    &hellip;&#10;    library_targets = [&#10;        "//Modules/Lib1",&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre> will be transformed into: <pre><code>xcschemes.top_level_build_target(&#10;    &hellip;&#10;    library_targets = [&#10;        xcschemes.library_target("//Modules/Lib1"),&#10;        xcschemes.library_target(&#10;            "//Modules/Lib2",&#10;            &hellip;&#10;        ),&#10;    ],&#10;)</code></pre>   |  `[]` |
| <a id="xcschemes.top_level_build_target-post_actions"></a>post_actions |  Post-actions to run when building or running the action this build target is a part of.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.top_level_build_target-pre_actions"></a>pre_actions |  Pre-actions to run when building or running the action this build target is a part of.<br><br>Elements of the `list` must be values returned by functions in [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).   |  `[]` |
| <a id="xcschemes.top_level_build_target-target_environment"></a>target_environment |  The [target environment](#top_level_target-target_environments) to use when determining which version of the top-level target [`label`](#xcschemes.top_level_build_target-label) refers to.<br><br>If not set, the default target environment will be used (i.e. `"simulator"` if it's one of the available target environments, otherwise `"device"`).   |  `None` |


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
| <a id="xcode_provisioning_profile-managed_by_xcode"></a>managed_by_xcode |  Whether the provisioning profile is managed by Xcode. If `True`, "Automatic Code Signing" will be enabled in Xcode, and the profile name will be ignored. Xcode will add devices to profiles automatically via the currently logged in Apple Developer Account, and otherwise fully manage the profile. If `False`, "Manual Code Signing" will be enabled in Xcode, and the profile name will be used to determine which profile to use.<br><br>Xcode will still manage the profile when this is `True`, but otherwise won't use it to actually sign the binary. Instead Bazel will perform the code signing with the file set to `provisioning_profile`. Using rules_apple's `local_provisioning_profile` as the target set to `provisioning_profile` will then allow Bazel to code sign with the Xcode managed profile.   | Boolean | required |  |
| <a id="xcode_provisioning_profile-profile_name"></a>profile_name |  When `managed_by_xcode` is `False`, the `PROVISIONING_PROFILE_SPECIFIER` Xcode build setting will be set to this value. If this is `None` (the default), and `provisioning_profile` returns the `AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does), then `AppleProvisioningProfileInfo.profile_name` will be used instead.   | String | optional |  `""`  |
| <a id="xcode_provisioning_profile-provisioning_profile"></a>provisioning_profile |  The `File` that Bazel will use when code signing. If the target returns the `AppleProvisioningProfileInfo` provider (as `local_provisioning_profile` does), then it will provide default values for `profile_name` and `team_id`.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
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
XcodeProjAutomaticTargetProcessingInfo(<a href="#XcodeProjAutomaticTargetProcessingInfo-app_icons">app_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-args">args</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bundle_id">bundle_id</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files">collect_uncategorized_files</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-deps">deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-entitlements">entitlements</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-env">env</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-extra_files">extra_files</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-implementation_deps">implementation_deps</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-is_header_only_library">is_header_only_library</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-is_mixed_language">is_mixed_language</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-is_supported">is_supported</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-is_top_level">is_top_level</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-label">label</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-link_mnemonics">link_mnemonics</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs">non_arc_srcs</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-provisioning_profile">provisioning_profile</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-srcs">srcs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-target_type">target_type</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or its dependencies are processed,
return an `XcodeProjInfo` provider instance instead.

> [!WARNING]
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjAutomaticTargetProcessingInfo-app_icons"></a>app_icons |  An attribute name (or `None`) to collect the application icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-args"></a>args |  A `List` (or `None`) representing the command line arguments that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bundle_id"></a>bundle_id |  An attribute name (or `None`) to collect the bundle id string from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-collect_uncategorized_files"></a>collect_uncategorized_files |  Whether to collect files from uncategorized attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-deps"></a>deps |  A sequence of attribute names to collect `Target`s from for `deps`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-entitlements"></a>entitlements |  An attribute name (or `None`) to collect `File`s from for the `entitlements`-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-env"></a>env |  A `dict` representing the environment variables that this target should execute or test with.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-extra_files"></a>extra_files |  A sequence of attribute names to collect `File`s from to include in the project, which don't fall under other categorized attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-implementation_deps"></a>implementation_deps |  A sequence of attribute names to collect `Target`s from for `implementation_deps`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-is_header_only_library"></a>is_header_only_library |  Whether this target doesn't contain src files.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-is_mixed_language"></a>is_mixed_language |  Whether this target is a mixed-language target.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-is_supported"></a>is_supported |  Whether an Xcode target can be generated for this target. Even if this value is `False`, setting values for the other attributes can cause inputs to be collected and shown in the Xcode project.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-is_top_level"></a>is_top_level |  Whether this target is a "top-level" (e.g. bundled or executable) target.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-label"></a>label |  The effective `Label` to use for the target. This should generally be `target.label`, but in the case of skipped wrapper rules (e.g. `*_unit_test` targets), you might want to rename the target to the skipped target's label.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-link_mnemonics"></a>link_mnemonics |  A sequence of mnemonic (action) names to gather link parameters. The first action that matches any of the mnemonics is used.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs"></a>non_arc_srcs |  A sequence of attribute names to collect `File`s from for `non_arc_srcs`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-provisioning_profile"></a>provisioning_profile |  An attribute name (or `None`) to collect `File`s from for the `provisioning_profile`-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-srcs"></a>srcs |  A sequence of attribute names to collect `File`s from for `srcs`-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-target_type"></a>target_type |  See `XcodeProjInfo.target_type`.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-xcode_targets"></a>xcode_targets |  A `dict` mapping attribute names to target type strings (i.e. "resource" or "compile"). Only Xcode targets from the specified attributes with the specified target type are allowed to propagate.    |


<a id="XcodeProjInfo"></a>

## XcodeProjInfo

<pre>
XcodeProjInfo(<a href="#XcodeProjInfo-args">args</a>, <a href="#XcodeProjInfo-compilation_providers">compilation_providers</a>, <a href="#XcodeProjInfo-direct_dependencies">direct_dependencies</a>, <a href="#XcodeProjInfo-envs">envs</a>, <a href="#XcodeProjInfo-extension_infoplists">extension_infoplists</a>,
              <a href="#XcodeProjInfo-focused_labels">focused_labels</a>, <a href="#XcodeProjInfo-focused_library_deps">focused_library_deps</a>, <a href="#XcodeProjInfo-framework_product_mappings">framework_product_mappings</a>, <a href="#XcodeProjInfo-hosted_targets">hosted_targets</a>,
              <a href="#XcodeProjInfo-inputs">inputs</a>, <a href="#XcodeProjInfo-label">label</a>, <a href="#XcodeProjInfo-lldb_context">lldb_context</a>, <a href="#XcodeProjInfo-mergable_xcode_library_targets">mergable_xcode_library_targets</a>, <a href="#XcodeProjInfo-mergeable_infos">mergeable_infos</a>,
              <a href="#XcodeProjInfo-merged_target_ids">merged_target_ids</a>, <a href="#XcodeProjInfo-non_top_level_rule_kind">non_top_level_rule_kind</a>, <a href="#XcodeProjInfo-outputs">outputs</a>, <a href="#XcodeProjInfo-platforms">platforms</a>, <a href="#XcodeProjInfo-resource_bundle_ids">resource_bundle_ids</a>,
              <a href="#XcodeProjInfo-swift_debug_settings">swift_debug_settings</a>, <a href="#XcodeProjInfo-target_output_groups">target_output_groups</a>, <a href="#XcodeProjInfo-target_type">target_type</a>, <a href="#XcodeProjInfo-top_level_focused_deps">top_level_focused_deps</a>,
              <a href="#XcodeProjInfo-top_level_swift_debug_settings">top_level_swift_debug_settings</a>, <a href="#XcodeProjInfo-transitive_dependencies">transitive_dependencies</a>, <a href="#XcodeProjInfo-xcode_target">xcode_target</a>, <a href="#XcodeProjInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides information needed to generate an Xcode project.

> [!WARNING]
> This provider currently has an unstable API and may change in the future. If
> you are using this provider, please let us know so we can prioritize
> stabilizing it.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjInfo-args"></a>args |  A `depset` of `struct`s with `id` and `arg` fields. The `id` field is the target ID (see `xcode_target.id`) of the target and `arg` values for the target (if applicable).    |
| <a id="XcodeProjInfo-compilation_providers"></a>compilation_providers |  A value from `compilation_providers.{collect,merge}`.    |
| <a id="XcodeProjInfo-direct_dependencies"></a>direct_dependencies |  A `depset` of target IDs (see `xcode_target.id`) that this target directly depends on.    |
| <a id="XcodeProjInfo-envs"></a>envs |  A `depset` of `struct`s with `id` and `env` fields. The `id` field is the target ID (see `xcode_target.id`) of the target and `env` values for the target (if applicable).    |
| <a id="XcodeProjInfo-extension_infoplists"></a>extension_infoplists |  A `depset` of `struct`s with `id` and `infoplist` fields. The `id` field is the target ID (see `xcode_target.id`) of the application extension target. The `infoplist` field is a `File` for the Info.plist for the target.    |
| <a id="XcodeProjInfo-focused_labels"></a>focused_labels |  A `depset` of label strings of focused targets. This will include the current target (if focused) and any focused dependencies of the current target.    |
| <a id="XcodeProjInfo-focused_library_deps"></a>focused_library_deps |  A `depset` of `struct`s with `id` and `label` fields. The `id` field is the target ID (see `xcode_target.id`) of a focused library target. The `label` field is the string label of the same target.<br><br>This field represents the transitive focused library dependencies of the target. Top-level targets use this field to determine the value of `top_level_focused_deps`. They also reset this value.    |
| <a id="XcodeProjInfo-framework_product_mappings"></a>framework_product_mappings |  A `depset` of `(linker_path, product_path)` `tuple`s. `linker_path` is the `.framework/Executable` path used when linking to a framework. `product_path` is the path to a built `.framework` product. In particular, `product_path` can have a fully fleshed out framework, including resources, while `linker_path` will most likely only have a symlink to a `.dylib` in it.    |
| <a id="XcodeProjInfo-hosted_targets"></a>hosted_targets |  A `depset` of `struct`s with `host` and `hosted` fields. The `host` field is the target ID (see `xcode_target.id`) of the hosting target. The `hosted` field is the target ID of the hosted target.    |
| <a id="XcodeProjInfo-inputs"></a>inputs |  A value from `input_files.collect`/`inputs_files.merge`, that contains information related to all of the input `File`s for the project collected so far. It also includes information related to "extra files" that should be added to the Xcode project, but are not associated with any targets.    |
| <a id="XcodeProjInfo-label"></a>label |  The `Label` of the target.    |
| <a id="XcodeProjInfo-lldb_context"></a>lldb_context |  A value from `lldb_context.collect`.    |
| <a id="XcodeProjInfo-mergable_xcode_library_targets"></a>mergable_xcode_library_targets |  A `depset` of target IDs (see `xcode_target.id`). Each represents a target that can potentially merge into a top-level target (to be decided by the top-level target).    |
| <a id="XcodeProjInfo-mergeable_infos"></a>mergeable_infos |  A `depset` of `structs`s. Each contains information about a target that can potentially merge into a top-level target (to be decided by the top-level target).    |
| <a id="XcodeProjInfo-merged_target_ids"></a>merged_target_ids |  A `depset` of `tuple`s. The first element is the target ID (see `xcode_target.id`) of the target being merged into. The second element is a list of target IDs that have been merged into the target referenced by the first element.    |
| <a id="XcodeProjInfo-non_top_level_rule_kind"></a>non_top_level_rule_kind |  If this target is not a top-level target, this is the value from `ctx.rule.kind`, otherwise it is `None`. Top-level targets are targets that are valid to be listed in the `top_level_targets` attribute of `xcodeproj`. In particular, this means that they aren't library targets, which when specified in `top_level_targets` cause duplicate mis-configured targets to be added to the project.    |
| <a id="XcodeProjInfo-outputs"></a>outputs |  A value from `output_files.collect`/`output_files.merge`, that contains information about the output files for this target and its transitive dependencies.    |
| <a id="XcodeProjInfo-platforms"></a>platforms |  A `depset` of `apple_platform`s that this target and its transitive dependencies are built for.    |
| <a id="XcodeProjInfo-resource_bundle_ids"></a>resource_bundle_ids |  A `depset` of `tuple`s mapping target ID (see `xcode_target.id`) to bundle id.    |
| <a id="XcodeProjInfo-swift_debug_settings"></a>swift_debug_settings |  A `depset` of swift_debug_settings `File`s, produced by `pbxproj_partials.write_target_build_settings`.    |
| <a id="XcodeProjInfo-target_output_groups"></a>target_output_groups |  A value from `output_groups.collect`/`output_groups.merge`, that contains information related to BwB mode output groups.    |
| <a id="XcodeProjInfo-target_type"></a>target_type |  A string that categorizes the type of the current target. This will be one of "compile", "resources", or `None`. Even if this target doesn't produce an Xcode target, it can still have a non-`None` value for this field.    |
| <a id="XcodeProjInfo-top_level_focused_deps"></a>top_level_focused_deps |  A `depset` of `struct`s with `id`, `label`, and `deps` fields. The `id` field is the target ID (see `xcode_target.id`) of a top-level target. The `label` field is the string label of the same target. The `deps` field is a `tuple` (used as a frozen sequence) of values as stored in `focused_library_deps`.<br><br>This field is used to allow custom schemes (see the `xcschemes` module) to include the correct versions of library targets.    |
| <a id="XcodeProjInfo-top_level_swift_debug_settings"></a>top_level_swift_debug_settings |  A `depset` of `tuple`s of an LLDB context key and swift_debug_settings `File`s, produced by `pbxproj_partials.write_target_build_settings`. This will be an empty `depset` for non-top-level targets.    |
| <a id="XcodeProjInfo-transitive_dependencies"></a>transitive_dependencies |  A `depset` of target IDs (see `xcode_target.id`) that this target transitively depends on.    |
| <a id="XcodeProjInfo-xcode_target"></a>xcode_target |  A value from `xcode_targets.make` if this target can produce an Xcode target.    |
| <a id="XcodeProjInfo-xcode_targets"></a>xcode_targets |  A `depset` of values from `xcode_targets.make`, which potentially will become targets in the Xcode project.    |


# Aspect Hints

Aspect hints that can be used to provide additional information during project generation.

<a id="xcodeproj_extra_files"></a>

## xcodeproj_extra_files

<pre>
xcodeproj_extra_files(<a href="#xcodeproj_extra_files-name">name</a>, <a href="#xcodeproj_extra_files-files">files</a>)
</pre>

This rule is used to surface extra files that should be included in the Xcode
project navigator, but otherwise aren't inputs to a target. The provider
created by this rule should be attached to the related target via an aspect
hint.

**EXAMPLE**

```starlark
load("@rules_xcodeproj//xcodeproj:xcodeproj_extra_files.bzl", "xcodeproj_extra_files")

swift_library(
    ...
    aspect_hints = [":library_extra_files"],
    ...
)

# Display the README.md file located alongside the Swift library in Xcode
xcodeproj_extra_files(
    name = "library_extra_files",
    files = ["README.md"],
)
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="xcodeproj_extra_files-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="xcodeproj_extra_files-files"></a>files |  The list of extra files to surface in the Xcode navigator.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |



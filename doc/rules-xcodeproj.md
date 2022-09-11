<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public rules, macros, and libraries.

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

## Example

```python
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
| <a id="xcode_provisioning_profile-profile_name"></a>profile_name |  When <code>managed_by_xcode</code> is <code>False</code>, the <code>PROVISIONING_PROFILE_SPECIFIER</code> Xcode build setting will be set to this value. If this is <code>None</code> (the default), and <code>provisioning_profile</code> returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then <code>AppleProvisioningProfileInfo.profile_name</code> will be used instead.   | String | optional | "" |
| <a id="xcode_provisioning_profile-provisioning_profile"></a>provisioning_profile |  The <code>File</code> that Bazel will use when code signing. If the target returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then it will provide default values for <code>profile_name</code> and <code>team_id</code>.<br><br>When <code>xcodeproj.build_mode = "xcode"</code>, the actual file isn't used directly by Xcode, but in order to satisfy Bazel constraints this can't be <code>None</code>.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="xcode_provisioning_profile-team_id"></a>team_id |  The <code>DEVELOPER_TEAM</code> Xcode build setting will be set to this value. If this is <code>None</code> (the default), and <code>provisioning_profile</code> returns the <code>AppleProvisioningProfileInfo</code> provider (as <code>local_provisioning_profile</code> does), then <code>AppleProvisioningProfileInfo.team_id</code> will be used instead.<br><br><code>DEVELOPER_TEAM</code> is needed when <code>xcodeproj.build_mode = "xcode"</code>.   | String | optional | "" |


<a id="XcodeProjAutomaticTargetProcessingInfo"></a>

## XcodeProjAutomaticTargetProcessingInfo

<pre>
XcodeProjAutomaticTargetProcessingInfo(<a href="#XcodeProjAutomaticTargetProcessingInfo-app_icons">app_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bazel_build_mode_error">bazel_build_mode_error</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bundle_id">bundle_id</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-codesignopts">codesignopts</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-deps">deps</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-entitlements">entitlements</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists">exported_symbols_lists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-infoplists">infoplists</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-launchdplists">launchdplists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs">non_arc_srcs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-pch">pch</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-provisioning_profile">provisioning_profile</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-should_generate_target">should_generate_target</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-srcs">srcs</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-target_type">target_type</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-xcode_targets">xcode_targets</a>)
</pre>

Provides needed information about a target to allow rules_xcodeproj to
automatically process it.

If you need more control over how a target or it's dependencies are processed,
return a `XcodeProjInfo` provider instance instead.


**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="XcodeProjAutomaticTargetProcessingInfo-app_icons"></a>app_icons |  An attribute name (or <code>None</code>) to collect the application icons.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bazel_build_mode_error"></a>bazel_build_mode_error |  If <code>build_mode = "bazel"</code>, then if this is non-<code>None</code>, it will be raised as an error during analysis.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-bundle_id"></a>bundle_id |  An attribute name (or <code>None</code>) to collect the bundle id string from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-codesignopts"></a>codesignopts |  An attribute name (or <code>None</code>) to collect the <code>codesignopts</code> <code>list</code> from.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-deps"></a>deps |  A sequence of attribute names to collect <code>Target</code>s from for <code>deps</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-entitlements"></a>entitlements |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>entitlements</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists"></a>exported_symbols_lists |  A sequence of attribute names to collect <code>File</code>s from for the <code>exported_symbols_lists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-infoplists"></a>infoplists |  A sequence of attribute names to collect <code>File</code>s from for the <code>infoplists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-launchdplists"></a>launchdplists |  A sequence of attribute names to collect <code>File</code>s from for the <code>launchdplists</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-non_arc_srcs"></a>non_arc_srcs |  A sequence of attribute names to collect <code>File</code>s from for <code>non_arc_srcs</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-pch"></a>pch |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>pch</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-provisioning_profile"></a>provisioning_profile |  An attribute name (or <code>None</code>) to collect <code>File</code>s from for the <code>provisioning_profile</code>-like attribute.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-should_generate_target"></a>should_generate_target |  Whether or an Xcode target should be generated for this target. Even if this value is <code>False</code>, setting values for the other attributes can cause inputs to be collected and shown in the Xcode project.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-srcs"></a>srcs |  A sequence of attribute names to collect <code>File</code>s from for <code>srcs</code>-like attributes.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-target_type"></a>target_type |  See <code>XcodeProjInfo.target_type</code>.    |
| <a id="XcodeProjAutomaticTargetProcessingInfo-xcode_targets"></a>xcode_targets |  A <code>dict</code> mapping attribute names to target type strings (i.e. "resource" or "compile"). Only Xcode targets from the specified attributes with the specified target type are allowed to propagate.    |


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


<a id="xcode_schemes.scheme"></a>

## xcode_schemes.scheme

<pre>
xcode_schemes.scheme(<a href="#xcode_schemes.scheme-name">name</a>, <a href="#xcode_schemes.scheme-build_action">build_action</a>, <a href="#xcode_schemes.scheme-test_action">test_action</a>, <a href="#xcode_schemes.scheme-launch_action">launch_action</a>)
</pre>

Returns a `struct` representing an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.scheme-name"></a>name |  The user-visible name for the scheme as a <code>string</code>.   |  none |
| <a id="xcode_schemes.scheme-build_action"></a>build_action |  Optional. A value returned by <code>xcode_schemes.build_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-test_action"></a>test_action |  Optional. A value returned by <code>xcode_schemes.test_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-launch_action"></a>launch_action |  Optional. A value returned by <code>xcode_schemes.launch_action</code>.   |  <code>None</code> |

**RETURNS**

A `struct` representing an Xcode scheme.


<a id="xcode_schemes.build_action"></a>

## xcode_schemes.build_action

<pre>
xcode_schemes.build_action(<a href="#xcode_schemes.build_action-targets">targets</a>)
</pre>

Constructs a build action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.build_action-targets"></a>targets |  A <code>sequence</code> of elements that are either <code>struct</code> values as created by <code>xcode_schemes.build_target</code>, or a target label as a <code>string</code> value.   |  none |

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


<a id="xcode_schemes.test_action"></a>

## xcode_schemes.test_action

<pre>
xcode_schemes.test_action(<a href="#xcode_schemes.test_action-targets">targets</a>, <a href="#xcode_schemes.test_action-args">args</a>, <a href="#xcode_schemes.test_action-env">env</a>, <a href="#xcode_schemes.test_action-expand_variables_based_on">expand_variables_based_on</a>)
</pre>

Constructs a test action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.test_action-targets"></a>targets |  A <code>sequence</code> of target labels as <code>string</code> values.   |  none |
| <a id="xcode_schemes.test_action-args"></a>args |  Optional. A <code>list</code> of <code>string</code> arguments that should be passed to the target when executed.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-env"></a>env |  Optional. A <code>dict</code> of <code>string</code> values that will be set as environment variables when the target is executed.   |  <code>None</code> |
| <a id="xcode_schemes.test_action-expand_variables_based_on"></a>expand_variables_based_on |  Optional. One of the specified test target labels. If no value is provided, one of the test targets will be selected. If no expansion context is desired, use the <code>string</code> value <code>none</code>.   |  <code>None</code> |

**RETURNS**

A `struct` representing a test action.


<a id="xcode_schemes.launch_action"></a>

## xcode_schemes.launch_action

<pre>
xcode_schemes.launch_action(<a href="#xcode_schemes.launch_action-target">target</a>, <a href="#xcode_schemes.launch_action-args">args</a>, <a href="#xcode_schemes.launch_action-env">env</a>)
</pre>

Constructs a launch action for an Xcode scheme.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.launch_action-target"></a>target |  A target label as a <code>string</code> value.   |  none |
| <a id="xcode_schemes.launch_action-args"></a>args |  Optional. A <code>list</code> of <code>string</code> arguments that should be passed to the target when executed.   |  <code>None</code> |
| <a id="xcode_schemes.launch_action-env"></a>env |  Optional. A <code>dict</code> of <code>string</code> values that will be set as environment variables when the target is executed.   |  <code>None</code> |

**RETURNS**

A `struct` representing a launch action.


<a id="xcode_schemes.focus_schemes"></a>

## xcode_schemes.focus_schemes

<pre>
xcode_schemes.focus_schemes(<a href="#xcode_schemes.focus_schemes-schemes">schemes</a>, <a href="#xcode_schemes.focus_schemes-focused_targets">focused_targets</a>)
</pre>

Filter/adjust a `sequence` of schemes to only include focused targets.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.focus_schemes-schemes"></a>schemes |  A <code>sequence</code> of values returned by <code>xcode_schemes.scheme</code>.   |  none |
| <a id="xcode_schemes.focus_schemes-focused_targets"></a>focused_targets |  A <code>sequence</code> of <code>string</code> values representing Bazel labels of focused targets.   |  none |

**RETURNS**

A `sequence` of values returned by `xcode_schemes.scheme`.
  Will only include schemes that have at least one target in
  `focused_targets`. Some actions might be removed if they reference
  unfocused targets.


<a id="xcode_schemes.unfocus_schemes"></a>

## xcode_schemes.unfocus_schemes

<pre>
xcode_schemes.unfocus_schemes(<a href="#xcode_schemes.unfocus_schemes-schemes">schemes</a>, <a href="#xcode_schemes.unfocus_schemes-unfocused_targets">unfocused_targets</a>)
</pre>

Filter/adjust a `sequence` of schemes to exclude unfocused targets.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_schemes.unfocus_schemes-schemes"></a>schemes |  A <code>sequence</code> of values returned by <code>xcode_schemes.scheme</code>.   |  none |
| <a id="xcode_schemes.unfocus_schemes-unfocused_targets"></a>unfocused_targets |  A <code>sequence</code> of <code>string</code> values representing Bazel labels of unfocused targets.   |  none |

**RETURNS**

A `sequence` of values returned by `xcode_schemes.scheme`.
  Will only include schemes that have at least one target not in
  `unfocused_targets`. Some actions might be removed if they reference
  unfocused targets.


<a id="xcodeproj"></a>

## xcodeproj

<pre>
xcodeproj(<a href="#xcodeproj-name">name</a>, <a href="#xcodeproj-archived_bundles_allowed">archived_bundles_allowed</a>, <a href="#xcodeproj-bazel_path">bazel_path</a>, <a href="#xcodeproj-build_mode">build_mode</a>, <a href="#xcodeproj-config">config</a>, <a href="#xcodeproj-focused_targets">focused_targets</a>,
          <a href="#xcodeproj-ios_device_cpus">ios_device_cpus</a>, <a href="#xcodeproj-ios_simulator_cpus">ios_simulator_cpus</a>, <a href="#xcodeproj-project_name">project_name</a>, <a href="#xcodeproj-scheme_autogeneration_mode">scheme_autogeneration_mode</a>, <a href="#xcodeproj-schemes">schemes</a>,
          <a href="#xcodeproj-top_level_targets">top_level_targets</a>, <a href="#xcodeproj-tvos_device_cpus">tvos_device_cpus</a>, <a href="#xcodeproj-tvos_simulator_cpus">tvos_simulator_cpus</a>, <a href="#xcodeproj-unfocused_targets">unfocused_targets</a>,
          <a href="#xcodeproj-watchos_device_cpus">watchos_device_cpus</a>, <a href="#xcodeproj-watchos_simulator_cpus">watchos_simulator_cpus</a>, <a href="#xcodeproj-kwargs">kwargs</a>)
</pre>

Creates an `.xcodeproj` file in the workspace when run.

This is a wrapper macro for the
[actual `xcodeproj` rule](../xcodeproj/internal/xcodeproj_rule.bzl), which
can't be used directly. All public API is documented below. The `kwargs`
argument will pass forward values for globally available attributes (e.g.
`visibility`, `features`, etc.) to the underlying rule.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcodeproj-name"></a>name |  A unique name for this target.   |  none |
| <a id="xcodeproj-archived_bundles_allowed"></a>archived_bundles_allowed |  This argument is deprecated and is now a no-op. It will be removed in a future release. Adjust the setting of <code>--define=apple.experimental.tree_artifact_outputs</code> on <code>build:rules_xcodeproj</code> in your <code>.bazelrc</code> or <code>xcodeproj.bazelrc</code> file.   |  <code>None</code> |
| <a id="xcodeproj-bazel_path"></a>bazel_path |  Optional. The path the <code>bazel</code> binary or wrapper script. If the path is relative it will be resolved using the <code>PATH</code> environment variable (which is set to <code>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</code> in Xcode). If you want to specify a path to a workspace-relative binary, you must prepend the path with <code>./</code> (e.g. <code>"./bazelw"</code>).   |  <code>"bazel"</code> |
| <a id="xcodeproj-build_mode"></a>build_mode |  Optional. The build mode the generated project should use.<br><br>If this is set to <code>"xcode"</code>, the project will use the Xcode build system to build targets. Generated files and unfocused targets (see the <code>focused_targets</code> and <code>unfocused_targets</code> arguments) will be built with Bazel.<br><br>If this is set to <code>"bazel"</code>, the project will use Bazel to build targets, inside of Xcode. The Xcode build system still unavoidably orchestrates some things at a high level.   |  <code>"bazel"</code> |
| <a id="xcodeproj-config"></a>config |  Optional. The Bazel config to use when generating the project or invoking <code>bazel</code> inside of Xcode. This is the basename of multiple configs. For example, if this is set to <code>"projectx_xcodeproj"</code>, then the following configs will be available for you to adjust in your <code>.bazelrc</code> file: <code>projectx_xcodeproj</code>, <code>projectx_xcodeproj_generator</code>, <code>rules_xcodeproj_indexbuild</code>, and <code>rules_xcodeproj_swiftuipreviews</code>.<br><br>See the [usage guide](usage.md#bazel-configs) for more information about adjusting Bazel configs.   |  <code>"rules_xcodeproj"</code> |
| <a id="xcodeproj-focused_targets"></a>focused_targets |  Optional. A <code>list</code> of target labels as <code>string</code> values. If specified, only these targets will be included in the generated project; all other targets will be excluded, as if they were listed explicitly in the <code>unfocused_targets</code> argument. The labels must match transitive dependencies of the targets specified in the <code>top_level_targets</code> argument.   |  <code>[]</code> |
| <a id="xcodeproj-ios_device_cpus"></a>ios_device_cpus |  Optional. The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't iOS targets.   |  <code>"arm64"</code> |
| <a id="xcodeproj-ios_simulator_cpus"></a>ios_simulator_cpus |  Optional. The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't iOS targets.   |  <code>None</code> |
| <a id="xcodeproj-project_name"></a>project_name |  Optional. The name to use for the <code>.xcodeproj</code> file. If not specified, the value of the <code>name</code> argument is used.   |  <code>None</code> |
| <a id="xcodeproj-scheme_autogeneration_mode"></a>scheme_autogeneration_mode |  Optional. Specifies how Xcode schemes are automatically generated.   |  <code>"auto"</code> |
| <a id="xcodeproj-schemes"></a>schemes |  Optional. A <code>list</code> of values returned by <code>xcode_schemes.scheme</code>. Target labels listed in the schemes need to be from the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument. This and the <code>scheme_autogeneration_mode</code> argument together customize how schemes for those targets are generated.   |  <code>[]</code> |
| <a id="xcodeproj-top_level_targets"></a>top_level_targets |  A <code>list</code> of a list of top-level targets. Each target can be specified as either a <code>Label</code> (or label-like <code>string</code>), or a value returned by <code>top_level_target</code>.   |  none |
| <a id="xcodeproj-tvos_device_cpus"></a>tvos_device_cpus |  Optional. The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't tvOS targets.   |  <code>"arm64"</code> |
| <a id="xcodeproj-tvos_simulator_cpus"></a>tvos_simulator_cpus |  Optional. The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't tvOS targets.   |  <code>None</code> |
| <a id="xcodeproj-unfocused_targets"></a>unfocused_targets |  Optional. A <code>list</code> of target labels as <code>string</code> values. Any targets in the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with a matching label will be excluded from the generated project. This overrides any targets specified in the <code>focused_targets</code> argument.   |  <code>[]</code> |
| <a id="xcodeproj-watchos_device_cpus"></a>watchos_device_cpus |  Optional. The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"device"</code> <code>target_environment</code>, even if they aren't watchOS targets.   |  <code>"arm64_32"</code> |
| <a id="xcodeproj-watchos_simulator_cpus"></a>watchos_simulator_cpus |  Optional. The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>top_level_targets</code> argument with the <code>"simulator"</code> <code>target_environment</code>, even if they aren't watchOS targets.   |  <code>None</code> |
| <a id="xcodeproj-kwargs"></a>kwargs |  Additional arguments to pass to the underlying <code>xcodeproj</code> rule specified by <code>xcodeproj_rule</code>.   |  none |



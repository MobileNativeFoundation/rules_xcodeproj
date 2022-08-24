<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public rules, macros, and libraries.

<a id="xcodeproj"></a>

## xcodeproj

<pre>
xcodeproj(<a href="#xcodeproj-name">name</a>, <a href="#xcodeproj-archived_bundles_allowed">archived_bundles_allowed</a>, <a href="#xcodeproj-bazel_path">bazel_path</a>, <a href="#xcodeproj-build_mode">build_mode</a>, <a href="#xcodeproj-focused_targets">focused_targets</a>, <a href="#xcodeproj-project_name">project_name</a>,
          <a href="#xcodeproj-scheme_autogeneration_mode">scheme_autogeneration_mode</a>, <a href="#xcodeproj-schemes_json">schemes_json</a>, <a href="#xcodeproj-top_level_targets">top_level_targets</a>, <a href="#xcodeproj-toplevel_cache_buster">toplevel_cache_buster</a>,
          <a href="#xcodeproj-unfocused_targets">unfocused_targets</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="xcodeproj-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="xcodeproj-archived_bundles_allowed"></a>archived_bundles_allowed |  -   | Boolean | optional | False |
| <a id="xcodeproj-bazel_path"></a>bazel_path |  -   | String | optional | "bazel" |
| <a id="xcodeproj-build_mode"></a>build_mode |  -   | String | optional | "xcode" |
| <a id="xcodeproj-focused_targets"></a>focused_targets |  -   | List of strings | optional | [] |
| <a id="xcodeproj-project_name"></a>project_name |  -   | String | optional | "" |
| <a id="xcodeproj-scheme_autogeneration_mode"></a>scheme_autogeneration_mode |  Specifies how Xcode schemes are automatically generated.   | String | optional | "auto" |
| <a id="xcodeproj-schemes_json"></a>schemes_json |  A JSON string representing a list of Xcode schemes to create.   | String | optional | "" |
| <a id="xcodeproj-top_level_targets"></a>top_level_targets |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="xcodeproj-toplevel_cache_buster"></a>toplevel_cache_buster |  For internal use only. Do not set this value yourself.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="xcodeproj-unfocused_targets"></a>unfocused_targets |  -   | List of strings | optional | [] |


<a id="XcodeProjAutomaticTargetProcessingInfo"></a>

## XcodeProjAutomaticTargetProcessingInfo

<pre>
XcodeProjAutomaticTargetProcessingInfo(<a href="#XcodeProjAutomaticTargetProcessingInfo-app_icons">app_icons</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bazel_build_mode_error">bazel_build_mode_error</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-bundle_id">bundle_id</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-codesignopts">codesignopts</a>,
                                       <a href="#XcodeProjAutomaticTargetProcessingInfo-entitlements">entitlements</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-exported_symbols_lists">exported_symbols_lists</a>, <a href="#XcodeProjAutomaticTargetProcessingInfo-infoplists">infoplists</a>,
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
| <a id="xcode_schemes.scheme-build_action"></a>build_action |  Optional. A <code>struct</code> as returned by <code>xcode_schemes.build_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-test_action"></a>test_action |  Optional. A <code>struct</code> as returned by <code>xcode_schemes.test_action</code>.   |  <code>None</code> |
| <a id="xcode_schemes.scheme-launch_action"></a>launch_action |  Optional. A <code>struct</code> as returned by <code>xcode_schemes.launch_action</code>.   |  <code>None</code> |

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
| <a id="xcode_schemes.build_target-build_for"></a>build_for |  Optional. The settings that dictate when Xcode will build the target. It is a <code>struct</code> as returned by <code>xcode_schemes.build_for</code>.   |  <code>None</code> |

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
| <a id="xcode_schemes.focus_schemes-schemes"></a>schemes |  A <code>sequence</code> of <code>struct</code> values as returned by <code>xcode_schemes.scheme</code>.   |  none |
| <a id="xcode_schemes.focus_schemes-focused_targets"></a>focused_targets |  A <code>sequence</code> of <code>string</code> values representing Bazel labels of focused targets.   |  none |

**RETURNS**

A `sequence` of `struct` values as returned by `xcode_schemes.scheme`.
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
| <a id="xcode_schemes.unfocus_schemes-schemes"></a>schemes |  A <code>sequence</code> of <code>struct</code> values as returned by <code>xcode_schemes.scheme</code>.   |  none |
| <a id="xcode_schemes.unfocus_schemes-unfocused_targets"></a>unfocused_targets |  A <code>sequence</code> of <code>string</code> values representing Bazel labels of unfocused targets.   |  none |

**RETURNS**

A `sequence` of `struct` values as returned by `xcode_schemes.scheme`.
  Will only include schemes that have at least one target not in
  `unfocused_targets`. Some actions might be removed if they reference
  unfocused targets.



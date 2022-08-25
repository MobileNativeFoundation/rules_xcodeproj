<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public evolving/experimental rules, macros, and libraries.

<a id="device_and_simulator"></a>

## device_and_simulator

<pre>
device_and_simulator(<a href="#device_and_simulator-name">name</a>, <a href="#device_and_simulator-device_only_targets">device_only_targets</a>, <a href="#device_and_simulator-ios_device_cpus">ios_device_cpus</a>, <a href="#device_and_simulator-ios_simulator_cpus">ios_simulator_cpus</a>,
                     <a href="#device_and_simulator-simulator_only_targets">simulator_only_targets</a>, <a href="#device_and_simulator-targets">targets</a>, <a href="#device_and_simulator-tvos_device_cpus">tvos_device_cpus</a>, <a href="#device_and_simulator-tvos_simulator_cpus">tvos_simulator_cpus</a>,
                     <a href="#device_and_simulator-watchos_device_cpus">watchos_device_cpus</a>, <a href="#device_and_simulator-watchos_simulator_cpus">watchos_simulator_cpus</a>)
</pre>

The `device_and_simulator` rule is deprecated and will be removed in a future rules_xcodeproj release. Please use the `top_level_target()` function with `xcodeproj.top_level_targets` instead.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="device_and_simulator-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="device_and_simulator-device_only_targets"></a>device_only_targets |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="device_and_simulator-ios_device_cpus"></a>ios_device_cpus |  The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute, even if they aren't iOS targets.   | String | optional | "arm64" |
| <a id="device_and_simulator-ios_simulator_cpus"></a>ios_simulator_cpus |  The value to use for <code>--ios_multi_cpus</code> when building the transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute, even if they aren't iOS targets.   | String | optional | "" |
| <a id="device_and_simulator-simulator_only_targets"></a>simulator_only_targets |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="device_and_simulator-targets"></a>targets |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="device_and_simulator-tvos_device_cpus"></a>tvos_device_cpus |  The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute, even if they aren't tvOS targets.   | String | optional | "arm64" |
| <a id="device_and_simulator-tvos_simulator_cpus"></a>tvos_simulator_cpus |  The value to use for <code>--tvos_cpus</code> when building the transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>sim_arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute, even if they aren't tvOS targets.   | String | optional | "" |
| <a id="device_and_simulator-watchos_device_cpus"></a>watchos_device_cpus |  The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute.<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>simulator_only_targets</code> attribute, or the simulator-based targets in the <code>targets</code> attribute, even if they aren't watchOS targets.   | String | optional | "arm64_32" |
| <a id="device_and_simulator-watchos_simulator_cpus"></a>watchos_simulator_cpus |  The value to use for <code>--watchos_cpus</code> when building the transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute.<br><br>If no value is specified, it defaults to the simulator cpu that goes with <code>--host_cpu</code> (i.e. <code>arm64</code> on Apple Silicon and <code>x86_64</code> on Intel).<br><br>**Warning:** Changing this value will affect the Starlark transition hash of all transitive dependencies of the targets specified in the <code>device_only_targets</code> attribute, or the device-based targets in the <code>targets</code> attribute, even if they aren't watchOS targets.   | String | optional | "" |


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



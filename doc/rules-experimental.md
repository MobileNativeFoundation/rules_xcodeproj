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



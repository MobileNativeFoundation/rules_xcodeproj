# Custom Xcode schemes

> **Last Updated: July 29, 2022**

This document is a proposal for how custom Xcode schemes can be defined and
implemented in `rules_xcodeproj`.

## Contents

* [Automatic scheme generation](#automatic-scheme-generation)
* [Introduction of custom Xcode schemes](#introduction-of-custom-xcode-schemes)
  * [Defining a simple Xcode scheme](#defining-a-simple-xcode-scheme)
  * [Specifying a launch target](#specifying-a-launch-target)
  * [Specifying launch arguments, environment variables and a custom working directory](#specifying-launch-arguments-environment-variables-and-a-custom-working-directory)
    * [Note about working directory support](#note-about-working-directory-support)
* [Introduction of scheme auto-generation Mode](#introduction-of-scheme-auto-generation-mode)
* [Implementation changes](#implementation-changes)
  * [`xcode_schemes` module](#xcode_schemes-module)
  * [Changes to `xcodeproj` rule](#changes-to-_xcodeproj-rule)
    * [`scheme_autogeneration_mode` attribute](#scheme_autogeneration_mode-attribute)
    * [`schemes` attribute](#schemes-attribute)
  * [Changes to `xcodeproj` macro](#changes-to-xcodeproj-macro)
    * [Top-level library target](#top-level-library-target)
    * [Collecting targets from schemes](#collecting-targets-from-schemes)
* [Configuration and target selection in schemes](#configuration-and-target-selection-in-schemes)
* [Build for configuration logic](#build-for-configuration-logic)
* [Outstanding questions](#outstanding-questions)

## Automatic scheme generation

As of this writing, the `rules_xcodeproj` ruleset generates an Xcode scheme for
every buildable target provided to the `xcodeproj` rule. This allows a client to
quickly define an `xcodeproj` target and generate an Xcode project.

Let's start with an example.

```python
# Assumptions
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/Foo:Foo - swift_library, a dependency of //Sources/FooTests:FooTests

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    targets = [
        "//Tests/FooTests",
    ],
)
```

The above declaration generates two schemes: `Foo` and
`FooTests.__internal__.__test_bundle`. The `Foo` scheme contains configuration
that builds `//Sources/Foo`, but has no configuration for test, launch or any of
the other actions. The `FooTests.__internal__.__test_bundle` scheme contains
configuration that builds `//Tests/FooTests` and executes `//Tests/FooTests`
when testing is requested.

## Introduction of custom Xcode schemes

A new Starlark module called, `xcode_schemes`, provides functions for defining
custom, Xcode schemes.

### Defining a simple Xcode scheme

Building on the previous example, let's define a scheme that combines the two
targets, `//Sources/Foo` and `//Tests/FooTests`.

```python
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Foo Module",
        build_action = xcode_schemes.build_action(["//Sources/Foo"]),
        test_action = xcode_schemes.test_action(["//Tests/FooTests"]),
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

The `xcode_schemes.scheme` function call defines a scheme with a user visible
name of `Foo Module`. It is configured to build `//Sources/Foo` and
`//Tests/FooTests`. (Targets listed in the test action and launch action are
automatically added to the build action.) The scheme is also configured to
execute the `//Tests/FooTests` target when testing is requested.

The result of the function is wrapped in a `list` and passed to the `schemes`
parameter of the `xcodeproj` macro.

### Specifying a launch target

Let's continue our example. We will add an `ios_application` and a `ios_ui_test`
to the mix.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Foo Module",
        build_action = xcode_schemes.build_action(["//Sources/Foo"]),
        test_action = xcode_schemes.test_action(["//Tests/FooTests"]),
    ),
    xcode_schemes.scheme(
        name = "My Application",
        test_action = xcode_schemes.test_action([
            "//Tests/AppUITests",
            "//Tests/FooTests",
        ]),
        launch_action = xcode_schemes.launch_action("//Sources/App"),
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

The above example adds a second scheme called `My Application`. It is configured
with two test targets and a single launch target. All three targets are
implicitly included in the build list.

### Specifying launch arguments, environment variables and a custom working directory

There are times when it is desirable to customize the launch action with
arguments, environment variables and/or a custom working directory. This can be
accomplished by specifying them as parameters to the
`xcode_schemes.launch_action` function call.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Foo Module",
        build_action = xcode_schemes.build_action(["//Sources/Foo"]),
        test_action = xcode_schemes.test_action(["//Tests/FooTests"]),
    ),
    xcode_schemes.scheme(
        name = "My Application",
        test_action = xcode_schemes.test_action([
            "//Tests/AppUITests",
            "//Tests/FooTests",
        ]),
        launch_action = xcode_schemes.launch_action(
            target = "//Sources/App",
            args = [
                "--my_awesome_flag",
                "path/to/a/file.txt",
            ],
            env = {
                "RELEASE_THE_KRAKEN": "true",
            },
            working_directory = "$(PROJECT_DIR)",
        ),
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

This example is the same as the previous one except arguments, environment
variables, and a custom working directory are defined for the launch action.

#### Note about working directory support

Here is an example of a launch action with a custom working directory as written
by Xcode.

```xml
<LaunchAction
   buildConfiguration = "Debug"
   selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
   selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
   launchStyle = "0"
   useCustomWorkingDirectory = "YES"
   customWorkingDirectory = "/path/to/working_directory"
   ignoresPersistentStateOnLaunch = "NO"
   debugDocumentVersioning = "YES"
   debugServiceExtension = "internal"
   allowLocationSimulation = "YES">
   <BuildableProductRunnable
      runnableDebuggingMode = "0">
      <BuildableReference
         BuildableIdentifier = "primary"
         BlueprintIdentifier = "E3F17BE9286CBA4400756F9B"
         BuildableName = "MyCommandLine"
         BlueprintName = "MyCommandLine"
         ReferencedContainer = "container:MyCommandLine.xcodeproj">
      </BuildableReference>
   </BuildableProductRunnable>
</LaunchAction>
```

Note that the `useCustomWorkingDirectory` is set to `YES` and
`customWorkingDirectory` is set to the custom working directory value.

It appears that `tuist/XcodeProj` supports
[`useCustomWorkingDirectory`](https://github.com/tuist/XcodeProj/blob/3a93b47a34860a4d7dbcd9cc0ae8e9543c179c61/Sources/XcodeProj/Scheme/XCScheme%2BLaunchAction.swift#L45)
but does not support [`customWorkingDirectory` in the data
model](https://github.com/tuist/XcodeProj/search?q=customWorkingDirectory).

It looks like we will need to put up a PR to `tuist/XcodeProj` to add
`customWorkingDirectory`.

## Introduction of scheme auto-generation mode

With this proposal, it is now possible to control how Xcode scheme
auto-generation works using the `scheme_autogeneration_mode` attribute on
`_xcodeproj`.

__Values__
- `auto`: If no custom schemes are provided, an Xcode scheme will be created for
  every buildable target. If custom schemes are provided, no autogenerated
  schemes will be created.
- `none`: No schemes are automatically generated.
- `all`: A scheme is generated for every buildable target even if custom schemes
  are provided.
- `top_level_only`: A scheme is generated for every top-level target even if
  custom schemes are provided. A top-level target in this context is one that is
  not depended upon by any other target in the Xcode project.

The default value for `scheme_autogeneration_mode` is `auto`.

## Implementation changes

### `xcode_schemes` module

```python
def _scheme(
    name,
    build_action = None,
    test_action = None,
    launch_action = None):
    """Returns a `struct` representing an Xcode scheme.

    Args:
        name: The user-visible name for the scheme as a `string`.
        build_action: Optional. A value returned by
            `xcode_schemes.build_action`.
        test_action: Optional. A value returned by
            `xcode_schemes.test_action`.
        launch_action: Optional. A value returned by
            `xcode_schemes.launch_action`.

    Returns:
        A `struct` representing an Xcode scheme.
    """
    pass

def _build_action(targets):
    """Constructs a build action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.

    Return:
        A `struct` representing a build action.
    """
    pass

def _test_action(targets):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.

    Return:
        A `struct` representing a test action.
    """
    pass

def _launch_action(target, args = None, env = None, working_directory = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        working_directory: Optional. A `string` that will be set as the custom
            working directory in the Xcode scheme's launch action.

    Return:
        A `struct` representing a launch action.
    """
    pass

xcode_schemes = struct(
    scheme = _scheme,
    build_action = _build_action,
    test_action = _test_action,
    launch_action = _launch_action,
)

```

### Changes to `xcodeproj` rule

#### `scheme_autogeneration_mode` attribute

The `scheme_autogeneration_mode` attribute determines how Xcode scheme
auto-generation will occur. It's behavior is described in
[Introduction of scheme auto-generation mode](#introduction-of-scheme-auto-generation-mode).

#### `schemes` attribute

The `schemes` attribute accepts a `sequence` of JSON `string` values returned by
`xcode_schemes.scheme`. The values are parsed and passed along to the scheme
generation code in `rules_xcodeproj`. An Xcode scheme is generated for each
entry in the list.

### Changes to `xcodeproj` macro

The `xcodeproj` macro will gain two parameters: `targets` and `schemes`.

```python
def xcodeproj(*,
    name,
    xcodeproj_rule = _xcodeproj,
    targets = [],
    schemes = None,
    **kwargs):
    """Creates an .xcodeproj file in the workspace when run.

    Args:
        name: The name of the target.
        xcodeproj_rule: The actual `xcodeproj` rule. This is overridden during
            fixture testing. You shouldn't need to set it yourself.
        targets: Optional. A `list` of targets to be included in the Xcode
            project.
        schemes: Optional. A `list` of values returned by
            `xcode_schemes.scheme`.
        **kwargs: Additional arguments to pass to `xcodeproj_rule`.
    """
    pass
```

In addition to what the `xcodeproj` macro does today, if a value is provided for
the `schemes` parameter, the macro will:
1. Collect all of the targets listed in the test and launch actions (not the
   build action) and add them to the overall targets list.
2. Serialize the scheme `struct` values to JSON and set those values in the
   `schemes` attribute of the `xcodeproj` rule.

We only collect targets from the test action and launch action because the
target list for the `xcodeproj` macro should only contain top-level or
leaf-nodes (i.e., not depeneded upon by other targets in the Xcode project).

_NOTE: If desired, we can leave the signature of the `xcodeproj` macro as it is
today. If we go that route, we will retrieve the parameters from the `kwargs`._

#### Top-level library target

There are situations where a library target might be a top-level target (i.e.,
no test target or launch target).  To ensure that it is included in the Xcode
project properly, one will need to specify the library target in the `targets`
list for the `xcodeproj` macro and any schemes that should include it. The
following shows an example.

```python
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Foo Module",
        build_action = xcode_schemes.build_action(["//Sources/Foo"]),
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
    targets = [
        "//Sources/Foo",
    ],
)
```

#### Collecting targets from schemes

Let's look at an example that illustrates how targets are collected. The
following is the example from earlier with two schemes and some overlapping
targets.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "Foo Module",
        build_action = xcode_schemes.build_action(["//Sources/Foo"]),
        test_action = xcode_schemes.test_action(["//Tests/FooTests"]),
    ),
    xcode_schemes.scheme(
        name = "My Application",
        test_action = xcode_schemes.test_action([
            "//Tests/AppUITests",
            "//Tests/FooTests",
        ]),
        launch_action = xcode_schemes.launch_action("//Sources/App"),
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

After evaluation of the macro, the declaration for the `xcodeproj` rule will
look like the following:

```python
_xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = [
        "{...}", # JSON representation of Foo Module scheme
        "{...}", # JSON representation of My Application scheme
    ],
    # Only the top-level or leaf node targets were added to the overall targets
    # list.
    targets = [
        "//Sources/App",
        "//Tests/FooTests",
        "//Tests/AppUITests",
    ],
)
```

Note that the `targets` list is a deduplicated, sorted list of the targets that
were provided from the schemes and directly in the `targets` parameter.

The JSON representation of `Foo Module` will look like the following:

```json
{
  "name": "Foo Module",
  "build_action": {
    "targets": [
      "//Sources/Foo",
    ],
  },
  "test_action": {
    "targets": [
      "//Tests/FooTests"
    ]
  }
}
```

Note that the build action targets list contains the targets from the build
action declaration and the test action declaration.

The JSON representation of `My Application` will look like the following:

```json
{
  "name": "My Application",
  "test_action": {
    "targets": [
      "//Tests/FooTests",
      "//Tests/AppUITests"
    ]
  },
  "launch_action": {
    "target": "//Sources/App"
  }
}
```

## Configuration and target selection in schemes

Throughout this proposal, the syntax for listing targets in the schemes shows
simple Bazel target syntax. However, underneath the covers, there is some magic
that occurs.

Every Bazel target can map to one or more buildable targets inside
`rules_xcodeproj`. These buildable targets consist of the Bazel target along
with any configuration variations that are required to build any specified leaf
nodes. For instance, the configuration for a module being tested by a unit test
using the iOS simulator is different than the configuration for the module when
it is used by an iOS application targeted for a device.

To simplify the syntax for specifying targets for schemes, we have opted to
allow targets to be specified by their Bazel target only. The logic inside
`rules_xcodeproj` will select the correct configuration variant based upon the
leaf nodes that are included in the scheme.

## Build for configuration logic

Xcode schemes support configuration that dictates when a target is built. In the
`tuist/XcodeProj` data model, this is modeled under
[`XCScheme.BuildAction.Entry.BuildFor`](https://github.com/tuist/XcodeProj/blob/3a93b47a34860a4d7dbcd9cc0ae8e9543c179c61/Sources/XcodeProj/Scheme/XCScheme%2BBuildAction.swift#L8-L13).

The following will be the logic used to set the `BuildFor` for targets listed in
custom schemes:

- Anything in `test_action` gets `.testing`.
- Anything in `launch_action` or `build_action` gets
  `[.running, .profiling, .archiving, .analyzing]`.
- Thus being in both gets all of the values.

## Outstanding questions

### Do we need to support [Make variable](https://bazel.build/reference/be/make-variables) for the JSON strings provided to the `schemes` attribute?

If we do support it, it will make it difficult to specify Xcode-specific
variables (e.g. [`$(PROJECT_DIR)`](https://stackoverflow.com/questions/67235826/how-do-i-use-an-environment-variable-in-the-xcode-scheme-arguments-passed-on-lau/67235841#67235841))
in values like the custom working directory.

If we do end up adding support for
[make variable](https://bazel.build/reference/be/make-variables), I believe that
we can use [expand_make_vars](https://github.com/aspect-build/bazel-lib/blob/main/docs/expand_make_vars.md)
to implement it.

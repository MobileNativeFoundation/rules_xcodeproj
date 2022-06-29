# Custom Xcode Schemes

This document is a proposal for how custom Xcode schemes can be defined and implemented in
`rules_xcodeproj`.

## Contents

* [Automatic Scheme Generation](#automatic-scheme-generation)
* [Introduction of Custom Xcode Schemes](#introduction-of-custom-xcode-schemes)
  * [Defining a Simple Xcode Scheme](#defining-a-simple-xcode-scheme)
  * [Specifying a Launch Target](#specifying-a-launch-target)
  * [Specifying Launch Arguments and Environment Variables](#specifying-launch-arguments-and-environment-variables)
* [Introduction of Scheme Autogeneration Mode](#introduction-of-scheme-autogeneration-mode)
* [Implementation Changes](#implementation-changes)
  * [xcode\_schemes Module](#xcode_schemes-module)
  * [Changes to \_xcodeproj Rule](#changes-to-_xcodeproj-rule)
    * [scheme\_autogeneration\_mode Attribute](#scheme_autogeneration_mode-attribute)
    * [schemes Attribute](#schemes-attribute)
  * [Changes to xcodeproj Macro](#changes-to-xcodeproj-macro)
    * [Collecting Targets from Schemes](#collecting-targets-from-schemes)
* [Configuration and Target Selection in Schemes](#configuration-and-target-selection-in-schemes)
* [Outstanding Questions](#outstanding-questions)

## Automatic Scheme Generation

As of this writing, the `rules_xcodeproj` ruleset generates an Xcode scheme for every buildable
target provided to the `xcodeproj` rule. This allows a client to quickly define an `xcodeproj`
target and generate an Xcode project.

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
`FooTests.__internal__.__test_bundle`. The `Foo` scheme contains configuration that builds
`//Sources/Foo`, but has no configuration for test, launch or any of the other actions. The
`FooTests.__internal__.__test_bundle` scheme contains configuration that builds `//Tests/FooTests`
and executes `//Tests/FooTests` when testing is requested.

## Introduction of Custom Xcode Schemes

A new Starlark module called, `xcode_schemes`, provides functions for defining custom, Xcode
schemes.

### Defining a Simple Xcode Scheme

Building on the previous example, let's define a scheme that combines the two targets,
`//Sources/Foo` and `//Tests/FooTests`.

```python
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
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

The `xcode_schemes.scheme` function call defines a scheme with a user visible name of `Foo Module`.
It is configured to build `//Sources/Foo` and `//Tests/FooTests`. (Targets listed in the
test action and launch action are automatically added to the build action.) The scheme is also
configured to execute the `//Tests/FooTests` target when testing is requested.

The result of the function is wrapped in a `list` and passed to the `schemes` parameter of the
`xcodeproj` macro.

### Specifying a Launch Target

Let's continue our example. We will add an `ios_application` and a `ios_ui_test` to the mix.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
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

The above example adds a second scheme called `My Application`. It is configured with two test targets
and a single launch target. All three targets are implicitly included in the build list.

### Specifying Launch Arguments and Environment Variables

There are times when it is desirable to customize the launch action with arguments and environment
variables. This can be accomplished by specifying them as parameters to the
`xcode_schemes.launch_action` function call.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
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

This example is the same as the previous one except arguments and environment variables are
defined for the launch action.

## Introduction of Scheme Autogeneration Mode

With this proposal, it is now possible to control how Xcode scheme autogeneration works using
the `scheme_autogeneration_mode` attribute on `_xcodeproj`. 

__Values__
- `auto`: If no custom schemes are provided, an Xcode scheme will be created for every buildable
  target. If custom schemes are provided, no autogenerated schemes will be created.
- `none`: No schemes are automatically generated.
- `all`: A scheme is generated for every buildable target even if custom schemes are provided.

The default value for `scheme_autogeneration_mode` is `auto`.

## Implementation Changes

### `xcode_schemes` Module

```python
def _scheme(
    name, 
    as_json = True, 
    build_action = None, 
    test_action = None, 
    launch_action = None):
    """Returns a `struct` or JSON `string` representing an Xcode scheme.

    Args:
        name: The user-visible name for the scheme as a `string`.
        as_json: Optional. A `bool` indicating whether the resulting struct 
            should be returned as JSON.
        build_action: Optional. A `struct` as returned by 
            `xcode_schemes.build_action`.
        test_action: Optional. A `struct` as returned by 
            `xcode_schemes.test_action`.
        launch_action: Optional. A `struct` as returned by 
            `xcode_schemes.launch_action`.
  
    Returns:
        If `as_json` is `False`, a `struct` representing an Xcode scheme is 
        returned. Otherwise, a JSON `string` representing the struct is 
        returned.
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

def _launch_action(target, args = None, env = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        args: Optional. A `list` of `string` arguments that should be passed to 
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as 
            environment variables when the target is executed.

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

### Changes to `_xcodeproj` Rule

#### `scheme_autogeneration_mode` Attribute

The `scheme_autogeneration_mode` attribute determines how Xcode scheme autogeneration will occur.
It's behavior is described in [Introduction of Scheme Autogeneration
Mode](#introduction-of-scheme-autogeneration-mode).

#### `schemes` Attribute

The `schemes` attribute accepts a `sequence` of JSON `string` values as returned by
`xcode_schemes.scheme`. The values are parsed and passed along to the scheme generation code in
`rules_xcodeproj`. An Xcode scheme is generated for each entry in the list.

### Changes to `xcodeproj` Macro 

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
        schemes: Optional. A `list` of JSON `string` values as returned by
            `xcode_schemes.scheme`.
        **kwargs: Additional arguments to pass to `xcodeproj_rule`.
    """
    pass
```

In addition to what the `xcodeproj` macro does today, if a value is provided for the `schemes`
parameter, the macro will collect all of the targets listed in the test and launch actions (not the
build action) and add them to the overall targets list. We only collect targets from the test action
and launch action because the target list for `xcodeproj` should only contain top-level or
leaf-nodes (i.e., not depeneded upon by other targets in the Xcode project).

_NOTE: If desired, we can leave the signature of `xcodeproj` as it is today. If we go that route, we
will retrieve the parameters from the `kwargs`._

#### Top-Level Library Target

There are situations where a library target might be a top-level target (i.e., no test target or
launch target).  To ensure that it is included in the Xcode project properly, one will need to
specify the library target in the `targets` list for `xcodeproj` and any schemes that should include
it. The following shows an example.

```python
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
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

#### Collecting Targets from Schemes

Let's look at an example that illustrates how targets are collected. The following is the example
from earlier with two schemes and some overlapping targets.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
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

After evaluation of the macro, the declaration for `_xcodeproj` will look like the following:

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

Note that the `targets` list is a deduplicated, sorted list of the targets that were provided from
the schemes and directly in the `targets` parameter.

The JSON representation of `Foo Module` will look like the following:

```json
{
  "name": "Foo Module",
  "build_action": {
    "targets": [
      "//Sources/Foo",
      "//Tests/FooTests"
    ],
  },
  "test_action": {
    "targets": [
      "//Tests/FooTests"
    ]
  }
}
```

Note that the build action targets list contains the targets from the build action declaration and
the test action declaration.

The JSON representation of `My Application` will look like the following:

```json
{
  "name": "My Application",
  "build_action": {
    "targets": [
      "//Sources/App",
      "//Tests/FooTests"
      "//Tests/AppUITests"
    ],
  },
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

> TODO: Is selecting targets from the test actions and launch actions sufficient for only incuding
> top-level targets in the overall targets list?

## Configuration and Target Selection in Schemes

Throughout this proposal, the syntax for listing targets in the schemes shows simple Bazel target
syntax. However, underneath the covers, there is some magic that occurs. 

Every Bazel target can map to one or more buildable targets inside `rules_xcodeproj`. These
buildable targets consist of the Bazel target along with any configuration variations that are
required to build any specified leaf nodes. For instance, the configuration for a module being
tested by a unit test using the iOS simulator is different than the configuration for the module
when it is used by an iOS application targeted for a device.

To simplify the syntax for specifying targets for schemes, we have opted to allow targets to be
specified by their Bazel target only. The logic inside `rules_xcodeproj` will select the correct
configuration variant based upon the leaf nodes that are included in the scheme.

## Outstanding Questions

### Do we need to support [`$(location)`](https://bazel.build/reference/be/make-variables#location) and [Make variable](https://bazel.build/reference/be/make-variables) for the JSON strings provided to the `schemes` attribute?

I think that the answer to this will be yes. I believe that we can use
[expand_make_vars](https://github.com/aspect-build/bazel-lib/blob/main/docs/expand_make_vars.md) to
implement it.

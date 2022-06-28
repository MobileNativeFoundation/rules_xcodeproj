# Custom Xcode Schemes

This document is a proposal for how custom Xcode schemes can be defined and implemented in
`rules_xcodeproj`.

## Contents

## Automatic Scheme Generation

As of this writing, the ruleset generates an Xcode scheme for every buildable target provided to
the `xcodeproj` rule. This allows a client to quickly define an `xcodeproj` target and generate an
Xcode project.

Let's start with an example.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    targets = [
        "//Sources/Foo",
        "//Tests/FooTests",
    ],
)
```

The above declaration generates two schemes: `Foo` and
`FooTests.__internal__.__test_bundle`. The `Foo` scheme contains configuration that builds
`//Sources/Foo`, but has no configuration for test, launch or any of the other actions. The
`FooTests.__internal__.__test_bundle` scheme contains configuration that builds `//Tests/FooTests`
and executes `//Tests/FooTests` when testing is requested.

While functional, developers may prefer a single scheme that builds both targets and executes
the `//Test/FooTests` target when test execution is requested.

## Introduction of the `xcode_scheme` Function

The `xcode_scheme` Starlark function allows a client to define an Xcode scheme and return a
representation of the scheme as a JSON string.

The `_xcodeproj` rule now has a `schemes` attribute that expects a `list` of JSON `string` values.

The `xcodeproj` macro also accepts a `schemes` parameter. The scheme JSON values are then used to
populate the `targets` attribute and the `schemes` attribute for the `_xcodeproj` rule.

### Simple Example Using `xcode_scheme`

Building on the previous example, let's define a scheme that combines the two targets.

```python
_SCHEMES = [
    xcode_scheme(
        name = "Foo Module",
        top_level_targets = [
            "//Tests/FooTests",
        ],
        other_targets = [
            "//Sources/Foo",
        ]
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

## Launch Actions

### Specify the Launch Target (`launch_action`)

Let's continue our example. We will add an `ios_application` and a `ios_ui_test` to the mix.

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

_SCHEMES = [
    xcode_scheme(
        name = "Foo Module",
        top_level_targets = [
            "//Tests/FooTests",
        ],
        other_targets = [
            "//Sources/Foo",
        ],
    ),
    # Things to note:
    # 1. Added a launch_action 
    # 2. Did not include other_targets
    xcode_scheme(
        name = "My Application",
        launch_action = launch_action(
            target = "//Sources/App"
        ),
        top_level_targets = [
            "//Tests/AppUITests",
            "//Tests/FooTests",
        ],
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

### Specify Launch Arguments and Environment Variables

```python
# Assumptions
#   //Sources/Foo:Foo - swift_library
#   //Sources/FooTests:FooTests = ios_unit_test
#   //Sources/App = ios_application
#   //Sources/AppUITests = ios_ui_test

_SCHEMES = [
    xcode_scheme(
        name = "Foo Module",
        top_level_targets = [
            "//Tests/FooTests",
        ],
        other_targets = [
            "//Sources/Foo",
        ],
    ),
    xcode_scheme(
        name = "My Application",
        launch_action = launch_action(
            target = "//Sources/App"
            args = [
                "--my_awesome_flag",
                "path/to/a/file.txt",
            ],
            env = {
                "RELEASE_THE_KRAKEN": "true",
            },
        ),
        top_level_targets = [
            "//Tests/AppUITests",
            "//Tests/FooTests",
        ],
    ),
]

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = _SCHEMES,
)
```

## Starlark Definitions

> TODO (grindel): FINISH ME

```python

def xcode_scheme(name, top_level_targets, other_targets = []):
    """Returns a JSON string that describes 
    """
    pass

```

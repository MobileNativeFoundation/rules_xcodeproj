# Custom Xcode Schemes

This document is a proposal for how custom Xcode schemes can be defined and implemented in
`rules_xcodeproj`.

## No Custom Schemes

As of this writing, the ruleset will generate an Xcode scheme for every buildable target provided to
the `xcodeproj` rule. This allows a client to quickly define an `xcodeproj` target and generate an
Xcode project.

The following declaration will generate two schemes: `Bar` and
`BarTests.__internal__.__test_bundle`. The `Bar` scheme contains configuration that builds
`//Sources/Bar`, but has no configuration for test, launch or any of the other actions. The
`BarTests.__internal__.__test_bundle` scheme contains configuration that builds `//Tests/BarTests`
and executes the test.

```python
# Assumptions
#   //Sources/Bar:Bar - swift_library
#   //Sources/BarTests:BarTests = ios_unit_test

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    targets = [
        "//Sources/Bar",
        "//Tests/BarTests",
    ],
)
```

While functional, most developers would prefer a single scheme that built both targets and executed
the `//Test/BarTests` target when test execution was requested.

## Simple

```python
scheme(
    name = "foo_scheme",
    scheme_name = "Foo Module",
    targets = [
        "//Sources/Foo",
        "//Tests/FooTests",
    ],
)

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = [
        ":foo_scheme",
    ],
)
```

## Complex with `launch_args` and `launch_env`

```python
scheme(
    name = "foo_scheme",
    scheme_name = "Foo Module",
    targets = [
        "//Sources/Foo",
        "//Tests/FooTests",
    ],
)

scheme(
    name = "bar_scheme",
    scheme_name = "Bar Module",
    targets = [
        "//Sources/Bar",
        "//Tests/BarTests",
    ],
)

scheme(
    name = "app_scheme",
    scheme_name = "My Application",
    targets = [
        "//Sources/App",
        "//Sources/Foo",
        "//Sources/Bar",
        "//Tests/FooTests",
        "//Tests/BarTests",
        "//Tests/AppUITests",
    ],
    launch_target = "//Sources/App",
    launch_args = [
        "path/to/a/file.txt",
    ]
    launch_env = {
        "RELEASE_THE_KRAKEN": "true",
    }
)

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = [
        ":foo_app_scheme",
        ":foo_scheme",
        ":bar_scheme",
    ],
)
```

## Complex with Launch Action

```python
scheme(
    name = "foo_scheme",
    scheme_name = "Foo Module",
    targets = [
        "//Sources/Foo",
        "//Tests/FooTests",
    ],
)

scheme(
    name = "bar_scheme",
    scheme_name = "Bar Module",
    targets = [
        "//Sources/Bar",
        "//Tests/BarTests",
    ],
)

launch_action(
    name = "app_launch_action",
    target = "//Sources/App,"
    args = [
        "path/to/a/file.txt",
    ]
    env = {
        "RELEASE_THE_KRAKEN": "true",
    }
)

scheme(
    name = "app_scheme",
    scheme_name = "My Application",
    targets = [
        ":app_launch_action",
        "//Sources/Foo",
        "//Sources/Bar",
        "//Tests/FooTests",
        "//Tests/BarTests",
        "//Tests/AppUITests",
    ],
)

xcodeproj(
    name = "generate_xcodeproj",
    project_name = "Command Line",
    tags = ["manual"],
    schemes = [
        ":foo_app_scheme",
        ":foo_scheme",
        ":bar_scheme",
    ],
)
```


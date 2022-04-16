# Proposal for Representing External Swift Packages

## Problem

External Swift packages are, typically, represented in Bazel projects in one of two ways:

1. As an external repository using `spm_repositories` and `spm_pkg` from
   [cgrindel/rules_spm](https://github.com/cgrindel/rules_spm/). 
2. As an external repositry using `http_archive` providing a custom build file.

If an Xcode project is generated to build with Bazel (BWB), no additional support is required in the
Xcode project for the project to build properly. Whatever is defined in the Bazel project will
handle the building and linking of the external dependencies.

If an Xcode project is generated to build with Xcode (BWX), the Xcode project needs to understand
how to incorporate the external dependency.

## Possible Solutions

### Treat the External Dependency as Another Target

In essence, the external dependencies are imported as Xcode targets. 

The pros for this approach are:

- The generation code can leverage much of its existing logic mapping Bazel targets.
- This maps well for Bazel projects that download the external package using `http_archive` and
  define a custom build file.

The cons for this approach are:

- The generated project will be cluttered with targets that are not relevant to the developer.
  These will include not just the direct dependencies, but all of the transitive dependencies for
  the external packages.
- The generation code will need to handle the source for these external dependencies, differently.
  It will need to download the source for the external dependencies, map it and make it available in
  the user interface.
- This approach will not handle external dependencies defined using `rules_spm`.

### Import the External Swift Packages as Swift Packages in the Xcode Project

[Xcode natively supports importing external Swift Packages to a
project.](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)

The pros for this approach are:

- The generated Xcode project will behave as if the developer had created the Xcode project and
  added the external dependency through the user interface.
- The generation code does not need to process the source files for the external dependencies.
- There are no extra targets in the Xcode project.
- This approach will handle external dependencies defined using `rules_spm`.

The cons for this approach are:

- This approach _may_ require some additional information from Bazel projects that download the
  external package using `http_archive` and define a custom build file.

## Recommendation

This proposal recommends that external Swift packages be added to the project using Xcode's native
Swift package support. The remaineder of this document defines a design by which this can be done.

## Design

The TL;DR for the design is:

- The `rules_xcodeproj` project will provide a rule, `xcodeproj_external_swift_packages` that maps
  external Bazel dependencies to their Swift package dependency declarations. 
- The `xcodeproj_external_swift_packages` rule will return an `ExternalSwiftPackagesInfo` provider
  with the external dependency information.
- The `xcodeproj` rule will gain an `external_deps` attribute that expects targets that provide an
  `ExternalSwiftPackagesInfo`.
- The `xcodeproj` rule will generate the appropriate Xcode project entries to load the external
  Swift package and associate it with the Xcode targets.

### `xcodeproj_external_swift_packages` Rule and `ExternalSwiftPackagesInfo` Provider

The mapping of external Bazel target to Swift package dependency will occur in the
`xcodeproj_external_swift_packages` rule. This rule provides an `ExternalSwiftPackagesInfo` instance
that maps dependent package information to Bazel targets.


#### External Dependencies Downloaded using `http_archive`

Let's assume that two external packages, `apple/swift-log` and `apple/swift-nio`, are used by a
project. The `WORKSPACE` might look something like the following:

```python
http_archive(
    name = "apple_swift_log",
    build_file = "@//bazel/third_party_deps:swift-log.BUILD",
    sha256 = "3bc5e9691bb6f5426325d8a564f6dc72de05c5f05e6676a5e8745299aa07a09d",
    strip_prefix = "swift-log-acbd69711395f5697b12beb4cf089929c9dbf3b4",
    url = "https://github.com/apple/swift-nio/archive/acbd69711395f5697b12beb4cf089929c9dbf3b4.tar.gz",
)

http_archive(
    name = "apple_swift_nio",
    build_file = "@//bazel/third_party_deps:swift-nio.BUILD",
    sha256 = "2bc5e9691bb6f5426325d8a564f6dc72de05c5f05e6676a5e8745299aa07a09c",
    strip_prefix = "swift-nio-2.38.0",
    url = "https://github.com/apple/swift-nio/archive/refs/tags/2.38.0.tar.gz",
)
```

Let's also assume that the build files for these packages define Bazel targets that match the
product names (e.g. the `Logging` product for `swift-log` is mapped to `@apple_swift_log//:Logging`.

The `xcodeproj_external_swift_packages` and `xcodeproj` declarations would look like the following:

```python
xcodeproj_external_swift_packages(
    name = "external_packages",
    packages = [
        xcodeproj_swift_package(
            url = "https://github.com/apple/swift-log",
            revision = "acbd69711395f5697b12beb4cf089929c9dbf3b4",
            products_to_bazel_map = {
                "Logging": "@apple_swift_log//:Logging",
            }
        ),
        xcodeproj_swift_package(
            url = "https://github.com/apple/swift-nio",
            exact_version = "2.38.0",
            products_to_bazel_map = {
                "NIO": "@apple_swift_nio//:NIO",
                "NIOHTTP1": "@apple_swift_nio//:NIOHTTP1",
            }
        ),
    ],
)

xcodeproj(
    name = "xcodeproj",
    project_name = "My App",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
    external_deps = [
        ":external_packages",
    ],
)
```

_TODO: Come up with a better name for `products_to_bazel_map` attribute._

The `packages` attribute for `xcodeproj_external_swift_packages` accepts one or more
`xcodeproj_swift_package` definitions. Each `xcodeproj_swift_package` defines the package dependency
and the mapping of the Swift package product to Bazel target. The `packages` attribute is defined as
an `attr.string_list`.  The`xcodeproj_swift_package` function returns a JSON string with the
attributes serialized as JSON keys.


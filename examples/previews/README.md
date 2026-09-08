# Native Xcode Previews

This example opts into native compilation only in a dedicated `Previews`
configuration. Ordinary `Debug` builds remain Bazel-owned. No Xcode installation
or build-service modifications are needed.

```sh
bazel run //:xcodeproj
open Previews.xcodeproj
```

Choose the source owned by the selected scheme:

| Scheme | Preview source |
| --- | --- |
| Views Previews, Framework Previews | `PreviewView.swift` |
| Mixed Previews | `Mixed.swift` |
| Mac Previews, iOS Previews | `PreviewApp.swift` |
| Explicit Previews | `GeneratedPreviewView.swift` under Bazel Generated |

For a library scheme, the top-level anchor supplies the platform and dependency
graph without making the app the selected compilation target. App schemes build
their library dependencies with Bazel; use the app-owned Preview source rather
than a dependency's source with an app-only scheme.

## Opt in

```starlark
xcodeproj(
    # ...
    default_xcode_configuration = "Debug",
    xcode_configurations = {"Debug": {}, "Previews": {}},
    preview_xcode_configurations = ["Previews"],
)
```

Set the Preview scheme's run configuration to `Previews`. Keep test, profile,
archive, and production actions on a normal Bazel-owned configuration. Archive
attempts using a Preview configuration are rejected.

In the Preview configuration, Bazel prepares generated sources, local imports,
link dependencies, and runtime bundles. Xcode compiles and links the selected
target with its real tools. Simulator and macOS Swift WMO targets use Xcode's
single-file compilation mode there; the original Bazel compilation mode remains
unchanged. `ENABLE_XOJIT_PREVIEWS` alone does not opt in because Xcode also sets
it during ordinary builds.

## Example coverage

The schemes exercise a Swift library with a dependency, a mixed Swift/C/C++/
Objective-C/Objective-C++ library with generated C, generated Swift with an
explicit Swift module map, macOS and iOS apps, and a dynamic framework. The
example uses the toolchain versions pinned in `MODULE.bazel`.

The Swift library, app, and framework graphs also share an
`apple_resource_bundle`. Preview builds materialize processed bundles next to
the selected product. Resource copies track their producers and owners, so
removing a dependency only removes bundles owned by this integration. Conflicting
same-name producers and unowned destinations fail instead of being overwritten.
Verify resource lookup in the running Canvas as well as the staged contents.

Command-line build checks can be run without opening the Canvas:

```sh
xcodebuild -project Previews.xcodeproj -scheme 'Views Previews' \
  -configuration Previews -destination 'platform=macOS,arch=arm64' build
xcodebuild -project Previews.xcodeproj -scheme 'iOS Previews' \
  -configuration Previews -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Previews.xcodeproj -scheme 'Mac Previews' \
  -configuration Debug -destination 'platform=macOS,arch=arm64' build
```

A successful build does not prove that a Preview rendered. Validate cold Canvas
creation, a literal edit, a structural edit, and a dependency edit with the
specific Xcode/runtime combination before relying on this workflow. Custom
toolchains, device-only destinations, and extension hosting need their own
validation; they are not covered by this example.

# `PBXNativeTarget`s `PBXProj` partials generator

The `pbxnativetargets` generator creates two or more files:

- A `PBXProj` partial containing all of the `PBXNativeTarget` related objects:
  - `PBXNativeTarget`
  - `XCBuildConfiguration`
  - `XCBuildConfigurationList`
  - and various build phases
- A file that maps `PBXBuildFile` identifiers to file paths

Each `pbxnativetargets` invocation might process a subset of all targets. All
targets that share the same name will be processed by the same invocation. This
is to enable target disambiguation (using the full label as the Xcode target
name when multiple targets share the same target name).

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXNativeTargets.swift`](src/PBXNativeTargets.swift) for more details):

- Positional `targets-output-path`
- Positional `buildfile-map-output-path`
- Positional `consolidation-map`
- Positional `target-arguments-file
- Positional `top-level-target-attributes-file`
- Positional `unit-test-host-attributes-file`
- Positional `default-xcode-configuration`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxnativetargets \
    /tmp/pbxproj_partials/pbxnativetargets/0 \
    /tmp/pbxproj_partials/buildfile_subidentifiers/0 \
    /tmp/pbxproj_partials/consolidation_maps/0 \
    /tmp/pbxproj_partials/target_arguments_files/7 \
    /tmp/pbxproj_partials/top_level_target_attributes_files/7 \
    /tmp/pbxproj_partials/unit_test_host_attributes_files/7 \
    Profile
```

## Output

Here is an example output:

### `pbxnativetargets`

```

```

### `consolidation_maps/1`

```

```

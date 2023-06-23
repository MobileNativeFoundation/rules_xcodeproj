# `PBXNativeTarget`s `PBXProj` partials generator

The `pbxnativetargets` generator creates two or more files:

- A `PBXProj` partial containing all of the `PBXNativeTarget` related objects:
  - `PBXNativeTarget`
  - `XCBuildConfiguration`
  - `XCBuildConfigurationList`
  - and various build phases
- A file that maps `PBXBuildFile` identifiers to file paths
- A directory containing zero or more automatic `.xcsheme`s

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
- Positional `xcshemes-output-directory`
- Positional `consolidation-map`
- Positional `default-xcode-configuration`
- Optional option `--top-level-targets <target> <output-product-basename> <link-params> <entitlements> <executable-name> <compile-target-name> <compile-target-ids> <test-host> ...`
- Optional option `--unit-test-hosts <target> <package-bin-dir> <product-path> <executable-name> ...`
- Option `--targets <target> ...`
- Option `--xcode-configuration-counts <xcode-configuration-count> ...`
- Option `--xcode-configurations <xcode-configuration-name> ...`
- Option `--product-types <product-types> ...`
- Option `--package-bin-dirs <package-bin-dir> ...`
- Option `--product-names <product-name> ...`
- Option `--product-paths <product-path> ...`
- Option `--product-basenames <product-basename> ...`
- Option `--platforms <platform> ...`
- Option `--os-versions <os-version> ...`
- Option `--archs <arch> ...`
- Option `--build-settings-files <build-settings-file> ...`
- Option `--has-c-params <has-c-params> ...`
- Option `--has-cxx-params <has-cxx-params> ...`
- Optional option `--srcs-counts <srcs-count> ...`
- Optional option `--srcs <srcs> ...`
- Optional option `--non-arc-srcs-counts <non-arc-srcs-count> ...`
- Optional option `--non-arc-srcs <non-arc-srcs> ...`
- Optional option `--hdrs-counts <hdrs-count> ...`
- Optional option `--hdrs <hdrs> ...`
- Optional option `--resources-counts <resources-count> ...`
- Optional option `--resources <resources> ...`
- Optional option `--folder-resources-counts <folder-resources-count> ...`
- Optional option `--folder-resources <folder-resources> ...`
- Option `--output-product-filenames <output-product-filename> ...`
- Option `--dysm-paths <dysm-path> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxnativetargets \
    /tmp/pbxproj_partials/pbxnativetargets/0 \
    /tmp/pbxproj_partials/buildfile_subidentifiers/0 \
    /tmp/pbxproj_partials/automatic_xcschemes/0 \
    /tmp/pbxproj_partials/consolidation_maps/0 \
    --targets \
    //tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3 \
    //tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3 \
    --xcode-configuration-counts \
    2 \
    1 \
    --xcode-configurations \
    Debug \
    Profile \
    Debug \
    --product-types \
    T \
    u \
    --product-names \
    generator \
    tests\
    --package-bin-dirs \
    applebin_macos-darwin_x86_64-dbg-STABLE-3/bin \
    applebin_macos-darwin_x86_64-dbg-STABLE-3/bin \
    --product-paths \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest \
    --product-basenames \
    generator_codesigned \
    tests.xctest \
    --module-names \
    generator \
    tests \
    --platforms \
    macosx \
    macosx \
    --os-versions \
    12.0 \
    12.0 \
    --archs \
    x86_64 \
    x86_64 \
    --build-settings-files \
    /tmp/pbxproj_partials/target_build_settings \
    "" \
    --has-c-params \
    0 \
    0 \
    --has-cxx-params \
    0 \
    0 \
    --srcs-counts \
    0 \
    2 \
    --srcs \
    tools/generators/legacy/test/AddTargetsTests.swift \
    tools/generators/legacy/test/Array+ExtensionsTests.swift \
    --dsym-paths \
    "" \
    ""
```

## Output

Here is an example output:

### `pbxnativetargets`

```

```

### `consolidation_maps/1`

```

```

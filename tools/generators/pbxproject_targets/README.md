# `PBXProject.targets` `PBXProj` partials generator

The `pbxproject_targets` generator creates four+ files:

- A `PBXProj` partial containing the `PBXProject.attributes.TargetAttributes` property
- A `PBXProj` partial containing:
  - The `PBXProject.targets` property
  - Closes the `PBXProject` element
- A `PBXProj` partial containing the `PBXTargetDependency` and `PBXContainerItemProxy` elements
- A set of files, each detailing how a set of configured targets are consolidated together

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXProjectTargets.swift`](src/PBXProjectTargets.swift) for more details):

- Positional `targets-output-path`
- Positional `target-attributes-output-path`
- Positional `target-dependencies-output-path`
- Positional `minimum-xcode-version`
- Optional option `--target-and-test-hosts <target> <test-host> ...`
- Option `--consolidation-map-output-paths <consolidation-map-output-path> ...`
- Option `--label-counts <label-count> ...`
- Option `--labels <label> ...`
- Option `--target-counts <target-count> ...`
- Option `--targets <target> ...`
- Option `--xcode-configuration-counts <xcode-configuration-count> ...`
- Option `--xcode-configurations <xcode-configuration> ...`
- Option `--product-types <product-types> ...`
- Option `--product-paths <product-path> ...`
- Option `--platforms <platform> ...`
- Option `--os-versions <os-version> ...`
- Option `--archs <arch> ...`
- Option `--dependency-counts <dependency-count> ...`
- Option `--dependencies <dependency> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxproject_targets \
    /tmp/pbxproj_partials/pbxproject_targets \
    /tmp/pbxproj_partials/pbxproject_target_attributes \
    /tmp/pbxproj_partials/pbxtargetdependencies \
    14.0 \
    --target-and-test-hosts \
    '//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3' \
    '//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3' \
    --consolidation-map-output-paths \
    /tmp/pbxproj_partials/consolidation_maps/0 \
    /tmp/pbxproj_partials/consolidation_maps/1 \
    --label-counts \
    2 \
    1 \
    --labels \
    //tools/generators/legacy:generator \
    //tools/generators/legacy/test:tests.__internal__.__test_bundle \
    //tools/generators/legacy:generator.library \
    --target-counts \
    1 \
    1 \
    1 \
    --targets \
    '//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3' \
    '//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3' \
    '//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1' \
    --xcode-configuration-counts \
    2 \
    1 \
    1 \
    --xcode-configurations \
    Debug \
    Release \
    Debug \
    Debug \
    --product-types \
    com.apple.product-type.tool \
    com.apple.product-type.bundle.unit-test \
    com.apple.product-type.library.static \
    --product-paths \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest \
    bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a \
    --platforms \
    macosx \
    macosx \
    macosx \
    --os-versions \
    12.0 \
    12.0 \
    12.0 \
    --archs \
    x86_64 \
    x86_64 \
    x86_64 \
    --dependency-counts \
    1 \
    1 \
    0 \
    --dependencies \
    '//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1' \
    '//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'
```

## Output

Here is an example output:

### `pbxproject_targets`

```
			targets = (
				0000564AEDC8000000000001 /* generator */,
				010071A3113B000000000001 /* generator.library */,
				00005110672D000000000001 /* tests.__internal__.__test_bundle */,
			);
		};

```

### `pbxproject_target_attributes`

```
				TargetAttributes = {
					FF0100000000000000000001 /* BazelDependencies */ = {
						CreatedOnToolsVersion = 14.0.0;
						LastSwiftMigration = 9999;
					};
					0000564AEDC8000000000001 /* generator */ = {
						CreatedOnToolsVersion = 14.0.0;
						LastSwiftMigration = 9999;
					};
					010071A3113B000000000001 /* generator.library */ = {
						CreatedOnToolsVersion = 14.0.0;
						LastSwiftMigration = 9999;
					};
					00005110672D000000000001 /* tests.__internal__.__test_bundle */ = {
						CreatedOnToolsVersion = 14.0.0;
						LastSwiftMigration = 9999;
					};
				};
			};

```

### `pbxtargetdependencies`

```
		0001564AEDC8010071A3113B /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 010071A3113B000000000001;
			remoteInfo = generator.library;
		};
		0002564AEDC8010071A3113B /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			name = generator.library;
			target = 010071A3113B000000000001 /* generator.library */;
			targetProxy = 0001564AEDC8010071A3113B /* PBXContainerItemProxy */;
		};
		00015110672D010071A3113B /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = FF0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 010071A3113B000000000001;
			remoteInfo = generator.library;
		};
		00025110672D010071A3113B /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			name = generator.library;
			target = 010071A3113B000000000001 /* generator.library */;
			targetProxy = 00015110672D010071A3113B /* PBXContainerItemProxy */;
		};

```

### `consolidation_maps/0`

```
generator	//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3	00564AEDC80171A3113B
tests.__internal__.__test_bundle	//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3	005110672D0171A3113B

```

### `consolidation_maps/1`

```
generator.library	//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1	0171A3113B

```

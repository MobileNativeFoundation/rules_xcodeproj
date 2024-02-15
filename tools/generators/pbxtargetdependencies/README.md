# `PBXTargetDependencies` `PBXProj` partials generator

The `pbxtargetdependencies` generator creates four+ files:

- A `PBXProj` partial containing the `PBXTargetDependency` and `PBXContainerItemProxy` objects
- A `PBXProj` partial containing the `PBXProject.attributes.TargetAttributes` property
- A `PBXProj` partial containing:
  - The `PBXProject.targets` property
  - Closes the `PBXProject` element
- A set of files, each detailing how a set of configured targets are consolidated together

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXTargetDependencies.swift`](src/PBXTargetDependencies.swift) for more
details):

- Positional `target-dependencies-output-path`
- Positional `targets-output-path`
- Positional `target-attributes-output-path`
- Positional `consolidation-maps-inputs-file`
- Positional `minimum-xcode-version`
- Positional `target-name-mode`
- Optional option `--target-and-test-hosts <target> <test-host> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxtargetdependencies \
    /tmp/pbxproj_partials/pbxtargetdependencies \
    /tmp/pbxproj_partials/pbxtargetdependencies \
    /tmp/pbxproj_partials/pbxproject_target_attributes \
    /tmp/pbxproj_partials/consolidation_maps_inputs_file \
    14.0 \
	auto \
    --target-and-test-hosts \
    '//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3' \
    '//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'
```

## Output

Here is an example output:

### `pbxtargetdependencies`

```
			targets = (
				FF0100000000000000000001 /* BazelDependencies */,
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

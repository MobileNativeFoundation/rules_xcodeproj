# `BazelDependencies` `PBXProj` partial generator

The `bazel_dependencies` generator creates a `PBXProj` partial containing the
`BazelDependencies` target and associated elements.

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`BazelDependencies.swift`](src/BazelDependencies.swift) for more details):

- Positional `output-path`
- Positional `target-ids-file`
- Positional `index-import`
- Option list `--xcode-configurations <xcode-configurations> ...`
- Optional option `--default-xcode-configuration <default-xcode-configuration>`
- Option list `--platforms <platforms> ...`
- Optional option `--pre-build-script <pre-build-script>`
- Optional option `--post-build-script <post-build-script>`
- Flag `--colorize`

Here is an example invocation:

```shell
$ bazel_dependencies \
    /tmp/pbxproj_partials/bazel_dependencies \
    bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_target_ids \
    bazel-out/darwin_arm64-opt-exec-2B5CBBC6/bin/external/_main~non_module_deps~rules_xcodeproj_index_import/index-import \
    --xcode-configurations \
    Debug \
    Release \
    --default-xcode-configuration Release \
    --platforms \
    iphonesimulator \
    macosx \
    watchos \
    --pre-build-script bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_pre_build_script
```

## Output

Here is an example output:

```
		0000000000000000000000FE /* Pre-build Run Script */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Pre-build Run Script";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"build\" ]]; then\n  cd \"$SRCROOT\"\n  echo \"Hello from pre-build!\"\nfi\n";
			showEnvVarsInLog = 0;
		};
		0000000000000000000000FD /* Bazel Build */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
		0000000000000000000000FC /* Create swift_debug_settings.py */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "perl -pe '\n  # Replace \"__BAZEL_XCODE_DEVELOPER_DIR__\" with \"$(DEVELOPER_DIR)\"\n  s/__BAZEL_XCODE_DEVELOPER_DIR__/\\$(DEVELOPER_DIR)/g;\n\n  # Replace \"__BAZEL_XCODE_SDKROOT__\" with \"$(SDKROOT)\"\n  s/__BAZEL_XCODE_SDKROOT__/\\$(SDKROOT)/g;\n\n  # Replace build settings with their values\n  s/\n    \\$             # Match a dollar sign\n    (\\()?          # Optionally match an opening parenthesis and capture it\n    ([a-zA-Z_]\\w*) # Match a variable name and capture it\n    (?(1)\\))       # If an opening parenthesis was captured, match a closing parenthesis\n  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable\n\n' \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\n";
			showEnvVarsInLog = 0;
		};
		0000000000000000000000F9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BAZEL_PACKAGE_BIN_DIR = rules_xcodeproj;
				CALCULATE_OUTPUT_GROUPS_SCRIPT = "$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py";
				INDEXING_SUPPORTED_PLATFORMS__ = "$(INDEXING_SUPPORTED_PLATFORMS__NO)";
				INDEXING_SUPPORTED_PLATFORMS__NO = "macosx iphonesimulator";
				INDEXING_SUPPORTED_PLATFORMS__YES = macosx;
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_DISABLE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_OUT)/darwin_arm64-opt-exec-2B5CBBC6/bin/external/_main~non_module_deps~rules_xcodeproj_index_import/index-import";
				SUPPORTED_PLATFORMS = "$(INDEXING_SUPPORTED_PLATFORMS__$(INDEX_ENABLE_BUILD_ARENA))";
				SUPPORTS_MACCATALYST = YES;
				TARGET_IDS_FILE = "$(BAZEL_OUT)/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_target_ids";
				TARGET_NAME = BazelDependencies;
			};
			name = Debug;
		};
		0000000000000000000000F8 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BAZEL_PACKAGE_BIN_DIR = rules_xcodeproj;
				CALCULATE_OUTPUT_GROUPS_SCRIPT = "$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py";
				INDEXING_SUPPORTED_PLATFORMS__ = "$(INDEXING_SUPPORTED_PLATFORMS__NO)";
				INDEXING_SUPPORTED_PLATFORMS__NO = "macosx iphonesimulator watchos";
				INDEXING_SUPPORTED_PLATFORMS__YES = macosx;
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_DISABLE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_OUT)/darwin_arm64-opt-exec-2B5CBBC6/bin/external/_main~non_module_deps~rules_xcodeproj_index_import/index-import";
				SUPPORTED_PLATFORMS = "$(INDEXING_SUPPORTED_PLATFORMS__$(INDEX_ENABLE_BUILD_ARENA))";
				SUPPORTS_MACCATALYST = YES;
				TARGET_IDS_FILE = "$(BAZEL_OUT)/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_target_ids";
				TARGET_NAME = BazelDependencies;
			};
			name = Release;
		};
		0000000000000000000000FA /* Build configuration list for PBXAggregateTarget "BazelDependencies" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0000000000000000000000F9 /* Debug */,
				0000000000000000000000F8 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		0000000000000000000000FF /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			buildConfigurationList = 0000000000000000000000FC /* Build configuration list for PBXAggregateTarget "BazelDependencies" */;
			buildPhases = (
				0000000000000000000000FE /* Pre-build Run Script */,
				0000000000000000000000FD /* Bazel Build */,
				0000000000000000000000FC /* Create swift_debug_settings.py */,
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

```

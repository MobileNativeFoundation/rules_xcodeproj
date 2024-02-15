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
		0700567C87AA000000000003 /* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)",
			);
			name = "Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"indexbuild\" ]]; then\n  cd \"$SRCROOT\"\n\n  \"$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh\"\nelse\n  \"$BAZEL_INTEGRATION_DIR/copy_outputs.sh\" \\\n    \"_BazelForcedCompile_.swift\" \\\n    \"$BAZEL_INTEGRATION_DIR/xctest.exclude.rsynclist\"\nfi\n";
			showEnvVarsInLog = 0;
		};
		0700567C87AA000000000005 /* Create Link Dependencies */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(LINK_PARAMS_FILE)",
			);
			name = "Create Link Dependencies";
			outputPaths = (
				"$(DERIVED_FILE_DIR)/link.params",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"${ENABLE_PREVIEWS:-}\" == \"YES\" ]]; then\nperl -pe 's/\\$(\\()?([a-zA-Z_]\\w*)(?(1)\\))/$ENV{$2}/g' \\\n  \"$SCRIPT_INPUT_FILE_0\" > \"$SCRIPT_OUTPUT_FILE_0\"\nelse\n  touch \"$SCRIPT_OUTPUT_FILE_0\"\nfi\n";
			showEnvVarsInLog = 0;
		};
		0700567C87AA000000000006 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				07FF899480F401C8A355436E /* CalculateConsolidationMapsTests.swift in Sources */,
				07FF77C58DFE143251932914 /* CalculateCreatedOnToolsVersionTests.swift in Sources */,
				07FF910CC024D714A0A5231E /* CalculateIdentifiedTargetsMapTests.swift in Sources */,
				07FF6C261264AE5214DC1970 /* CalculateTargetAttributesPartialTests.swift in Sources */,
				07FF3FC97131936C46CCDF94 /* CalculateTargetDependenciesPartialTests.swift in Sources */,
				07FF9DD9FE52C4BF15C03952 /* CalculateTargetsPartialTests.swift in Sources */,
				07FF3D79A49557EB694D854A /* ConsolidateTargetsTests.swift in Sources */,
				07FF4350F1F4E0FBF3407CBE /* CreateContainerItemProxyObject+Testing.swift in Sources */,
				07FF8A27B8AF544C8411FC6A /* CreateContainerItemProxyObjectTests.swift in Sources */,
				07FFF1BFCBE243B6E5F78576 /* CreateDependencyObjectsTests.swift in Sources */,
				07FF0A8760BC914A2B2E2844 /* CreateTargetAttributesContentTests.swift in Sources */,
				07FFF2B1536D5835BB0EB9DF /* CreateTargetAttributesObject+Testing.swift in Sources */,
				07FF554C721C17B46C8F7D9B /* CreateTargetAttributesObjectsTests.swift in Sources */,
				07FF6D9A089FBCAE868FBADB /* CreateTargetDependencyObject+Testing.swift in Sources */,
				07FF1212C6EE17729102A827 /* CreateTargetDependencyObjectTests.swift in Sources */,
				07FF93197908A62575A869B4 /* CreateTargetSubIdentifier+Testing.swift in Sources */,
				07FF758E3DB6B0347F41F13E /* DisambiguateTargetsTests.swift in Sources */,
				07FFD1ECA5E24935A946F225 /* IdentifiedTarget+Testing.swift in Sources */,
				07FFB9A3B2C27B345B74DFB2 /* InnerIdentifyTargetsTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0700567C87AA000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BAZEL_COMPILE_TARGET_IDS = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests.library macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee";
				BAZEL_LABEL = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests";
				BAZEL_OUTPUTS_PRODUCT = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/pbxtargetdependencies/pbxtargetdependencies_tests.__internal__.__test_bundle.zip";
				BAZEL_OUTPUTS_PRODUCT_BASENAME = pbxtargetdependencies_tests.xctest;
				BAZEL_PACKAGE_BIN_DIR = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/pbxtargetdependencies";
				BAZEL_TARGET_ID = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee";
				COMPILE_TARGET_NAME = pbxtargetdependencies_tests;
				INFOPLIST_FILE = "$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/pbxtargetdependencies/rules_xcodeproj/pbxtargetdependencies_tests.__internal__.__test_bundle/Info.plist";
				LINK_PARAMS_FILE = "$(BAZEL_OUT)/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj-params/pbxtargetdependencies_tests.25.link.params";
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				OTHER_LDFLAGS = "@$(DERIVED_FILE_DIR)/link.params";
				OTHER_SWIFT_FLAGS = "-Xcc -working-directory -Xcc $(PROJECT_DIR) -working-directory $(PROJECT_DIR) -Xcc -ivfsoverlay$(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml $(PREVIEWS_SWIFT_INCLUDE__$(ENABLE_PREVIEWS)) -DDEBUG -Onone -enable-testing -F$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks -I$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/usr/lib -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~non_module_deps~com_github_apple_swift_argument_parser -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/lib/ToolCommon -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~non_module_deps~com_github_apple_swift_collections -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/lib/PBXProj -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/pbxtargetdependencies -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin -static -Xcc -O0 -Xcc -DDEBUG=1 -Xcc -fstack-protector -Xcc -fstack-protector-all";
				PREVIEWS_SWIFT_INCLUDE__ = "";
				PREVIEWS_SWIFT_INCLUDE__NO = "";
				PREVIEWS_SWIFT_INCLUDE__YES = "-I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/tools/generators/pbxtargetdependencies";
				PRODUCT_BUNDLE_IDENTIFIER = com.bazelbuild.rulesapple.Tests;
				PRODUCT_MODULE_NAME = pbxtargetdependencies_tests;
				PRODUCT_NAME = pbxtargetdependencies_tests;
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				TARGET_NAME = pbxtargetdependencies_tests;
			};
			name = Debug;
		};
		0700567C87AA000000000101 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BAZEL_COMPILE_TARGET_IDS = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests.library macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9";
				BAZEL_LABEL = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests";
				BAZEL_OUTPUTS_DSYM = "\"bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies/pbxtargetdependencies_tests.xctest.dSYM\"";
				BAZEL_OUTPUTS_PRODUCT = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies/pbxtargetdependencies_tests.__internal__.__test_bundle.zip";
				BAZEL_OUTPUTS_PRODUCT_BASENAME = pbxtargetdependencies_tests.xctest;
				BAZEL_PACKAGE_BIN_DIR = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies";
				BAZEL_TARGET_ID = "@@//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9";
				COMPILE_TARGET_NAME = pbxtargetdependencies_tests;
				INFOPLIST_FILE = "$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies/rules_xcodeproj/pbxtargetdependencies_tests.__internal__.__test_bundle/Info.plist";
				LINK_PARAMS_FILE = "$(BAZEL_OUT)/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj-params/pbxtargetdependencies_tests.54.link.params";
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				OTHER_LDFLAGS = "@$(DERIVED_FILE_DIR)/link.params";
				OTHER_SWIFT_FLAGS = "-Xcc -working-directory -Xcc $(PROJECT_DIR) -working-directory $(PROJECT_DIR) -Xcc -ivfsoverlay$(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml $(PREVIEWS_SWIFT_INCLUDE__$(ENABLE_PREVIEWS)) -DNDEBUG -O -F$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks -I$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/usr/lib -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~non_module_deps~com_github_apple_swift_argument_parser -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/lib/ToolCommon -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~non_module_deps~com_github_apple_swift_collections -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/lib/PBXProj -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay -I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_swift_custom_dump -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin -static -Xcc -Os -Xcc -DNDEBUG=1 -Xcc -Wno-unused-variable -Xcc -Winit-self -Xcc -Wno-extra";
				PREVIEWS_SWIFT_INCLUDE__ = "";
				PREVIEWS_SWIFT_INCLUDE__NO = "";
				PREVIEWS_SWIFT_INCLUDE__YES = "-I$(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/tools/generators/pbxtargetdependencies";
				PRODUCT_BUNDLE_IDENTIFIER = com.bazelbuild.rulesapple.Tests;
				PRODUCT_MODULE_NAME = pbxtargetdependencies_tests;
				PRODUCT_NAME = pbxtargetdependencies_tests;
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				TARGET_NAME = pbxtargetdependencies_tests;
			};
			name = Release;
		};
		0700567C87AA000000000002 /* Build configuration list for PBXNativeTarget "pbxtargetdependencies_tests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0700567C87AA000000000100 /* Debug */,
				0700567C87AA000000000101 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		0700567C87AA0000000000FF /* pbxtargetdependencies_tests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = pbxtargetdependencies_tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		0700567C87AA000000000001 /* pbxtargetdependencies_tests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 0700567C87AA000000000002 /* Build configuration list for PBXNativeTarget "pbxtargetdependencies_tests" */;
			buildPhases = (
				0700567C87AA000000000003 /* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */,
				0700567C87AA000000000005 /* Create Link Dependencies */,
				0700567C87AA000000000006 /* Sources */,
			);
			buildRules = (
			);
			dependencies = (
				0702567C87AAFF0001000000 /* PBXTargetDependency */,
			);
			name = pbxtargetdependencies_tests;
			productName = pbxtargetdependencies_tests;
			productReference = 0700567C87AA0000000000FF /* pbxtargetdependencies_tests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		0700284A927C000000000003 /* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Copy Bazel Outputs / Generate Bazel Dependencies (Index Build)";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -euo pipefail\n\nif [[ \"$ACTION\" == \"indexbuild\" ]]; then\n  cd \"$SRCROOT\"\n\n  \"$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh\"\nelse\n  \"$BAZEL_INTEGRATION_DIR/copy_outputs.sh\" \\\n    \"_BazelForcedCompile_.swift\" \\\n    \"\"\nfi\n";
			showEnvVarsInLog = 0;
		};
		0700284A927C000000000006 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				07FFB3353134E248C274F3D5 /* XCTFail.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0700284A927C000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BAZEL_LABEL = "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay";
				BAZEL_OUTPUTS_PRODUCT = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay/libXCTestDynamicOverlay.a";
				BAZEL_OUTPUTS_PRODUCT_BASENAME = libXCTestDynamicOverlay.a;
				BAZEL_PACKAGE_BIN_DIR = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay";
				BAZEL_TARGET_ID = "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee";
				COMPILE_TARGET_NAME = XCTestDynamicOverlay;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				OTHER_SWIFT_FLAGS = "-Xcc -working-directory -Xcc $(PROJECT_DIR) -working-directory $(PROJECT_DIR) -Xcc -ivfsoverlay$(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml -DDEBUG -Onone -enable-testing -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin -static -Xcc -O0 -Xcc -DDEBUG=1 -Xcc -fstack-protector -Xcc -fstack-protector-all";
				PRODUCT_MODULE_NAME = XCTestDynamicOverlay;
				PRODUCT_NAME = XCTestDynamicOverlay;
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				TARGET_NAME = XCTestDynamicOverlay;
			};
			name = Debug;
		};
		0700284A927C000000000101 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BAZEL_LABEL = "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay";
				BAZEL_OUTPUTS_PRODUCT = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay/libXCTestDynamicOverlay.a";
				BAZEL_OUTPUTS_PRODUCT_BASENAME = libXCTestDynamicOverlay.a;
				BAZEL_PACKAGE_BIN_DIR = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay";
				BAZEL_TARGET_ID = "@@_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9";
				COMPILE_TARGET_NAME = XCTestDynamicOverlay;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				OTHER_SWIFT_FLAGS = "-Xcc -working-directory -Xcc $(PROJECT_DIR) -working-directory $(PROJECT_DIR) -Xcc -ivfsoverlay$(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml -DNDEBUG -O -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min13.0-applebin_macos-darwin_arm64-opt-ST-1f5196d1a0d9/bin -static -Xcc -Os -Xcc -DNDEBUG=1 -Xcc -Wno-unused-variable -Xcc -Winit-self -Xcc -Wno-extra";
				PRODUCT_MODULE_NAME = XCTestDynamicOverlay;
				PRODUCT_NAME = XCTestDynamicOverlay;
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				TARGET_NAME = XCTestDynamicOverlay;
			};
			name = Release;
		};
		0700284A927C000000000002 /* Build configuration list for PBXNativeTarget "XCTestDynamicOverlay" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0700284A927C000000000100 /* Debug */,
				0700284A927C000000000101 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		0700284A927C0000000000FF /* libXCTestDynamicOverlay.a */ = {isa = PBXFileReference; explicitFileType = "compiled.mach-o.dylib"; includeInIndex = 0; name = libXCTestDynamicOverlay.a; path = "bazel-out/macos-arm64-min13.0-applebin_macos-darwin_arm64-dbg-ST-95054d4cebee/bin/external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay/libXCTestDynamicOverlay.a"; sourceTree = BUILT_PRODUCTS_DIR; };
		0700284A927C000000000001 /* XCTestDynamicOverlay */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 0700284A927C000000000002 /* Build configuration list for PBXNativeTarget "XCTestDynamicOverlay" */;
			buildPhases = (
				0700284A927C000000000003 /* Copy Bazel Outputs / Generate Bazel Dependencies (Index Build) */,
				0700284A927C000000000006 /* Sources */,
			);
			buildRules = (
			);
			dependencies = (
				0702284A927CFF0001000000 /* PBXTargetDependency */,
			);
			name = XCTestDynamicOverlay;
			productName = XCTestDynamicOverlay;
			productType = "com.apple.product-type.library.static";
		};

```

### `buildfile_subidentifiers`

```
P07567C87AA0pbxtargetdependencies_tests.xctest
007899480F401C8A355436E0tools/generators/pbxtargetdependencies/test/Generator/CalculateConsolidationMapsTests.swift
00777C58DFE1432519329140tools/generators/pbxtargetdependencies/test/Generator/CalculateCreatedOnToolsVersionTests.swift
007910CC024D714A0A5231E0tools/generators/pbxtargetdependencies/test/Generator/CalculateIdentifiedTargetsMapTests.swift
0076C261264AE5214DC19700tools/generators/pbxtargetdependencies/test/Generator/CalculateTargetAttributesPartialTests.swift
0073FC97131936C46CCDF940tools/generators/pbxtargetdependencies/test/Generator/CalculateTargetDependenciesPartialTests.swift
0079DD9FE52C4BF15C039520tools/generators/pbxtargetdependencies/test/Generator/CalculateTargetsPartialTests.swift
0073D79A49557EB694D854A0tools/generators/pbxtargetdependencies/test/Generator/ConsolidateTargetsTests.swift
0074350F1F4E0FBF3407CBE0tools/generators/pbxtargetdependencies/test/Generator/CreateContainerItemProxyObject+Testing.swift
0078A27B8AF544C8411FC6A0tools/generators/pbxtargetdependencies/test/Generator/CreateContainerItemProxyObjectTests.swift
007F1BFCBE243B6E5F785760tools/generators/pbxtargetdependencies/test/Generator/CreateDependencyObjectsTests.swift
0070A8760BC914A2B2E28440tools/generators/pbxtargetdependencies/test/Generator/CreateTargetAttributesContentTests.swift
007F2B1536D5835BB0EB9DF0tools/generators/pbxtargetdependencies/test/Generator/CreateTargetAttributesObject+Testing.swift
007554C721C17B46C8F7D9B0tools/generators/pbxtargetdependencies/test/Generator/CreateTargetAttributesObjectsTests.swift
0076D9A089FBCAE868FBADB0tools/generators/pbxtargetdependencies/test/Generator/CreateTargetDependencyObject+Testing.swift
0071212C6EE17729102A8270tools/generators/pbxtargetdependencies/test/Generator/CreateTargetDependencyObjectTests.swift
00793197908A62575A869B40tools/generators/pbxtargetdependencies/test/Generator/CreateTargetSubIdentifier+Testing.swift
007758E3DB6B0347F41F13E0tools/generators/pbxtargetdependencies/test/Generator/DisambiguateTargetsTests.swift
007D1ECA5E24935A946F2250tools/generators/pbxtargetdependencies/test/Generator/IdentifiedTarget+Testing.swift
007B9A3B2C27B345B74DFB20tools/generators/pbxtargetdependencies/test/Generator/InnerIdentifyTargetsTests.swift
P07284A927C0libXCTestDynamicOverlay.a
007B3353134E248C274F3D50external/_main~dev_non_module_deps~com_github_pointfreeco_xctest_dynamic_overlay/Sources/XCTestDynamicOverlay/XCTFail.swift

```

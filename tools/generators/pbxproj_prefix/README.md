# `PBXProj` prefix partial generator

The `pbxproj_prefix` generator creates a `PBXProj` partial containing the
start of the `PBXProj` element, `PBXProject` related elements, and _part of_ the
start of the `PBXProject` element.

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXProjPrefix.swift`](src/PBXProjPrefix.swift) for more details):

- Positional `output-path`
- Positional `workspace`
- Positional `execution-root-file`
- Positional `build-mode`
- Positional `minimum-xcode-version`
- Positional `development-region`
- Optional option `--organization-name <organization-name>`
- Option list `--xcode-configurations <xcode-configurations> ...`
- Optional option `--default-xcode-configuration <default-xcode-configuration>`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxproj_prefix \
    /tmp/pbxproj_partials/pbxproj_prefix \
    /tmp/workspace \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_execution_root_file \
    bazel \
    14.0 \
    enGB \
    --organization-name MobileNativeFoundation \
    --xcode-configurations \
    Debug \
    Release \
    --default-xcode-configuration Release
```

## Output

Here is an example output:

```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 55;
	objects = {
		000000000000000000000005 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				BAZEL_CONFIG = rules_xcodeproj;
				BAZEL_EXTERNAL = "$(BAZEL_OUTPUT_BASE)/external";
				BAZEL_INTEGRATION_DIR = "$(INTERNAL_DIR)/bazel";
				BAZEL_LLDB_INIT = "$(HOME)/.lldbinit-rules_xcodeproj";
				BAZEL_OUT = "$(PROJECT_DIR)/bazel-out";
				BAZEL_OUTPUT_BASE = "$(_BAZEL_OUTPUT_BASE:standardizepath)";
				BAZEL_WORKSPACE_ROOT = "$(SRCROOT)";
				BUILD_DIR = "$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)";
				BUILD_WORKSPACE_DIRECTORY = "$(SRCROOT)";
				BUILT_PRODUCTS_DIR = "$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				CC = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_MODULES_AUTOLINK = NO;
				CODE_SIGNING_ALLOWED = NO;
				CONFIGURATION_BUILD_DIR = "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)";
				COPY_PHASE_STRIP = NO;
				CURRENT_EXECUTION_ROOT = "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				CXX = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEPLOYMENT_LOCATION = "$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA))";
				DSTROOT = "$(PROJECT_TEMP_DIR)";
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				INDEXING_BUILT_PRODUCTS_DIR__ = "$(INDEXING_BUILT_PRODUCTS_DIR__NO)";
				INDEXING_BUILT_PRODUCTS_DIR__NO = "$(BUILD_DIR)";
				INDEXING_BUILT_PRODUCTS_DIR__YES = "$(CONFIGURATION_BUILD_DIR)";
				INDEXING_DEPLOYMENT_LOCATION__ = "$(INDEXING_DEPLOYMENT_LOCATION__NO)";
				INDEXING_DEPLOYMENT_LOCATION__NO = YES;
				INDEXING_DEPLOYMENT_LOCATION__YES = NO;
				INDEXING_PROJECT_DIR__ = "$(INDEXING_PROJECT_DIR__NO)";
				INDEXING_PROJECT_DIR__NO = "$(PROJECT_DIR)";
				INDEXING_PROJECT_DIR__YES = "/tmp/workspace/bazel-output-base/rules_xcodeproj.noindex/indexbuild_output_base/execroot/_main";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = $(PROJECT_FILE_PATH)/rules_xcodeproj;
				LD = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LDPLUSPLUS = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = (
				);
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool.sh";
				ONLY_ACTIVE_ARCH = YES;
				RESOLVED_REPOSITORIES = "";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SCHEME_TARGET_IDS_FILE = "$(OBJROOT)/scheme_target_ids";
				SRCROOT = /tmp/workspace;
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EXEC = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_USE_INTEGRATED_DRIVER = NO;
				SWIFT_VERSION = 5.0;
				TARGET_TEMP_DIR = "$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)";
				USE_HEADERMAP = NO;
				VALIDATE_WORKSPACE = NO;
				_BAZEL_OUTPUT_BASE = "$(PROJECT_DIR)/../..";
			};
			name = Debug;
		};
		000000000000000000000006 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				BAZEL_CONFIG = rules_xcodeproj;
				BAZEL_EXTERNAL = "$(BAZEL_OUTPUT_BASE)/external";
				BAZEL_INTEGRATION_DIR = "$(INTERNAL_DIR)/bazel";
				BAZEL_LLDB_INIT = "$(HOME)/.lldbinit-rules_xcodeproj";
				BAZEL_OUT = "$(PROJECT_DIR)/bazel-out";
				BAZEL_OUTPUT_BASE = "$(_BAZEL_OUTPUT_BASE:standardizepath)";
				BAZEL_WORKSPACE_ROOT = "$(SRCROOT)";
				BUILD_DIR = "$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)";
				BUILD_WORKSPACE_DIRECTORY = "$(SRCROOT)";
				BUILT_PRODUCTS_DIR = "$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				CC = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_MODULES_AUTOLINK = NO;
				CODE_SIGNING_ALLOWED = NO;
				CONFIGURATION_BUILD_DIR = "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)";
				COPY_PHASE_STRIP = NO;
				CURRENT_EXECUTION_ROOT = "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				CXX = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEPLOYMENT_LOCATION = "$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA))";
				DSTROOT = "$(PROJECT_TEMP_DIR)";
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				INDEXING_BUILT_PRODUCTS_DIR__ = "$(INDEXING_BUILT_PRODUCTS_DIR__NO)";
				INDEXING_BUILT_PRODUCTS_DIR__NO = "$(BUILD_DIR)";
				INDEXING_BUILT_PRODUCTS_DIR__YES = "$(CONFIGURATION_BUILD_DIR)";
				INDEXING_DEPLOYMENT_LOCATION__ = "$(INDEXING_DEPLOYMENT_LOCATION__NO)";
				INDEXING_DEPLOYMENT_LOCATION__NO = YES;
				INDEXING_DEPLOYMENT_LOCATION__YES = NO;
				INDEXING_PROJECT_DIR__ = "$(INDEXING_PROJECT_DIR__NO)";
				INDEXING_PROJECT_DIR__NO = "$(PROJECT_DIR)";
				INDEXING_PROJECT_DIR__YES = "/tmp/workspace/bazel-output-base/rules_xcodeproj.noindex/indexbuild_output_base/execroot/_main";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = $(PROJECT_FILE_PATH)/rules_xcodeproj;
				LD = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LDPLUSPLUS = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = (
				);
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool.sh";
				ONLY_ACTIVE_ARCH = YES;
				RESOLVED_REPOSITORIES = "";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SCHEME_TARGET_IDS_FILE = "$(OBJROOT)/scheme_target_ids";
				SRCROOT = /tmp/workspace;
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EXEC = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_USE_INTEGRATED_DRIVER = NO;
				SWIFT_VERSION = 5.0;
				TARGET_TEMP_DIR = "$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)";
				USE_HEADERMAP = NO;
				VALIDATE_WORKSPACE = NO;
				_BAZEL_OUTPUT_BASE = "$(PROJECT_DIR)/../..";
			};
			name = Release;
		};
		000000000000000000000002 /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000005 /* Debug */,
				000000000000000000000006 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000004 /* Build configuration list for PBXProject */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = enGB;
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000002 /* /tmp/workspace */;
			productRefGroup = 000000000000000000000003 /* Products */;
			projectDirPath = /tmp/workspace/bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
				ORGANIZATIONNAME = MobileNativeFoundation;
```

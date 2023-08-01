import CustomDump
import GeneratorCommon
import PBXProj
import XCTest

@testable import pbxproj_prefix

class PBXProjectBuildSettingsTests: XCTestCase {
    func test_bazel() {
        // Arrange

        let buildMode: BuildMode = .bazel
        let indexImport = "external/index-import"
        let indexingProjectDir = "/some/indexing/project dir"
        let projectDir = "/some/project dir"
        let resolvedRepositories = #""" "/tmp/workspace""#
        let workspace = "/Users/TimApple/Star Board"

        // The tabs for indenting are intentional
        let expectedBuildSettings = #"""
{
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
				INDEXING_PROJECT_DIR__NO = "/some/project dir";
				INDEXING_PROJECT_DIR__YES = "/some/indexing/project dir";
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LDPLUSPLUS = "$(BAZEL_INTEGRATION_DIR)/ld.sh";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool.sh";
				ONLY_ACTIVE_ARCH = YES;
				PROJECT_DIR = "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SCHEME_TARGET_IDS_FILE = "$(OBJROOT)/scheme_target_ids";
				SRCROOT = "/Users/TimApple/Star Board";
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
			}
"""#

        // Act

        let buildSettings = Generator.pbxProjectBuildSettings(
            buildMode: buildMode,
            indexImport: indexImport,
            indexingProjectDir: indexingProjectDir,
            projectDir: projectDir,
            resolvedRepositories: resolvedRepositories,
            workspace: workspace,
            createBuildSettingsAttribute: CreateBuildSettingsAttribute()
        )

        // Assert

        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }

    func test_xcode() {
        // Arrange

        let buildMode: BuildMode = .xcode
        let indexImport = "external/index-import"
        let indexingProjectDir = "/some/indexing/project_dir"
        let projectDir = "/some/project_dir"
        let resolvedRepositories = #""" "/tmp/workspace""#
        let workspace = "/Users/TimApple/StarBoard"

        // The tabs for indenting are intentional
        let expectedBuildSettings = #"""
{
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
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_MODULES_AUTOLINK = NO;
				CONFIGURATION_BUILD_DIR = "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)";
				COPY_PHASE_STRIP = NO;
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
				INDEXING_PROJECT_DIR__NO = /some/project_dir;
				INDEXING_PROJECT_DIR__YES = /some/indexing/project_dir;
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				ONLY_ACTIVE_ARCH = YES;
				PROJECT_DIR = "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = xcode;
				SCHEME_TARGET_IDS_FILE = "$(OBJROOT)/scheme_target_ids";
				SRCROOT = /Users/TimApple/StarBoard;
				SUPPORTS_MACCATALYST = NO;
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
				TARGET_TEMP_DIR = "$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)";
				USE_HEADERMAP = NO;
				VALIDATE_WORKSPACE = NO;
				_BAZEL_OUTPUT_BASE = "$(PROJECT_DIR)/../..";
			}
"""#

        // Act

        let buildSettings = Generator.pbxProjectBuildSettings(
            buildMode: buildMode,
            indexImport: indexImport,
            indexingProjectDir: indexingProjectDir,
            projectDir: projectDir,
            resolvedRepositories: resolvedRepositories,
            workspace: workspace,
            createBuildSettingsAttribute: CreateBuildSettingsAttribute()
        )

        // Assert

        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }
}

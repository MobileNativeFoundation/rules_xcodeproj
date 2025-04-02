import CustomDump
import PBXProj
import ToolCommon
import XCTest

@testable import pbxproj_prefix

class PBXProjectBuildSettingsTests: XCTestCase {
    func test() {
        // Arrange

        let config = "rxcp_custom_config"
        let importIndexBuildIndexstores = false
        let indexImport = "external/index-import"
        let indexingProjectDir = "/some/indexing/project dir"
        let projectDir = "/some/project dir"
        let resolvedRepositories = #""" "/tmp/workspace""#
        let workspace = "/Users/TimApple/Star Board"

        // The tabs for indenting are intentional
        let expectedBuildSettings = #"""
{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS = NO;
				BAZEL_CONFIG = rxcp_custom_config;
				BAZEL_EXTERNAL = "$(BAZEL_OUTPUT_BASE)/external";
				BAZEL_INTEGRATION_DIR = "$(INTERNAL_DIR)/bazel";
				BAZEL_LLDB_INIT = "$(HOME)/.lldbinit-rules_xcodeproj";
				BAZEL_OUT = "$(PROJECT_DIR)/bazel-out";
				BAZEL_OUTPUT_BASE = "$(_BAZEL_OUTPUT_BASE:standardizepath)";
				BAZEL_WORKSPACE_ROOT = "$(SRCROOT)";
				BUILD_DIR = "$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)";
				BUILD_MARKER_FILE = "$(OBJROOT)/build_marker";
				BUILD_WORKSPACE_DIRECTORY = "$(SRCROOT)";
				CC = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_MODULES_AUTOLINK = NO;
				CODE_SIGNING_ALLOWED = NO;
				CODE_SIGN_STYLE = Manual;
				CONFIGURATION_BUILD_DIR = "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)";
				COPY_PHASE_STRIP = NO;
				CXX = "$(BAZEL_INTEGRATION_DIR)/clang.sh";
				DEBUG_INFORMATION_FORMAT = dwarf;
				DSTROOT = "$(PROJECT_TEMP_DIR)";
				ENABLE_DEBUG_DYLIB = NO;
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IMPORT_INDEX_BUILD_INDEXSTORES = NO;
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool";
				ONLY_ACTIVE_ARCH = YES;
				PROJECT_DIR = "/some/project dir";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SRCROOT = "/Users/TimApple/Star Board";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
				TAPI_EXEC = /usr/bin/true;
				TARGET_TEMP_DIR = "$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)";
				USE_HEADERMAP = NO;
				VALIDATE_WORKSPACE = NO;
				_BAZEL_OUTPUT_BASE = "$(PROJECT_DIR)/../..";
			}
"""#

        // Act

        let buildSettings = Generator.pbxProjectBuildSettings(
            config: config,
            importIndexBuildIndexstores: importIndexBuildIndexstores,
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

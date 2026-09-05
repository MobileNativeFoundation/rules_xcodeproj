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
        let legacyIndexImport = "external/legacy-index-import"
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
				BAZEL_LLDB_INIT = "$(PROJECT_FILE_PATH)/rules_xcodeproj/bazel.lldbinit";
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
				ENABLE_DEBUG_DYLIB = YES;
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IMPORT_INDEX_BUILD_INDEXSTORES = NO;
				INDEXING_PROJECT_DIR__ = "$(INDEXING_PROJECT_DIR__NO)";
				INDEXING_PROJECT_DIR__NO = "/some/project dir";
				INDEXING_PROJECT_DIR__YES = "/some/indexing/project dir";
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD = "$(LD__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS = "$(LDPLUSPLUS__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang++";
				LDPLUSPLUS__ = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__NO = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				LD_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang";
				LD__ = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__NO = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LEGACY_INDEX_IMPORT = "$(BAZEL_EXTERNAL)/legacy-index-import";
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool";
				ONLY_ACTIVE_ARCH = YES;
				PREVIEW_SDK_LIBRARY_SEARCH_PATH = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__$(ENABLE_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__ = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__NO = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__YES = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__ = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__NO = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__YES = "$(SDKROOT)/usr/lib";
				PROJECT_DIR = "/some/project dir";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SRCROOT = "/Users/TimApple/Star Board";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EXEC = "$(SWIFT_EXEC_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_EXEC_LEGACY__ = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__NO = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__YES = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__ = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__NO = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__YES = "$(DT_TOOLCHAIN_DIR)/usr/bin/swiftc";
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_USE_INTEGRATED_DRIVER = "$(SWIFT_USE_INTEGRATED_DRIVER_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__ = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__NO = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__YES = NO;
				SWIFT_USE_INTEGRATED_DRIVER__ = NO;
				SWIFT_USE_INTEGRATED_DRIVER__NO = NO;
				SWIFT_USE_INTEGRATED_DRIVER__YES = YES;
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
            createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
            importIndexBuildIndexstores: importIndexBuildIndexstores,
            indexImport: indexImport,
            indexingProjectDir: indexingProjectDir,
            legacyIndexImport: legacyIndexImport,
            projectDir: projectDir,
            resolvedRepositories: resolvedRepositories,
            separateIndexBuildOutputBase: false,
            suppressCoverageBuild: false,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }

    func testSuppressCoverageBuild() {
        let config = "rxcp_custom_config"
        let importIndexBuildIndexstores = false
        let legacyIndexImport = "external/legacy-index-import"
        let indexImport = "external/index-import"
        let indexingProjectDir = "/some/indexing/project dir"
        let projectDir = "/some/project dir"
        let resolvedRepositories = #""" "/tmp/workspace""#
        let workspace = "/Users/TimApple/Star Board"

        let expectedBuildSettings = #"""
{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS = NO;
				BAZEL_CONFIG = rxcp_custom_config;
				BAZEL_EXTERNAL = "$(BAZEL_OUTPUT_BASE)/external";
				BAZEL_INTEGRATION_DIR = "$(INTERNAL_DIR)/bazel";
				BAZEL_LLDB_INIT = "$(PROJECT_FILE_PATH)/rules_xcodeproj/bazel.lldbinit";
				BAZEL_OUT = "$(PROJECT_DIR)/bazel-out";
				BAZEL_OUTPUT_BASE = "$(_BAZEL_OUTPUT_BASE:standardizepath)";
				BAZEL_SUPPRESS_COVERAGE_BUILD = YES;
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
				ENABLE_DEBUG_DYLIB = YES;
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IMPORT_INDEX_BUILD_INDEXSTORES = NO;
				INDEXING_PROJECT_DIR__ = "$(INDEXING_PROJECT_DIR__NO)";
				INDEXING_PROJECT_DIR__NO = "/some/project dir";
				INDEXING_PROJECT_DIR__YES = "/some/indexing/project dir";
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD = "$(LD__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS = "$(LDPLUSPLUS__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang++";
				LDPLUSPLUS__ = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__NO = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				LD_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang";
				LD__ = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__NO = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LEGACY_INDEX_IMPORT = "$(BAZEL_EXTERNAL)/legacy-index-import";
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool";
				ONLY_ACTIVE_ARCH = YES;
				PREVIEW_SDK_LIBRARY_SEARCH_PATH = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__$(ENABLE_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__ = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__NO = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__YES = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__ = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__NO = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__YES = "$(SDKROOT)/usr/lib";
				PROJECT_DIR = "/some/project dir";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SRCROOT = "/Users/TimApple/Star Board";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EXEC = "$(SWIFT_EXEC_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_EXEC_LEGACY__ = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__NO = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__YES = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__ = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__NO = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__YES = "$(DT_TOOLCHAIN_DIR)/usr/bin/swiftc";
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_USE_INTEGRATED_DRIVER = "$(SWIFT_USE_INTEGRATED_DRIVER_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__ = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__NO = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__YES = NO;
				SWIFT_USE_INTEGRATED_DRIVER__ = NO;
				SWIFT_USE_INTEGRATED_DRIVER__NO = NO;
				SWIFT_USE_INTEGRATED_DRIVER__YES = YES;
				SWIFT_VERSION = 5.0;
				TAPI_EXEC = /usr/bin/true;
				TARGET_TEMP_DIR = "$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)";
				USE_HEADERMAP = NO;
				VALIDATE_WORKSPACE = NO;
				_BAZEL_OUTPUT_BASE = "$(PROJECT_DIR)/../..";
			}
"""#

        let buildSettings = Generator.pbxProjectBuildSettings(
            config: config,
            createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
            importIndexBuildIndexstores: importIndexBuildIndexstores,
            indexImport: indexImport,
            indexingProjectDir: indexingProjectDir,
            legacyIndexImport: legacyIndexImport,
            projectDir: projectDir,
            resolvedRepositories: resolvedRepositories,
            separateIndexBuildOutputBase: false,
            suppressCoverageBuild: true,
            workspace: workspace
        )
        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }

    func testSeparateIndexOutputBase() {
        // Arrange

        let config = "rxcp_custom_config"
        let importIndexBuildIndexstores = false
        let legacyIndexImport = "external/legacy-index-import"
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
				BAZEL_LLDB_INIT = "$(PROJECT_FILE_PATH)/rules_xcodeproj/bazel.lldbinit";
				BAZEL_OUT = "$(PROJECT_DIR)/bazel-out";
				BAZEL_OUTPUT_BASE = "$(_BAZEL_OUTPUT_BASE:standardizepath)";
				BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE = YES;
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
				ENABLE_DEBUG_DYLIB = YES;
				ENABLE_DEFAULT_SEARCH_PATHS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IMPORT_INDEX_BUILD_INDEXSTORES = NO;
				INDEXING_PROJECT_DIR__ = "$(INDEXING_PROJECT_DIR__NO)";
				INDEXING_PROJECT_DIR__NO = "/some/project dir";
				INDEXING_PROJECT_DIR__YES = "/some/indexing/project dir";
				INDEX_DATA_STORE_DIR = "$(INDEX_DATA_STORE_DIR)";
				INDEX_FORCE_SCRIPT_EXECUTION = YES;
				INDEX_IMPORT = "$(BAZEL_EXTERNAL)/index-import";
				INSTALL_PATH = "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin";
				INTERNAL_DIR = "$(PROJECT_FILE_PATH)/rules_xcodeproj";
				LD = "$(LD__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS = "$(LDPLUSPLUS__$(ENABLE_PREVIEWS))";
				LDPLUSPLUS_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LDPLUSPLUS_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang++";
				LDPLUSPLUS__ = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__NO = "$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LDPLUSPLUS__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_DYLIB_INSTALL_NAME = "";
				LD_OBJC_ABI_VERSION = "";
				LD_RUNPATH_SEARCH_PATHS = "";
				LD_XOJIT__ = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__NO = "$(BAZEL_INTEGRATION_DIR)/ld";
				LD_XOJIT__YES = "$(BAZEL_INTEGRATION_DIR)/clang";
				LD__ = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__NO = "$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				LD__YES = "$(BAZEL_INTEGRATION_DIR)/ld";
				LEGACY_INDEX_IMPORT = "$(BAZEL_EXTERNAL)/legacy-index-import";
				LIBTOOL = "$(BAZEL_INTEGRATION_DIR)/libtool";
				ONLY_ACTIVE_ARCH = YES;
				PREVIEW_SDK_LIBRARY_SEARCH_PATH = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__$(ENABLE_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__ = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__NO = "$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__YES = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__ = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__NO = "";
				PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__YES = "$(SDKROOT)/usr/lib";
				PROJECT_DIR = "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))";
				RESOLVED_REPOSITORIES = "\"\" \"/tmp/workspace\"";
				RULES_XCODEPROJ_BUILD_MODE = bazel;
				SRCROOT = "/Users/TimApple/Star Board";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EXEC = "$(SWIFT_EXEC_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_EXEC_LEGACY__ = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__NO = "$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_EXEC_LEGACY__YES = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__ = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__NO = "$(BAZEL_INTEGRATION_DIR)/swiftc";
				SWIFT_EXEC__YES = "$(DT_TOOLCHAIN_DIR)/usr/bin/swiftc";
				SWIFT_OBJC_INTERFACE_HEADER_NAME = "";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_USE_INTEGRATED_DRIVER = "$(SWIFT_USE_INTEGRATED_DRIVER_LEGACY__$(ENABLE_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__ = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__NO = "$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))";
				SWIFT_USE_INTEGRATED_DRIVER_LEGACY__YES = NO;
				SWIFT_USE_INTEGRATED_DRIVER__ = NO;
				SWIFT_USE_INTEGRATED_DRIVER__NO = NO;
				SWIFT_USE_INTEGRATED_DRIVER__YES = YES;
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
            createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
            importIndexBuildIndexstores: importIndexBuildIndexstores,
            indexImport: indexImport,
            indexingProjectDir: indexingProjectDir,
            legacyIndexImport: legacyIndexImport,
            projectDir: projectDir,
            resolvedRepositories: resolvedRepositories,
            separateIndexBuildOutputBase: true,
            suppressCoverageBuild: false,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(buildSettings, expectedBuildSettings)
    }
}

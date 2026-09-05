import PBXProj
import ToolCommon

extension Generator {
    /// Calculates the `buildSettings` attribute of the `XCBuildConfiguration`
    /// objects used by the `PBXProject` element.
    ///
    /// - Parameters:
    ///   - config: The value to be used for the `BAZEL_CONFIG` build setting.
    ///   - importIndexBuildIndexstores: Whether to import index build
    ///     indexstores.
    ///   - legacyIndexImport: The Bazel execution root relative path to the
    ///     `index_import` (version 5.8) executable.
    ///   - indexImport: The Bazel execution root relative path to the
    ///     `index_import` (version 6.1+) executable.
    ///   - indexingProjectDir: The value returned from
    ///     `Generator.indexingProjectDir()`.
    ///   - projectDir: The value returned from `Generator.projectDir()`.
    ///   - resolvedRepositories: The value to be used for the
    ///     `RESOLVED_REPOSITORIES` build setting.
    ///   - workspace: The absolute path to the Bazel workspace.
    static func pbxProjectBuildSettings(
        config: String,
        createBuildSettingsAttribute: CreateBuildSettingsAttribute,
        importIndexBuildIndexstores: Bool,
        indexImport: String,
        indexingProjectDir: String,
        legacyIndexImport: String,
        projectDir: String,
        resolvedRepositories: String,
        separateIndexBuildOutputBase: Bool,
        suppressCoverageBuild: Bool,
        workspace: String
    ) -> String {
        var buildSettings: [BuildSetting] = [
            .init(key: "ALWAYS_SEARCH_USER_PATHS", value: "NO"),
            .init(
                key: "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS",
                value: "NO"
            ),
            .init(key: "BAZEL_CONFIG", value: config.pbxProjEscaped),
            .init(
                key: "BAZEL_EXTERNAL",
                value: #""$(BAZEL_OUTPUT_BASE)/external""#
            ),
            .init(
                key: "BAZEL_INTEGRATION_DIR",
                value: #""$(INTERNAL_DIR)/bazel""#
            ),
            .init(
                key: "BAZEL_LLDB_INIT",
                value: #""$(PROJECT_FILE_PATH)/rules_xcodeproj/bazel.lldbinit""#
            ),
            .init(
                key: "BAZEL_OUT",
                value: #""$(PROJECT_DIR)/bazel-out""#
            ),
            .init(
                key: "BAZEL_OUTPUT_BASE",
                value: #""$(_BAZEL_OUTPUT_BASE:standardizepath)""#
            ),
            .init(
                key: "BAZEL_WORKSPACE_ROOT",
                value: #""$(SRCROOT)""#
            ),
            .init(
                key: "BUILD_DIR",
                value:
                    #""$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)""#
            ),
            .init(
                key: "BUILD_MARKER_FILE",
                value: #""$(OBJROOT)/build_marker""#
            ),
            .init(
                key: "BUILD_WORKSPACE_DIRECTORY",
                value: #""$(SRCROOT)""#
            ),
            .init(key: "CC", value: #""$(BAZEL_INTEGRATION_DIR)/clang.sh""#),
            .init(key: "CLANG_ENABLE_OBJC_ARC", value: "YES"),
            .init(key: "CLANG_MODULES_AUTOLINK", value: "NO"),
            .init(key: "CODE_SIGNING_ALLOWED", value: "NO"),
            .init(key: "CODE_SIGN_STYLE", value: "Manual"),
            .init(
                key: "CONFIGURATION_BUILD_DIR",
                value: #""$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)""#
            ),
            .init(key: "COPY_PHASE_STRIP", value: "NO"),
            .init(key: "CXX", value: #""$(BAZEL_INTEGRATION_DIR)/clang.sh""#),
            .init(key: "DEBUG_INFORMATION_FORMAT", value: "dwarf"),
            .init(key: "DSTROOT", value: #""$(PROJECT_TEMP_DIR)""#),
            .init(key: "ENABLE_DEBUG_DYLIB", value: "YES"),
            .init(key: "ENABLE_DEFAULT_SEARCH_PATHS", value: "NO"),
            .init(key: "ENABLE_STRICT_OBJC_MSGSEND", value: "YES"),
            .init(key: "ENABLE_USER_SCRIPT_SANDBOXING", value: "NO"),
            .init(key: "GCC_OPTIMIZATION_LEVEL", value: "0"),
            .init(key: "LD", value: #""$(LD__$(ENABLE_PREVIEWS))""#),
            .init(
                key: "LD__",
                value: #""$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "LD__NO",
                value: #""$(LD_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(key: "LD__YES", value: #""$(BAZEL_INTEGRATION_DIR)/ld""#),
            .init(key: "LD_XOJIT__", value: #""$(BAZEL_INTEGRATION_DIR)/ld""#),
            .init(key: "LD_XOJIT__NO", value: #""$(BAZEL_INTEGRATION_DIR)/ld""#),
            .init(
                key: "LD_XOJIT__YES",
                value: #""$(BAZEL_INTEGRATION_DIR)/clang""#
            ),
            .init(
                key: "LDPLUSPLUS",
                value: #""$(LDPLUSPLUS__$(ENABLE_PREVIEWS))""#
            ),
            .init(
                key: "LDPLUSPLUS__",
                value: #""$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "LDPLUSPLUS__NO",
                value: #""$(LDPLUSPLUS_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "LDPLUSPLUS__YES",
                value: #""$(BAZEL_INTEGRATION_DIR)/ld""#
            ),
            .init(
                key: "LDPLUSPLUS_XOJIT__",
                value: #""$(BAZEL_INTEGRATION_DIR)/ld""#
            ),
            .init(
                key: "LDPLUSPLUS_XOJIT__NO",
                value: #""$(BAZEL_INTEGRATION_DIR)/ld""#
            ),
            .init(
                key: "LDPLUSPLUS_XOJIT__YES",
                value: #""$(BAZEL_INTEGRATION_DIR)/clang++""#
            ),
            .init(
                key: "LIBTOOL",
                value: #""$(BAZEL_INTEGRATION_DIR)/libtool""#
            ),
            .init(
                key: "IMPORT_INDEX_BUILD_INDEXSTORES",
                value: importIndexBuildIndexstores ? "YES" : "NO"
            ),
            .init(
                key: "INDEXING_PROJECT_DIR__",
                value: #""$(INDEXING_PROJECT_DIR__NO)""#
            ),
            .init(
                key: "INDEXING_PROJECT_DIR__NO",
                value: projectDir.pbxProjEscaped
            ),
            .init(
                key: "INDEXING_PROJECT_DIR__YES",
                value: indexingProjectDir.pbxProjEscaped
            ),
            .init(
                key: "INDEX_DATA_STORE_DIR",
                value: #""$(INDEX_DATA_STORE_DIR)""#
            ),
            .init(key: "INDEX_FORCE_SCRIPT_EXECUTION", value: "YES"),
            .init(
                key: "INDEX_IMPORT",
                value: indexImport
                    .executionRootBasedBuildSettingPath
                    .pbxProjEscaped
            ),
            .init(
                key: "INSTALL_PATH",
                value: #""$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin""#
            ),
            .init(
                key: "INTERNAL_DIR",
                value: #""$(PROJECT_FILE_PATH)/rules_xcodeproj""#
            ),
            .init(key: "LD_DYLIB_INSTALL_NAME", value: #""""#),
            .init(key: "LD_OBJC_ABI_VERSION", value: #""""#),
            .init(key: "LD_RUNPATH_SEARCH_PATHS", value: #""""#),
            .init(
                key: "LEGACY_INDEX_IMPORT",
                value: legacyIndexImport
                    .executionRootBasedBuildSettingPath
                    .pbxProjEscaped
            ),
            .init(key: "ONLY_ACTIVE_ARCH", value: "YES"),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH",
                value:
                    #""$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__$(ENABLE_PREVIEWS))""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__",
                value:
                    #""$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__NO",
                value:
                    #""$(PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_LEGACY__YES",
                value: #""""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__",
                value: #""""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__NO",
                value: #""""#
            ),
            .init(
                key: "PREVIEW_SDK_LIBRARY_SEARCH_PATH_XOJIT__YES",
                value: #""$(SDKROOT)/usr/lib""#
            ),
            .init(
                key: "RESOLVED_REPOSITORIES",
                value: resolvedRepositories.pbxProjEscaped
            ),
            .init(key: "RULES_XCODEPROJ_BUILD_MODE", value: "bazel"),
            .init(key: "SRCROOT", value: workspace.pbxProjEscaped),
            .init(key: "SUPPORTS_MACCATALYST", value: "NO"),
            .init(
                key: "SWIFT_EXEC",
                value: #""$(SWIFT_EXEC_LEGACY__$(ENABLE_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_EXEC_LEGACY__",
                value: #""$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_EXEC_LEGACY__NO",
                value: #""$(SWIFT_EXEC__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_EXEC_LEGACY__YES",
                value: #""$(BAZEL_INTEGRATION_DIR)/swiftc""#
            ),
            .init(
                key: "SWIFT_EXEC__",
                value: #""$(BAZEL_INTEGRATION_DIR)/swiftc""#
            ),
            .init(
                key: "SWIFT_EXEC__NO",
                value: #""$(BAZEL_INTEGRATION_DIR)/swiftc""#
            ),
            .init(
                key: "SWIFT_EXEC__YES",
                value: #""$(DT_TOOLCHAIN_DIR)/usr/bin/swiftc""#
            ),
            .init(key: "SWIFT_OBJC_INTERFACE_HEADER_NAME", value: #""""#),
            .init(key: "SWIFT_OPTIMIZATION_LEVEL", value: #""-Onone""#),
            .init(
                key: "SWIFT_USE_INTEGRATED_DRIVER",
                value:
                    #""$(SWIFT_USE_INTEGRATED_DRIVER_LEGACY__$(ENABLE_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_USE_INTEGRATED_DRIVER_LEGACY__",
                value:
                    #""$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_USE_INTEGRATED_DRIVER_LEGACY__NO",
                value:
                    #""$(SWIFT_USE_INTEGRATED_DRIVER__$(ENABLE_XOJIT_PREVIEWS))""#
            ),
            .init(
                key: "SWIFT_USE_INTEGRATED_DRIVER_LEGACY__YES",
                value: "NO"
            ),
            .init(key: "SWIFT_USE_INTEGRATED_DRIVER__", value: "NO"),
            .init(key: "SWIFT_USE_INTEGRATED_DRIVER__NO", value: "NO"),
            .init(key: "SWIFT_USE_INTEGRATED_DRIVER__YES", value: "YES"),
            .init(key: "SWIFT_VERSION", value: "5.0"),
            .init(key: "TAPI_EXEC", value: "/usr/bin/true"),
            .init(
                key: "TARGET_TEMP_DIR",
                value: #"""
"$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)"
"""#
            ),
            .init(key: "USE_HEADERMAP", value: "NO"),
            .init(key: "VALIDATE_WORKSPACE", value: "NO"),
            .init(
                key: "_BAZEL_OUTPUT_BASE",
                value: #""$(PROJECT_DIR)/../..""#
            ),
        ]
        if suppressCoverageBuild {
            buildSettings.append(
                .init(
                    key: "BAZEL_SUPPRESS_COVERAGE_BUILD",
                    value: "YES"
                )
            )
        }
        if separateIndexBuildOutputBase {
            buildSettings.append(contentsOf: [
                .init(
                    key: "BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE",
                    value: "YES"
                ),
                .init(
                    key: "PROJECT_DIR",
                    value:
                        #""$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))""#
                ),
            ])
        } else {
            buildSettings.append(
                .init(
                    key: "PROJECT_DIR",
                    value: projectDir.pbxProjEscaped
                )
            )
        }
        return createBuildSettingsAttribute(buildSettings: buildSettings)
    }
}

import GeneratorCommon
import PBXProj

extension Generator {
    /// Calculates the `buildSettings` attribute of the `XCBuildConfiguration`
    /// objects used by the `PBXProject` element.
    ///
    /// - Parameters:
    ///   - buildMode: The `BuildMode`.
    ///   - indexImport: The Bazel execution root relative path to the
    ///     `index_import` executable.
    ///   - indexingProjectDir: The value returned from
    ///     `Generator.indexingProjectDir()`.
    ///   - projectDir: The value returned from `Generator.projectDir()`.
    ///   - resolvedRepositories: The value to be used for the
    ///     `RESOLVED_REPOSITORIES` build setting.
    ///   - workspace: The absolute path to the Bazel workspace.
    static func pbxProjectBuildSettings(
        buildMode: BuildMode,
        indexImport: String,
        indexingProjectDir: String,
        projectDir: String,
        resolvedRepositories: String,
        workspace: String,
        createBuildSettingsAttribute: CreateBuildSettingsAttribute
    ) -> String {
        var buildSettings: [BuildSetting] = [
            .init(key: "ALWAYS_SEARCH_USER_PATHS", value: "NO"),
            .init(key: "BAZEL_CONFIG", value: "rules_xcodeproj"),
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
                value: #""$(HOME)/.lldbinit-rules_xcodeproj""#
            ),
            .init(
                key: "BAZEL_OUT",
                value: #""$(PROJECT_DIR)/bazel-out""#),
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
                key: "BUILD_WORKSPACE_DIRECTORY",
                value: #""$(SRCROOT)""#
            ),
            .init(
                key: "BUILT_PRODUCTS_DIR",
                value: #"""
"$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))"
"""#
            ),
            .init(key: "CLANG_ENABLE_OBJC_ARC", value: "YES"),
            .init(key: "CLANG_MODULES_AUTOLINK", value: "NO"),
            .init(
                key: "CONFIGURATION_BUILD_DIR",
                value: #""$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)""#
            ),
            .init(key: "COPY_PHASE_STRIP", value: "NO"),
            .init(key: "DEBUG_INFORMATION_FORMAT", value: "dwarf"),
            .init(
                key: "DEPLOYMENT_LOCATION",
                value: #"""
"$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA))"
"""#
            ),
            .init(key: "DSTROOT", value: #""$(PROJECT_TEMP_DIR)""#),
            .init(key: "ENABLE_DEFAULT_SEARCH_PATHS", value: "NO"),
            .init(key: "ENABLE_STRICT_OBJC_MSGSEND", value: "YES"),
            .init(key: "GCC_OPTIMIZATION_LEVEL", value: "0"),
            .init(
                key: "INDEXING_BUILT_PRODUCTS_DIR__",
                value: #""$(INDEXING_BUILT_PRODUCTS_DIR__NO)""#
            ),
            .init(
                key: "INDEXING_BUILT_PRODUCTS_DIR__NO",
                value: #""$(BUILD_DIR)""#
            ),
            .init(
                key: "INDEXING_BUILT_PRODUCTS_DIR__YES",
                value: #""$(CONFIGURATION_BUILD_DIR)""#
            ),
            .init(
                key: "INDEXING_DEPLOYMENT_LOCATION__",
                value: #""$(INDEXING_DEPLOYMENT_LOCATION__NO)""#
            ),
            .init(key: "INDEXING_DEPLOYMENT_LOCATION__NO", value: "YES"),
            .init(key: "INDEXING_DEPLOYMENT_LOCATION__YES", value: "NO"),
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
            .init(key: "ONLY_ACTIVE_ARCH", value: "YES"),
            .init(
                key: "PROJECT_DIR",
                value:
                    #""$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))""#
            ),
            .init(
                key: "RESOLVED_REPOSITORIES",
                value: resolvedRepositories.pbxProjEscaped
            ),
            .init(key: "RULES_XCODEPROJ_BUILD_MODE", value: buildMode.rawValue),
            .init(
                key: "SCHEME_TARGET_IDS_FILE",
                value: #""$(OBJROOT)/scheme_target_ids""#
            ),
            .init(key: "SRCROOT", value: workspace.pbxProjEscaped),
            .init(key: "SUPPORTS_MACCATALYST", value: "NO"),
            .init(key: "SWIFT_OBJC_INTERFACE_HEADER_NAME", value: #""""#),
            .init(key: "SWIFT_OPTIMIZATION_LEVEL", value: #""-Onone""#),
            .init(key: "SWIFT_VERSION", value: "5.0"),
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

        if buildMode.usesBazelModeBuildScripts {
            buildSettings.append(contentsOf: [
                .init(
                    key: "CC",
                    value: #""$(BAZEL_INTEGRATION_DIR)/clang.sh""#
                ),
                .init(
                    key: "CXX",
                    value: #""$(BAZEL_INTEGRATION_DIR)/clang.sh""#
                ),
                .init(key: "CODE_SIGNING_ALLOWED", value: "NO"),
                .init(
                    key: "LD",
                    value: #""$(BAZEL_INTEGRATION_DIR)/ld.sh""#
                ),
                .init(
                    key: "LDPLUSPLUS",
                    value: #""$(BAZEL_INTEGRATION_DIR)/ld.sh""#
                ),
                .init(
                    key: "LIBTOOL",
                    value: #""$(BAZEL_INTEGRATION_DIR)/libtool.sh""#
                ),
                .init(
                    key: "SWIFT_EXEC",
                    value: #""$(BAZEL_INTEGRATION_DIR)/swiftc""#
                ),
                .init(key: "SWIFT_USE_INTEGRATED_DRIVER", value: "NO"),
            ])
        }

        return createBuildSettingsAttribute(buildSettings: buildSettings)
    }
}

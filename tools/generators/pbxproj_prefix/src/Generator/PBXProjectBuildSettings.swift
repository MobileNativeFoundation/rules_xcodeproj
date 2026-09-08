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
        nativePreviews: Bool = false,
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
            .init(key: "BAZEL_NATIVE_PREVIEWS", value: nativePreviews ? "YES" : "NO"),
            .init(key: "BAZEL_SWIFT_COMPILATION_MODE", value: nativePreviews ? "singlefile" : "wholemodule"),
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

            .init(key: "CLANG_ENABLE_OBJC_ARC", value: "YES"),
            .init(key: "CLANG_MODULES_AUTOLINK", value: "NO"),
            .init(key: "CODE_SIGNING_ALLOWED", value: "NO"),
            .init(key: "CODE_SIGN_STYLE", value: "Manual"),
            .init(
                key: "CONFIGURATION_BUILD_DIR",
                value: #""$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)""#
            ),
            .init(key: "COPY_PHASE_STRIP", value: "NO"),

            .init(key: "DEBUG_INFORMATION_FORMAT", value: "dwarf"),
            .init(key: "DSTROOT", value: #""$(PROJECT_TEMP_DIR)""#),
            .init(key: "ENABLE_DEBUG_DYLIB", value: nativePreviews ? "YES" : "NO"),
            .init(key: "ENABLE_DEFAULT_SEARCH_PATHS", value: "NO"),
            .init(key: "ENABLE_STRICT_OBJC_MSGSEND", value: "YES"),
            .init(key: "ENABLE_USER_SCRIPT_SANDBOXING", value: "NO"),
            .init(key: "GCC_OPTIMIZATION_LEVEL", value: "0"),
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
                key: "RESOLVED_REPOSITORIES",
                value: resolvedRepositories.pbxProjEscaped
            ),
            .init(key: "RULES_XCODEPROJ_BUILD_MODE", value: "bazel"),
            .init(key: "SRCROOT", value: workspace.pbxProjEscaped),
            .init(key: "SUPPORTS_MACCATALYST", value: "NO"),
            .init(key: "SWIFT_OBJC_INTERFACE_HEADER_NAME", value: #""""#),
            .init(key: "SWIFT_OPTIMIZATION_LEVEL", value: #""-Onone""#),
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

        // Native ownership is an explicit configuration choice, available before
        // Xcode plans its tasks. ENABLE_XOJIT_PREVIEWS is also set for ordinary
        // Debug builds and cannot select the owner.
        for (key, bazelValue, nativeValue) in [
            ("CC", "$(BAZEL_INTEGRATION_DIR)/clang.sh", "$(DT_TOOLCHAIN_DIR)/usr/bin/clang"),
            ("CXX", "$(BAZEL_INTEGRATION_DIR)/clang.sh", "$(DT_TOOLCHAIN_DIR)/usr/bin/clang++"),
            ("LD", "$(BAZEL_INTEGRATION_DIR)/ld", "$(DT_TOOLCHAIN_DIR)/usr/bin/clang"),
            ("LDPLUSPLUS", "$(BAZEL_INTEGRATION_DIR)/ld", "$(DT_TOOLCHAIN_DIR)/usr/bin/clang++"),
            ("LIBTOOL", "$(BAZEL_INTEGRATION_DIR)/libtool", "$(BAZEL_INTEGRATION_DIR)/xojit/libtool"),
            ("SWIFT_EXEC", "$(BAZEL_INTEGRATION_DIR)/swiftc", "$(DT_TOOLCHAIN_DIR)/usr/bin/swiftc"),
            ("SWIFT_USE_INTEGRATED_DRIVER", "NO", "YES"),
            ("PREVIEW_SDK_LIBRARY_SEARCH_PATH", "", "$(SDKROOT)/usr/lib"),
        ] {
            buildSettings.append(
                .init(key: key, value: (nativePreviews ? nativeValue : bazelValue).pbxProjEscaped)
            )
        }
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

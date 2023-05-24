import GeneratorCommon
import PBXProj

extension Generator {
    /// Calculates the `buildSettings` attribute of the `XCBuildConfiguration`
    /// elements used by the `PBXProject` element.
    ///
    /// - Parameters:
    ///   - buildMode: The `BuildMode`.
    ///   - indexingProjectDir: The value returned from
    ///     `Generator.indexingProjectDir()`.
    ///   - workspace: The absolute path to the Bazel workspace.
    static func pbxProjectBuildSettings(
        buildMode: BuildMode,
        indexingProjectDir: String,
        workspace: String
    ) -> String {
        var settings: [String: String] = [
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "BAZEL_CONFIG": "rules_xcodeproj",
            "BAZEL_EXTERNAL": "$(BAZEL_OUTPUT_BASE)/external".pbxProjEscaped,
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel".pbxProjEscaped,
            "BAZEL_LLDB_INIT":
                "$(HOME)/.lldbinit-rules_xcodeproj".pbxProjEscaped,
            "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out".pbxProjEscaped,
            "BAZEL_OUTPUT_BASE":
                "$(_BAZEL_OUTPUT_BASE:standardizepath)".pbxProjEscaped,
            "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)".pbxProjEscaped,
            "BUILD_DIR":
                "$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)"
                .pbxProjEscaped,
            "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)".pbxProjEscaped,
            "BUILT_PRODUCTS_DIR":
                "$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))"
                .pbxProjEscaped,
            "CLANG_ENABLE_OBJC_ARC": "YES",
            "CLANG_MODULES_AUTOLINK": "NO",
            "CONFIGURATION_BUILD_DIR": "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)"
                .pbxProjEscaped,
            "COPY_PHASE_STRIP": "NO",
            "CURRENT_EXECUTION_ROOT":
                "$(INDEXING_PROJECT_DIR__$(INDEX_ENABLE_BUILD_ARENA))"
                .pbxProjEscaped,
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "DEPLOYMENT_LOCATION":
                "$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA))"
                    .pbxProjEscaped,
            "DSTROOT": "$(PROJECT_TEMP_DIR)".pbxProjEscaped,
            "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "INDEXING_BUILT_PRODUCTS_DIR__":
                "$(INDEXING_BUILT_PRODUCTS_DIR__NO)".pbxProjEscaped,
            "INDEXING_BUILT_PRODUCTS_DIR__NO": "$(BUILD_DIR)".pbxProjEscaped,
            "INDEXING_BUILT_PRODUCTS_DIR__YES":
                "$(CONFIGURATION_BUILD_DIR)".pbxProjEscaped,
            "INDEXING_DEPLOYMENT_LOCATION__":
                "$(INDEXING_DEPLOYMENT_LOCATION__NO)".pbxProjEscaped,
            "INDEXING_DEPLOYMENT_LOCATION__NO": "YES",
            "INDEXING_DEPLOYMENT_LOCATION__YES": "NO",
            "INDEXING_PROJECT_DIR__":
                "$(INDEXING_PROJECT_DIR__NO)".pbxProjEscaped,
            "INDEXING_PROJECT_DIR__NO": "$(PROJECT_DIR)".pbxProjEscaped,
            "INDEXING_PROJECT_DIR__YES": indexingProjectDir.pbxProjEscaped,
            "INDEX_FORCE_SCRIPT_EXECUTION": "YES",
            "INSTALL_PATH":
                "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin".pbxProjEscaped,
            "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/rules_xcodeproj",
            "LD_DYLIB_INSTALL_NAME": "".pbxProjEscaped,
            "LD_OBJC_ABI_VERSION": "".pbxProjEscaped,
            "LD_RUNPATH_SEARCH_PATHS": "(\n\t\t\t\t)",
            "ONLY_ACTIVE_ARCH": "YES",
            // TODO: Set `RESOLVED_REPOSITORIES`
            "RESOLVED_REPOSITORIES": "".pbxProjEscaped,
            "RULES_XCODEPROJ_BUILD_MODE": buildMode.rawValue,
            "SCHEME_TARGET_IDS_FILE":
                "$(OBJROOT)/scheme_target_ids".pbxProjEscaped,
            "SRCROOT": workspace.pbxProjEscaped,
            "SUPPORTS_MACCATALYST": "NO",
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "".pbxProjEscaped,
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone".pbxProjEscaped,
            "SWIFT_VERSION": "5.0",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
"""
                .pbxProjEscaped,
            "USE_HEADERMAP": "NO",
            "VALIDATE_WORKSPACE": "NO",
            "_BAZEL_OUTPUT_BASE": "$(PROJECT_DIR)/../..".pbxProjEscaped,
        ]

        if buildMode.usesBazelModeBuildScripts {
            settings.merge([
                "CC": "$(BAZEL_INTEGRATION_DIR)/clang.sh".pbxProjEscaped,
                "CXX": "$(BAZEL_INTEGRATION_DIR)/clang.sh".pbxProjEscaped,
                "CODE_SIGNING_ALLOWED": "NO",
                "LD": "$(BAZEL_INTEGRATION_DIR)/ld.sh".pbxProjEscaped,
                "LDPLUSPLUS": "$(BAZEL_INTEGRATION_DIR)/ld.sh".pbxProjEscaped,
                "LIBTOOL": "$(BAZEL_INTEGRATION_DIR)/libtool.sh".pbxProjEscaped,
                "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc".pbxProjEscaped,
                "SWIFT_USE_INTEGRATED_DRIVER": "NO",
            ], uniquingKeysWith: { _, r in r })
        }

        // The tabs for indenting are intentional
        return #"""
{
\#(
    settings
        .sorted { $0.key < $1.key }
        .map { (key, value) in
            return "\t\t\t\t\(key) = \(value);"
        }
        .joined(separator: "\n")
)
			}
"""#
    }
}

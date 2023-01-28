import PathKit
import XcodeProj

extension Generator {
    /// Creates the `PBXProj` and `PBXProject` objects for the given `Project`.
    ///
    /// The `PBXProject` is also created and assigned as the `PBXProj`'s
    /// `rootObject`.
    static func createProject(
        buildMode: BuildMode,
        forFixtures: Bool,
        project: Project,
        directories: Directories
    ) -> PBXProj {
        let pbxProj = PBXProj()

        let nonRelativeProjectDir = directories.executionRoot

        let projectDir: Path
        if nonRelativeProjectDir.isRelative {
            projectDir = directories.projectRoot + nonRelativeProjectDir
        } else {
            projectDir = nonRelativeProjectDir
        }

        let srcRoot: String
        if forFixtures {
            srcRoot = (0 ..< nonRelativeProjectDir.components.count)
                .map { _ in ".." }
                .joined(separator: "/")
        } else {
            srcRoot = directories.workspace.string
        }

        let mainGroup = PBXGroup(
            sourceTree: forFixtures ? .group : .absolute,
            path: srcRoot
        )
        pbxProj.add(object: mainGroup)

        var buildSettings: [String: Any] = [
            "ALWAYS_SEARCH_USER_PATHS": false,
            "BAZEL_CONFIG": project.bazelConfig,
            "BAZEL_EXTERNAL": "$(BAZEL_OUTPUT_BASE)/external",
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
            "BAZEL_LLDB_INIT": "$(HOME)/.lldbinit-rules_xcodeproj",
            "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
            "_BAZEL_OUTPUT_BASE": "$(PROJECT_DIR)/../..",
            "BAZEL_OUTPUT_BASE": "$(_BAZEL_OUTPUT_BASE:standardizepath)",
            "BAZEL_PATH": project.bazel,
            "BAZEL_WORKSPACE_ROOT": "$(SRCROOT)",
            "BUILD_DIR": """
$(SYMROOT)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
""",
            "BUILD_WORKSPACE_DIRECTORY": "$(SRCROOT)",
            // `BUILT_PRODUCTS_DIR` isn't actually used by the build, since
            // `DEPLOYMENT_LOCATION` is set. It does prevent `DYLD_LIBRARY_PATH`
            // from being modified though.
            "BUILT_PRODUCTS_DIR": """
$(INDEXING_BUILT_PRODUCTS_DIR__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "CLANG_ENABLE_OBJC_ARC": true,
            "CLANG_MODULES_AUTOLINK": false,
            "CONFIGURATION_BUILD_DIR": "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)",
            "COPY_PHASE_STRIP": false,
            "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
            "DSTROOT": "$(PROJECT_TEMP_DIR)",
            "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
            "GENERATOR_LABEL": project.generatorLabel,
            "INDEX_FORCE_SCRIPT_EXECUTION": true,
            "INDEXING_BUILT_PRODUCTS_DIR__": """
$(INDEXING_BUILT_PRODUCTS_DIR__NO)
""",
            "INDEXING_BUILT_PRODUCTS_DIR__NO": "$(BUILD_DIR)",
            // Index Build doesn't respect `DEPLOYMENT_LOCATION`, but we also
            // don't need the `DYLD_LIBRARY_PATH` fix for it
            "INDEXING_BUILT_PRODUCTS_DIR__YES": "$(CONFIGURATION_BUILD_DIR)",
            "INDEXING_DEPLOYMENT_LOCATION__": """
$(INDEXING_DEPLOYMENT_LOCATION__NO)
""",
            "INDEXING_DEPLOYMENT_LOCATION__NO": true,
            "INDEXING_DEPLOYMENT_LOCATION__YES": false,
            "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
            "INTERNAL_DIR": """
$(PROJECT_FILE_PATH)/\(directories.internalDirectoryName)
""",
            "LD_OBJC_ABI_VERSION": "",
            "LD_DYLIB_INSTALL_NAME": "",
            // We don't want Xcode to set any search paths, since we set them in
            // `link.params`
            "LD_RUNPATH_SEARCH_PATHS": [],
            "ONLY_ACTIVE_ARCH": true,
            "RULES_XCODEPROJ_BUILD_MODE": buildMode.rawValue,
            "SCHEME_TARGET_IDS_FILE": """
$(OBJROOT)/scheme_target_ids
""",
            "SRCROOT": srcRoot,
            // Bazel currently doesn't support Catalyst
            "SUPPORTS_MACCATALYST": false,
            // Needed as the default otherwise `ENABLE_PREIVEWS` isn't set
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
            "USE_HEADERMAP": false,
            "VALIDATE_WORKSPACE": false,
        ]

        if buildMode.usesBazelModeBuildScripts {
            buildSettings.merge([
                "CC": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
                "CXX": "$(BAZEL_INTEGRATION_DIR)/clang.sh",
                "CODE_SIGNING_ALLOWED": false,
                "LD": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
                "LDPLUSPLUS": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
                "LIBTOOL": "$(BAZEL_INTEGRATION_DIR)/libtool.sh",
                "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc",
                "SWIFT_USE_INTEGRATED_DRIVER": false,
            ], uniquingKeysWith: { _, r in r })
        }

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: buildSettings
        )
        pbxProj.add(object: debugConfiguration)
        let buildConfigurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: buildConfigurationList)

        let attributes = [
            "BuildIndependentTargetsInParallel": 1,
            // TODO: Make these an option? Hardcoded to never warn for now.
            "LastSwiftUpdateCheck": 9999,
            "LastUpgradeCheck": 9999,
        ]

        let projectDirPath: String
        if projectDir.string.hasPrefix("/private/") {
            projectDirPath = String(projectDir.string.dropFirst(8))
        } else {
            projectDirPath = projectDir.string
        }

        let pbxProject = PBXProject(
            name: project.name,
            buildConfigurationList: buildConfigurationList,
            compatibilityVersion: """
Xcode \(min(project.minimumXcodeVersion.major, 14)).0
""",
            mainGroup: mainGroup,
            // TODO: Make developmentRegion configurable?
            developmentRegion: "en",
            projectDirPath: projectDirPath,
            attributes: attributes
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return pbxProj
    }
}

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
        directories: FilePathResolver.Directories
    ) -> PBXProj {
        let pbxProj = PBXProj()

        let projectDir: Path
        let srcRoot: String
        let mainGroup: PBXGroup
        if directories.bazelOut.isRelative {
            let relativeExecutionRoot = directories.bazelOut.parent()
            projectDir = directories.projectRoot + relativeExecutionRoot
            let srcRootPath = (0 ..< relativeExecutionRoot.components.count)
                .map { _ in ".." }
                .joined(separator: "/")
            mainGroup = PBXGroup(
                sourceTree: .group,
                path: srcRootPath
            )
            srcRoot = "$(PROJECT_DIR)/\(srcRootPath)"
        } else {
            projectDir = directories.bazelOut.parent()
            srcRoot = directories.workspace.string
            mainGroup = PBXGroup(
                sourceTree: .absolute,
                path: srcRoot
            )
        }

        pbxProj.add(object: mainGroup)

        var buildSettings = project.buildSettings.asDictionary
        buildSettings.merge([
            "BAZEL_CONFIG": project.bazelConfig,
            "BAZEL_EXTERNAL": "$(BAZEL_OUTPUT_BASE)/external",
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
            "BAZEL_LLDB_INIT": "$(OBJROOT)/bazel.lldbinit",
            "BAZEL_OUT": "$(PROJECT_DIR)/bazel-out",
            "_BAZEL_OUTPUT_BASE": "$(PROJECT_DIR)/../..",
            "BAZEL_OUTPUT_BASE": "$(_BAZEL_OUTPUT_BASE:standardizepath)",
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
            "CONFIGURATION_BUILD_DIR": "$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)",
            "DEPLOYMENT_LOCATION": """
$(INDEXING_DEPLOYMENT_LOCATION__$(INDEX_ENABLE_BUILD_ARENA)),
""",
            "DSTROOT": "$(PROJECT_TEMP_DIR)",
            "ENABLE_DEFAULT_SEARCH_PATHS": "NO",
            "GENERATOR_LABEL": project.generatorLabel,
            "GENERATOR_PACKAGE_BIN_DIR": """
\(project.configuration)/bin/\(project.generatorLabel.package)
""",
            "GENERATOR_TARGET_NAME": project.generatorLabel.name,
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
            "RULES_XCODEPROJ_BUILD_MODE": buildMode.rawValue,            "SCHEME_TARGET_IDS_FILE": """
$(OBJROOT)/scheme_target_ids
""",
            // Bazel currently doesn't support Catalyst
            "SUPPORTS_MACCATALYST": false,
            // Needed as the default otherwise `ENABLE_PREIVEWS` isn't set
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(COMPILE_TARGET_NAME)
""",
        ], uniquingKeysWith: { _, r in r })

        if directories.bazelOut.isRelative {
            buildSettings["_SRCROOT"] = srcRoot
            buildSettings["SRCROOT"] = "$(_SRCROOT:standardizepath)"
        } else {
            buildSettings["SRCROOT"] = srcRoot
        }

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

        let pbxProject = PBXProject(
            name: project.name,
            buildConfigurationList: buildConfigurationList,
            // TODO: Calculate `compatibilityVersion`
            compatibilityVersion: "Xcode 13.0",
            mainGroup: mainGroup,
            // TODO: Make developmentRegion configurable?
            developmentRegion: "en",
            projectDirPath: projectDir.string,
            attributes: attributes
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return pbxProj
    }
}

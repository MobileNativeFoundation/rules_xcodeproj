import PathKit
import XcodeProj

extension Generator {
    /// Creates the `PBXProj` and `PBXProject` objects for the given `Project`.
    ///
    /// The `PBXProject` is also created and assigned as the `PBXProj`'s
    /// `rootObject`.
    static func createProject(
        buildMode: BuildMode,
        project: Project,
        projectRootDirectory: Path,
        filePathResolver: FilePathResolver
    ) -> PBXProj {
        let pbxProj = PBXProj()

        let mainGroup = PBXGroup(sourceTree: .group)
        pbxProj.add(object: mainGroup)

        var buildSettings = project.buildSettings.asDictionary
        buildSettings.merge([
            "BAZEL_EXTERNAL": "$(LINKS_DIR)/external",
            "BAZEL_INTEGRATION_DIR": "$(INTERNAL_DIR)/bazel",
            "BAZEL_LLDB_INIT": "$(BUILD_DIR)/bazel.lldbinit",
            "BAZEL_OUT": "$(BUILD_DIR)/real-bazel-out",
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
            "GEN_DIR": "$(LINKS_DIR)/gen_dir",
            "LINKS_DIR": "$(INTERNAL_DIR)/links",
            "INDEXING_BUILT_PRODUCTS_DIR__": "$(BUILD_DIR)",
            "INDEXING_BUILT_PRODUCTS_DIR__NO": """
$(INDEXING_BUILT_PRODUCTS_DIR__)
""",
            // Index Build doesn't respect `DEPLOYMENT_LOCATION`, but we also
            // don't need the `DYLD_LIBRARY_PATH` fix for it
            "INDEXING_BUILT_PRODUCTS_DIR__YES": "$(CONFIGURATION_BUILD_DIR)",
            "INDEXING_DEPLOYMENT_LOCATION__": true,
            "INDEXING_DEPLOYMENT_LOCATION__NO": """
$(INDEXING_DEPLOYMENT_LOCATION__)
""",
            "INDEXING_DEPLOYMENT_LOCATION__YES": false,
            "INSTALL_PATH": "$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)/bin",
            "INTERNAL_DIR": """
$(PROJECT_FILE_PATH)/\(filePathResolver.internalDirectoryName)
""",
            // Bazel currently doesn't support Catalyst
            "SUPPORTS_MACCATALYST": false,
            // Needed as the default otherwise `ENABLE_PREIVEWS` isn't set
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)
""",
        ], uniquingKeysWith: { _, r in r })

        if buildMode.usesBazelModeBuildScripts {
            buildSettings.merge([
                "BAZEL_BUILD_OUTPUT_GROUPS_FILE": """
$(BUILD_DIR)/bazel_build_output_groups
""",
                "CC": "$(BAZEL_INTEGRATION_DIR)/cc.sh",
                "CODE_SIGNING_ALLOWED": false,
                "LD": "$(BAZEL_INTEGRATION_DIR)/ld.sh",
                "LIBTOOL": "$(BAZEL_INTEGRATION_DIR)/libtool.sh",
                "SWIFT_EXEC": "$(BAZEL_INTEGRATION_DIR)/swiftc.py",
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
            // TODO: Generate these. Hardcoded to Xcode 13.2.0 for now.
            "LastSwiftUpdateCheck": 1320,
            "LastUpgradeCheck": 1320,
        ]

        let pbxProject = PBXProject(
            name: project.name,
            buildConfigurationList: buildConfigurationList,
            // TODO: Calculate `compatibilityVersion`
            compatibilityVersion: "Xcode 13.0",
            mainGroup: mainGroup,
            // TODO: Make developmentRegion configurable?
            developmentRegion: "en",
            // TODO: Make this configurable?
            // Normal Xcode projects set this to `""` when at the workspace
            // level. Maybe we should as well?
            projectDirPath: projectRootDirectory.normalize().string,
            attributes: attributes
        )
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        return pbxProj
    }
}

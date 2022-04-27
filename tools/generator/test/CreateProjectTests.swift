import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_xcode() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "~/Developer/project"

        let filePathResolver = FilePathResolver(
            internalDirectoryName: "r_xcp",
            workspaceOutputPath: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_EXTERNAL": "$(LINKS_DIR)/external",
                "BAZEL_OUT": "$(BUILD_DIR)/real-bazel-out",
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
                "GEN_DIR": "$(LINKS_DIR)/gen_dir",
                "LINKS_DIR": "$(INTERNAL_DIR)/links",
                "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
                "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)
""",
            ]) { $1 }
        )
        expectedPBXProj.add(object: debugConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        expectedPBXProj.add(object: expectedBuildConfigurationList)

        let attributes: [String: Any] = [
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 1320,
            "LastUpgradeCheck": 1320,
        ]

        let expectedPBXProject = PBXProject(
            name: "Bazel",
            buildConfigurationList: expectedBuildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "en",
            projectDirPath: projectRootDirectory.normalize().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .xcode,
            project: project,
            projectRootDirectory: projectRootDirectory,
            filePathResolver: filePathResolver
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }

    func test_bazel() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "~/Developer/project"

        let filePathResolver = FilePathResolver(
            internalDirectoryName: "r_xcp",
            workspaceOutputPath: "X.xcodeproj"
        )

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "BAZEL_BUILD_OUTPUT_GROUPS_FILE": """
$(BUILD_DIR)/bazel_build_output_groups
""",
                "BAZEL_EXTERNAL": "$(LINKS_DIR)/external",
                "BAZEL_LLDB_INIT": "$(INTERNAL_DIR)/.lldbinit",
                "BAZEL_OUT": "$(BUILD_DIR)/real-bazel-out",
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
                "GEN_DIR": "$(LINKS_DIR)/gen_dir",
                "LINKS_DIR": "$(INTERNAL_DIR)/links",
                "INTERNAL_DIR": "$(PROJECT_FILE_PATH)/r_xcp",
                "TARGET_TEMP_DIR": """
$(PROJECT_TEMP_DIR)/$(BAZEL_PACKAGE_BIN_DIR)/$(TARGET_NAME)
""",
            ]) { $1 }
        )
        expectedPBXProj.add(object: debugConfiguration)
        let expectedBuildConfigurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        expectedPBXProj.add(object: expectedBuildConfigurationList)

        let attributes: [String: Any] = [
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 1320,
            "LastUpgradeCheck": 1320,
        ]

        let expectedPBXProject = PBXProject(
            name: "Bazel",
            buildConfigurationList: expectedBuildConfigurationList,
            compatibilityVersion: "Xcode 13.0",
            mainGroup: expectedMainGroup,
            developmentRegion: "en",
            projectDirPath: projectRootDirectory.normalize().string,
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            buildMode: .bazel,
            project: project,
            projectRootDirectory: projectRootDirectory,
            filePathResolver: filePathResolver
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}

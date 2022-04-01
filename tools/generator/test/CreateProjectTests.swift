import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let project = Fixtures.project
        let projectRootDirectory: Path = "~/Developer/project"

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: project.buildSettings.asDictionary.merging([
                "CONFIGURATION_BUILD_DIR": """
$(BUILD_DIR)/$(BAZEL_PACKAGE_BIN_DIR)
""",
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
            project: project,
            projectRootDirectory: projectRootDirectory
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}

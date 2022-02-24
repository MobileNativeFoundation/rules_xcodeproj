import CustomDump
import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let project = Fixtures.project

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup(sourceTree: .group)
        expectedPBXProj.add(object: expectedMainGroup)

        let expectedBuildConfigurationList = XCConfigurationList()
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
            knownRegions: ["en", "Base"],
            attributes: attributes
        )
        expectedPBXProj.add(object: expectedPBXProject)
        expectedPBXProj.rootObject = expectedPBXProject

        // Act

        let createdPBXProj = Generator.createProject(
            project: project
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(createdPBXProj, expectedPBXProj)
    }
}

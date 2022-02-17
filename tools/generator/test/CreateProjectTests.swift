import XCTest

@testable import generator
@testable import XcodeProj

final class CreateProjectTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let project = Fixtures.project

        let expectedPBXProj = PBXProj()

        let expectedMainGroup = PBXGroup()
        expectedPBXProj.add(object: expectedMainGroup)

        let expectedBuildConfigurationList = XCConfigurationList()
        expectedPBXProj.add(object: expectedBuildConfigurationList)

        let attributes = [
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

        let (createdPBXProj, createdPBXProject) = Generator.createProject(
            project: project
        )

        try createdPBXProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertEqual(createdPBXProject, createdPBXProj.rootObject)
        XCTAssertEqual(createdPBXProject.mainGroup, expectedMainGroup)

        // Break cycle before testing
        createdPBXProj.objects.delete(
            reference: createdPBXProj.rootObjectReference!
        )
        createdPBXProj.rootObject = nil
        expectedPBXProj.objects.delete(
            reference: expectedPBXProj.rootObjectReference!
        )
        expectedPBXProj.rootObject = nil
        XCTAssertEqual(createdPBXProj, expectedPBXProj)

        XCTAssertEqual(createdPBXProject, expectedPBXProject)
    }
}

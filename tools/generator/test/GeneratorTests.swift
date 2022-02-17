import XCTest

@testable import generator
@testable import XcodeProj

final class GeneratorTests: XCTestCase {
    /// Converts temporary references into stable ones, for equality asserts
    static func fixReferences(_ created: PBXProj, _ expected: PBXProj) throws {
        let referenceGenerator = ReferenceGenerator(outputSettings: .init())
        try referenceGenerator.generateReferences(proj: created)
        try referenceGenerator.generateReferences(proj: expected)
    }

    func test_createProject() throws {
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

        try Self.fixReferences(createdPBXProj, expectedPBXProj)

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

    func test_generate() throws {
        // Arrange

        let project = Project(
            name: "P"
        )
        let (pbxProj, pbxProject) = Fixtures.pbxProject()

        // MARK: createProject()

        struct CreateProjectCalled: Equatable {
            let project: Project
        }

        var createProjectCalled = [CreateProjectCalled]()
        func createProject(project: Project) -> (PBXProj, PBXProject) {
            createProjectCalled.append(CreateProjectCalled(
                project: project
            ))
            return (pbxProj, pbxProject)
        }

        let expectedCreateProjectCalled = [CreateProjectCalled(
            project: project
        )]

        // MARK: generate()

        let environment = Environment(
            createProject: createProject
        )
        let generator = Generator(environment: environment)

        // Act

        try generator.generate(project: project)

        // Assert

        // All the functions should be called with the correct parameters, the
        // correct number of times, and in the correct order.
        XCTAssertEqual(
            createProjectCalled,
            expectedCreateProjectCalled
        )
    }
}

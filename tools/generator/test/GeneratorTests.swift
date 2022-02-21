import CustomDump
import XCTest

@testable import generator
@testable import XcodeProj

final class GeneratorTests: XCTestCase {
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
        XCTAssertNoDifference(createProjectCalled, expectedCreateProjectCalled)
    }
}

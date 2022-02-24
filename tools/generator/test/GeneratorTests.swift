import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class GeneratorTests: XCTestCase {
    func test_generate() throws {
        // Arrange

        let project = Project(
            name: "P",
            buildSettings: [:],
            targets: Fixtures.targets,
            potentialTargetMerges: [:],
            requiredLinks: []
        )
        let pbxProj = Fixtures.pbxProj()
        let projectRootDirectory: Path = "~/project"
        let mergedTargets: [TargetID: Target] = [
            "Y": Target.mock(
                configuration: "a1b2c",
                product: .init(type: .staticLibrary, name: "Y", path: "")
            ),
            "Z":  Target.mock(
                configuration: "1a2b3",
                product: .init(type: .application, name: "Z", path: "")
            ),
        ]

        var expectedMessagesLogged: [StubLogger.MessageLogged] = []

        // MARK: createProject()

        struct CreateProjectCalled: Equatable {
            let project: Project
            let projectRootDirectory: Path
        }

        var createProjectCalled: [CreateProjectCalled] = []
        func createProject(
            project: Project,
            projectRootDirectory: Path
        ) -> PBXProj {
            createProjectCalled.append(.init(
                project: project,
                projectRootDirectory: projectRootDirectory
            ))
            return pbxProj
        }

        let expectedCreateProjectCalled = [CreateProjectCalled(
            project: project,
            projectRootDirectory: projectRootDirectory
        )]

        // MARK: processTargetMerges()

        struct ProcessTargetMergesCalled: Equatable {
            let targets: [TargetID: Target]
            let potentialTargetMerges: [TargetID: Set<TargetID>]
            let requiredLinks: Set<Path>
        }

        var processTargetMergesCalled: [ProcessTargetMergesCalled] = []
        func processTargetMerges(
            targets: inout [TargetID: Target],
            potentialTargetMerges: [TargetID: Set<TargetID>],
            requiredLinks: Set<Path>
        ) throws -> [InvalidMerge] {
            processTargetMergesCalled.append(.init(
                targets: targets,
                potentialTargetMerges: potentialTargetMerges,
                requiredLinks: requiredLinks
            ))
            targets = mergedTargets
            return [InvalidMerge(source: "Y", destinations: ["Z"])]
        }

        let expectedProcessTargetMergesCalled = [ProcessTargetMergesCalled(
            targets: project.targets,
            potentialTargetMerges: project.potentialTargetMerges,
            requiredLinks: project.requiredLinks
        )]
        expectedMessagesLogged.append(StubLogger.MessageLogged(.warning, """
 Was unable to merge "//Y (a1b2c)" into "//Z (1a2b3)"
 """))

        // MARK: generate()

        let logger = StubLogger()
        let environment = Environment(
            createProject: createProject,
            processTargetMerges: processTargetMerges
        )
        let generator = Generator(
            environment: environment,
            logger: logger
        )

        // Act

        try generator.generate(
            project: project,
            projectRootDirectory: projectRootDirectory
        )

        // Assert

        // All the functions should be called with the correct parameters, the
        // correct number of times, and in the correct order.
        XCTAssertNoDifference(
            createProjectCalled,
            expectedCreateProjectCalled
        )
        XCTAssertNoDifference(
            processTargetMergesCalled,
            expectedProcessTargetMergesCalled
        )

        // The correct messages should have been logged
        XCTAssertNoDifference(logger.messagesLogged, expectedMessagesLogged)
    }
}

class StubLogger: Logger {
    enum MessageType {
        case debug
        case info
        case warning
        case error
    }
    struct MessageLogged: Equatable {
        let type: MessageType
        let message: String

        init(_ type: MessageType, _ message: String) {
            self.type = type
            self.message = message
        }
    }
    var messagesLogged: [MessageLogged] = []

    func logDebug(_ message: @autoclosure () -> String) {
        messagesLogged.append(.init(.debug, message()))
    }

    func logInfo(_ message: @autoclosure () -> String) {
        messagesLogged.append(.init(.info, message()))
    }

    func logWarning(_ message: @autoclosure () -> String) {
        messagesLogged.append(.init(.warning, message()))
    }

    func logError(_ message: @autoclosure () -> String) {
        messagesLogged.append(.init(.error, message()))
    }
}

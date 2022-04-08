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
            label: "//a/P:xcodeproj",
            buildSettings: [:],
            targets: Fixtures.targets,
            targetMerges: [:],
            invalidTargetMerges: ["Y": ["Z"]],
            extraFiles: []
        )

        let pbxProj = Fixtures.pbxProj()
        let pbxProject = pbxProj.rootObject!
        let mainGroup = PBXGroup(name: "Main")
        pbxProject.mainGroup = mainGroup
        
        let projectRootDirectory: Path = "~/project"
        let externalDirectory: Path = "/var/tmp/_bazel_BB/HASH/external"
        let generatedDirectory: Path = "/var/tmp/_bazel/H/execroot/W/bazel-out"
        let internalDirectoryName = "rules_xcodeproj"
        let workspaceOutputPath: Path = "P.xcodeproj"
        let outputPath: Path = "P.xcodeproj"

        let filePathResolver = FilePathResolver(
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let mergedTargets: [TargetID: Target] = [
            "Y": Target.mock(
                label: "//:Y",
                configuration: "a1b2c",
                product: .init(type: .staticLibrary, name: "Y", path: "")
            ),
            "Z":  Target.mock(
                label: "//:Z",
                configuration: "1a2b3",
                product: .init(type: .application, name: "Z", path: "")
            ),
        ]
        let disambiguatedTargets: [TargetID: DisambiguatedTarget] = [
            "A": .init(
                name: "A (3456a)",
                target: mergedTargets["Y"]!
            ),
        ]
        let (files, filesAndGroups) = Fixtures.files(
            in: pbxProj,
            externalDirectory: externalDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )
        let rootElements = [filesAndGroups["a"]!, filesAndGroups["x"]!]
        let products = Fixtures.products(in: pbxProj)
        
        let productsGroup = PBXGroup(name: "42")
        let pbxTargets: [TargetID: PBXNativeTarget] = [
            "A": PBXNativeTarget(name: "A (3456a)"),
        ]
        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: pbxProj,
            sharedData: nil
        )

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
            let targetMerges: [TargetID: Set<TargetID>]
        }

        var processTargetMergesCalled: [ProcessTargetMergesCalled] = []
        func processTargetMerges(
            targets: inout [TargetID: Target],
            targetMerges: [TargetID: Set<TargetID>]
        ) throws -> Void {
            processTargetMergesCalled.append(.init(
                targets: targets,
                targetMerges: targetMerges
            ))
            targets = mergedTargets
        }

        let expectedProcessTargetMergesCalled = [ProcessTargetMergesCalled(
            targets: project.targets,
            targetMerges: project.targetMerges
        )]
        expectedMessagesLogged.append(StubLogger.MessageLogged(.warning, """
 Was unable to merge "//:Y (a1b2c)" into "//:Z (1a2b3)"
 """))

        // MARK: createFilesAndGroups()

        struct CreateFilesAndGroupsCalled: Equatable {
            let pbxProj: PBXProj
            let targets: [TargetID: Target]
            let extraFiles: Set<FilePath>
            let filePathResolver: FilePathResolver
        }

        var createFilesAndGroupsCalled: [CreateFilesAndGroupsCalled] = []
        func createFilesAndGroups(
            in pbxProj: PBXProj,
            targets: [TargetID: Target],
            extraFiles: Set<FilePath>,
            filePathResolver: FilePathResolver
        ) -> (
            files: [FilePath: File],
            rootElements: [PBXFileElement]
        ) {
            createFilesAndGroupsCalled.append(.init(
                pbxProj: pbxProj,
                targets: targets,
                extraFiles: extraFiles,
                filePathResolver: filePathResolver
            ))
            return (files, rootElements)
        }

        let expectedCreateFilesAndGroupsCalled = [CreateFilesAndGroupsCalled(
            pbxProj: pbxProj,
            targets: mergedTargets,
            extraFiles: project.extraFiles,
            filePathResolver: filePathResolver
        )]

        // MARK: createProducts()

        struct CreateProductsCalled: Equatable {
            let pbxProj: PBXProj
            let targets: [TargetID: Target]
        }

        var createProductsCalled: [CreateProductsCalled] = []
        func createProducts(
            pbxProj: PBXProj,
            targets: [TargetID: Target]
        ) -> (Products, PBXGroup) {
            createProductsCalled.append(.init(
                pbxProj: pbxProj,
                targets: targets
            ))
            return (products, productsGroup)
        }

        let expectedCreateProductsCalled = [CreateProductsCalled(
            pbxProj: pbxProj,
            targets: mergedTargets
        )]

        // MARK: populateMainGroup()

        struct PopulateMainGroupCalled: Equatable {
            let mainGroup: PBXGroup
            let pbxProj: PBXProj
            let rootElements: [PBXFileElement]
            let productsGroup: PBXGroup
        }

        var populateMainGroupCalled: [PopulateMainGroupCalled] = []
        func populateMainGroup(
            _ mainGroup: PBXGroup,
            in pbxProj: PBXProj,
            rootElements: [PBXFileElement],
            productsGroup: PBXGroup
        ) {
            populateMainGroupCalled.append(.init(
                mainGroup: mainGroup,
                pbxProj: pbxProj,
                rootElements: rootElements,
                productsGroup: productsGroup
            ))
        }

        let expectedPopulateMainGroupCalled = [PopulateMainGroupCalled(
            mainGroup: mainGroup,
            pbxProj: pbxProj,
            rootElements: rootElements,
            productsGroup: productsGroup
        )]

        // MARK: disambiguateTargets()

        struct DisambiguateTargetsCalled: Equatable {
            let targets: [TargetID: Target]
        }

        var disambiguateTargetsCalled: [DisambiguateTargetsCalled] = []
        func disambiguateTargets(
            targets: [TargetID: Target]
        ) -> [TargetID: DisambiguatedTarget] {
            disambiguateTargetsCalled.append(.init(
                targets: targets
            ))
            return disambiguatedTargets
        }

        let expectedDisambiguateTargetsCalled = [DisambiguateTargetsCalled(
            targets: mergedTargets
        )]

        // MARK: addTargets()

        struct AddTargetsCalled: Equatable {
            let pbxProj: PBXProj
            let disambiguatedTargets: [TargetID: DisambiguatedTarget]
            let products: Products
            let files: [FilePath: File]
            let filePathResolver: FilePathResolver
            let xcodeprojBazelLabel: String
        }

        var addTargetsCalled: [AddTargetsCalled] = []
        func addTargets(
            in pbxProj: PBXProj,
            for disambiguatedTargets: [TargetID: DisambiguatedTarget],
            products: Products,
            files: [FilePath: File],
            filePathResolver: FilePathResolver,
            xcodeprojBazelLabel: String
        ) throws -> [TargetID: PBXNativeTarget] {
            addTargetsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                products: products,
                files: files,
                filePathResolver: filePathResolver,
                xcodeprojBazelLabel: xcodeprojBazelLabel
            ))
            return pbxTargets
        }

        let expectedAddTargetsCalled = [AddTargetsCalled(
            pbxProj: pbxProj,
            disambiguatedTargets: disambiguatedTargets,
            products: products,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: project.label
        )]
        
        // MARK: setTargetConfigurations()

        struct SetTargetConfigurationsCalled: Equatable {
            let pbxProj: PBXProj
            let disambiguatedTargets: [TargetID: DisambiguatedTarget]
            let pbxTargets: [TargetID: PBXNativeTarget]
            let filePathResolver: FilePathResolver
        }

        var setTargetConfigurationsCalled: [SetTargetConfigurationsCalled] = []
        func setTargetConfigurations(
            in pbxProj: PBXProj,
            for disambiguatedTargets: [TargetID: DisambiguatedTarget],
            pbxTargets: [TargetID: PBXNativeTarget],
            filePathResolver: FilePathResolver
        ) {
            setTargetConfigurationsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                pbxTargets: pbxTargets,
                filePathResolver: filePathResolver
            ))
        }

        let expectedSetTargetConfigurationsCalled = [
            SetTargetConfigurationsCalled(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                pbxTargets: pbxTargets,
                filePathResolver: filePathResolver
            )
        ]

        // MARK: setTargetDependencies()

        struct SetTargetDependenciesCalled: Equatable {
            let disambiguatedTargets: [TargetID: DisambiguatedTarget]
            let pbxTargets: [TargetID: PBXNativeTarget]
        }

        var setTargetDependenciesCalled: [SetTargetDependenciesCalled] = []
        func setTargetDependencies(
            disambiguatedTargets: [TargetID: DisambiguatedTarget],
            pbxTargets: [TargetID: PBXNativeTarget]
        ) {
            setTargetDependenciesCalled.append(SetTargetDependenciesCalled(
                disambiguatedTargets: disambiguatedTargets,
                pbxTargets: pbxTargets
            ))
        }

        let expectedSetTargetDependenciesCalled = [SetTargetDependenciesCalled(
            disambiguatedTargets: disambiguatedTargets,
            pbxTargets: pbxTargets
        )]

        // MARK: createXcodeProj()

        struct CreateXcodeProjCalled: Equatable {
            let pbxProj: PBXProj
        }

        var createXcodeProjCalled: [CreateXcodeProjCalled] = []
        func createXcodeProj(
            for pbxProj: PBXProj
        ) -> XcodeProj {
            createXcodeProjCalled.append(.init(
                pbxProj: pbxProj
            ))
            return xcodeProj
        }

        let expectedCreateXcodeProjCalled = [CreateXcodeProjCalled(
            pbxProj: pbxProj
        )]

        // MARK: writeXcodeProj()

        struct WriteXcodeProjCalled: Equatable {
            let xcodeProj: XcodeProj
            let files: [FilePath: File]
            let internalDirectoryName: String
            let outputPath: Path
        }

        var writeXcodeProjCalled: [WriteXcodeProjCalled] = []
        func writeXcodeProj(
            xcodeProj: XcodeProj,
            files: [FilePath: File],
            internalDirectoryName: String,
            to outputPath: Path
        ) {
            writeXcodeProjCalled.append(.init(
                xcodeProj: xcodeProj,
                files: files,
                internalDirectoryName: internalDirectoryName,
                outputPath: outputPath
            ))
        }

        let expectedWriteXcodeProjCalled = [WriteXcodeProjCalled(
            xcodeProj: xcodeProj,
            files: files,
            internalDirectoryName: internalDirectoryName,
            outputPath: outputPath
        )]

        // MARK: generate()

        let logger = StubLogger()
        let environment = Environment(
            createProject: createProject,
            processTargetMerges: processTargetMerges,
            createFilesAndGroups: createFilesAndGroups,
            createProducts: createProducts,
            populateMainGroup: populateMainGroup,
            disambiguateTargets: disambiguateTargets,
            addTargets: addTargets,
            setTargetConfigurations: setTargetConfigurations,
            setTargetDependencies: setTargetDependencies,
            createXcodeProj: createXcodeProj,
            writeXcodeProj: writeXcodeProj
        )
        let generator = Generator(
            environment: environment,
            logger: logger
        )

        // Act

        try generator.generate(
            project: project,
            projectRootDirectory: projectRootDirectory,
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath,
            outputPath: outputPath
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
        XCTAssertNoDifference(
            createFilesAndGroupsCalled,
            expectedCreateFilesAndGroupsCalled
        )
        XCTAssertNoDifference(
            createProductsCalled,
            expectedCreateProductsCalled
        )
        XCTAssertNoDifference(
            populateMainGroupCalled,
            expectedPopulateMainGroupCalled
        )
        XCTAssertNoDifference(
            disambiguateTargetsCalled,
            expectedDisambiguateTargetsCalled
        )
        XCTAssertNoDifference(addTargetsCalled, expectedAddTargetsCalled)
        XCTAssertNoDifference(
            setTargetConfigurationsCalled,
            expectedSetTargetConfigurationsCalled
        )
        XCTAssertNoDifference(
            setTargetDependenciesCalled,
            expectedSetTargetDependenciesCalled
        )
        XCTAssertNoDifference(
            createXcodeProjCalled,
            expectedCreateXcodeProjCalled
        )
        XCTAssertNoDifference(
            writeXcodeProjCalled,
            expectedWriteXcodeProjCalled
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

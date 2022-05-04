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
        let xccurrentversions: [XCCurrentVersion] = [
            .init(container: "Ex/M.xcdatamodeld", version: "M2.xcdatamodel"),
            .init(container: "Xe/P.xcdatamodeld", version: "M1.xcdatamodel"),
        ]

        let pbxProj = Fixtures.pbxProj()
        let pbxProject = pbxProj.rootObject!
        let mainGroup = PBXGroup(name: "Main")
        pbxProject.mainGroup = mainGroup

        let buildMode: BuildMode = .bazel
        let projectRootDirectory: Path = "~/project"
        let internalDirectoryName = "rules_xcodeproj"
        let workspaceOutputPath: Path = "P.xcodeproj"
        let outputPath: Path = "P.xcodeproj"

        let filePathResolver = FilePathResolver(
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
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )
        let rootElements = [filesAndGroups["a"]!, filesAndGroups["x"]!]
        let products = Fixtures.products(in: pbxProj)
        
        let productsGroup = PBXGroup(name: "42")
        let bazelDependenciesTarget = PBXAggregateTarget(name: "BD")
        let pbxTargets: [TargetID: PBXNativeTarget] = [
            "A": PBXNativeTarget(name: "A (3456a)"),
        ]
        let schemes = [XCScheme(name: "Custom Scheme", lastUpgradeVersion: nil, version: nil)]
        let sharedData = XCSharedData(schemes: schemes)
        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: pbxProj,
            sharedData: sharedData
        )

        var expectedMessagesLogged: [StubLogger.MessageLogged] = []

        // MARK: createProject()

        struct CreateProjectCalled: Equatable {
            let buildMode: BuildMode
            let project: Project
            let projectRootDirectory: Path
            let filePathResolver: FilePathResolver
        }

        var createProjectCalled: [CreateProjectCalled] = []
        func createProject(
            buildMode: BuildMode,
            project: Project,
            projectRootDirectory: Path,
            filePathResolver: FilePathResolver
        ) -> PBXProj {
            createProjectCalled.append(.init(
                buildMode: buildMode,
                project: project,
                projectRootDirectory: projectRootDirectory,
                filePathResolver: filePathResolver
            ))
            return pbxProj
        }

        let expectedCreateProjectCalled = [CreateProjectCalled(
            buildMode: buildMode,
            project: project,
            projectRootDirectory: projectRootDirectory,
            filePathResolver: filePathResolver
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
            let xccurrentversions: [XCCurrentVersion]
            let filePathResolver: FilePathResolver
        }

        var createFilesAndGroupsCalled: [CreateFilesAndGroupsCalled] = []
        func createFilesAndGroups(
            in pbxProj: PBXProj,
            targets: [TargetID: Target],
            extraFiles: Set<FilePath>,
            xccurrentversions: [XCCurrentVersion],
            filePathResolver: FilePathResolver,
            logger: Logger
        ) -> (
            files: [FilePath: File],
            rootElements: [PBXFileElement]
        ) {
            createFilesAndGroupsCalled.append(.init(
                pbxProj: pbxProj,
                targets: targets,
                extraFiles: extraFiles,
                xccurrentversions: xccurrentversions,
                filePathResolver: filePathResolver
            ))
            return (files, rootElements)
        }

        let expectedCreateFilesAndGroupsCalled = [CreateFilesAndGroupsCalled(
            pbxProj: pbxProj,
            targets: mergedTargets,
            extraFiles: project.extraFiles,
            xccurrentversions: xccurrentversions,
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

        // MARK: addBazelDependenciesTarget()

        struct AddBazelDependenciesTargetCalled: Equatable {
            let pbxProj: PBXProj
            let buildMode: BuildMode
            let files: [FilePath: File]
            let filePathResolver: FilePathResolver
            let xcodeprojBazelLabel: String
        }

        var addBazelDependenciesTargetCalled: [AddBazelDependenciesTargetCalled]
            = []
        func addBazelDependenciesTarget(
            in pbxProj: PBXProj,
            buildMode: BuildMode,
            files: [FilePath: File],
            filePathResolver: FilePathResolver,
            xcodeprojBazelLabel: String
        ) throws -> PBXAggregateTarget? {
            addBazelDependenciesTargetCalled.append(.init(
                pbxProj: pbxProj,
                buildMode: buildMode,
                files: files,
                filePathResolver: filePathResolver,
                xcodeprojBazelLabel: xcodeprojBazelLabel
            ))
            return bazelDependenciesTarget
        }

        let expectedAddBazelDependenciesTargetCalled = [
            AddBazelDependenciesTargetCalled(
                pbxProj: pbxProj,
                buildMode: buildMode,
                files: files,
                filePathResolver: filePathResolver,
                xcodeprojBazelLabel: project.label
            ),
        ]

        // MARK: addTargets()

        struct AddTargetsCalled: Equatable {
            let pbxProj: PBXProj
            let disambiguatedTargets: [TargetID: DisambiguatedTarget]
            let buildMode: BuildMode
            let products: Products
            let files: [FilePath: File]
            let filePathResolver: FilePathResolver
            let bazelDependenciesTarget: PBXAggregateTarget?
        }

        var addTargetsCalled: [AddTargetsCalled] = []
        func addTargets(
            in pbxProj: PBXProj,
            for disambiguatedTargets: [TargetID: DisambiguatedTarget],
            buildMode: BuildMode,
            products: Products,
            files: [FilePath: File],
            filePathResolver: FilePathResolver,
            bazelDependenciesTarget: PBXAggregateTarget?
        ) throws -> [TargetID: PBXNativeTarget] {
            addTargetsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                buildMode: buildMode,
                products: products,
                files: files,
                filePathResolver: filePathResolver,
                bazelDependenciesTarget: bazelDependenciesTarget
            ))
            return pbxTargets
        }

        let expectedAddTargetsCalled = [AddTargetsCalled(
            pbxProj: pbxProj,
            disambiguatedTargets: disambiguatedTargets,
            buildMode: buildMode,
            products: products,
            files: files,
            filePathResolver: filePathResolver,
            bazelDependenciesTarget: bazelDependenciesTarget
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

        // MARK: createXCSchemes()

        struct CreateXCSchemesCalled: Equatable {
            let disambiguatedTargets: [TargetID: DisambiguatedTarget]
        }

        var createXCSchemesCalled: [CreateXCSchemesCalled] = []
        func createXCSchemes(
            disambiguatedTargets: [TargetID: DisambiguatedTarget]
        ) -> [XCScheme] {
            createXCSchemesCalled.append(.init(disambiguatedTargets: disambiguatedTargets))
            return schemes
        }

        let expectedCreateXCSchemesCalled = [CreateXCSchemesCalled(
            disambiguatedTargets: disambiguatedTargets
        )]

        // MARK: createXCSharedData()

        struct CreateXCSharedDataCalled: Equatable {
            let schemes: [XCScheme]
        }

        var createXCSharedDataCalled: [CreateXCSharedDataCalled] = []
        func createXCSharedData(schemes: [XCScheme]) -> XCSharedData {
            createXCSharedDataCalled.append(.init(schemes: schemes))
            return sharedData
        }

        let expectedCreateXCSharedDataCalled = [CreateXCSharedDataCalled(
            schemes: schemes
        )]

        // MARK: createXcodeProj()

        struct CreateXcodeProjCalled: Equatable {
            let pbxProj: PBXProj
            let sharedData: XCSharedData?
        }

        var createXcodeProjCalled: [CreateXcodeProjCalled] = []
        func createXcodeProj(
            for pbxProj: PBXProj,
            sharedData: XCSharedData?
        ) -> XcodeProj {
            createXcodeProjCalled.append(.init(
                pbxProj: pbxProj,
                sharedData: sharedData
            ))
            return xcodeProj
        }

        let expectedCreateXcodeProjCalled = [CreateXcodeProjCalled(
            pbxProj: pbxProj,
            sharedData: sharedData
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
            addBazelDependenciesTarget: addBazelDependenciesTarget,
            addTargets: addTargets,
            setTargetConfigurations: setTargetConfigurations,
            setTargetDependencies: setTargetDependencies,
            createXCSchemes: createXCSchemes,
            createXCSharedData: createXCSharedData,
            createXcodeProj: createXcodeProj,
            writeXcodeProj: writeXcodeProj
        )
        let generator = Generator(
            environment: environment,
            logger: logger
        )

        // Act

        try generator.generate(
            buildMode: buildMode,
            project: project,
            xccurrentversions: xccurrentversions,
            projectRootDirectory: projectRootDirectory,
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
        XCTAssertNoDifference(
            addBazelDependenciesTargetCalled,
            expectedAddBazelDependenciesTargetCalled
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
            createXCSchemesCalled,
            expectedCreateXCSchemesCalled
        )
        XCTAssertNoDifference(
            createXCSharedDataCalled,
            expectedCreateXCSharedDataCalled
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

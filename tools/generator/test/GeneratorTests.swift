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
            bazelWorkspaceName: "bazel_workspace",
            label: "//a/P:xcodeproj",
            configuration: "abc123",
            buildSettings: [:],
            targets: Fixtures.targets,
            targetMerges: [:],
            targetHosts: [
                "WKE": ["I 1", "I 2"],
            ],
            extraFiles: [],
            schemeAutogenerationMode: .auto,
            customXcodeSchemes: [],
            forceBazelDependencies: false
        )
        let xccurrentversions: [XCCurrentVersion] = [
            .init(container: "Ex/M.xcdatamodeld", version: "M2.xcdatamodel"),
            .init(container: "Xe/P.xcdatamodeld", version: "M1.xcdatamodel"),
        ]
        let extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier] = [
            "WKE": .unknown,
        ]

        let pbxProj = Fixtures.pbxProj()
        let pbxProject = pbxProj.rootObject!
        let mainGroup = PBXGroup(name: "Main")
        pbxProject.mainGroup = mainGroup

        let buildMode: BuildMode = .bazel
        let schemeAutogenerationMode: SchemeAutogenerationMode = .auto
        let projectRootDirectory: Path = "~/project"
        let internalDirectoryName = "rules_xcodeproj"
        let workspaceOutputPath: Path = "P.xcodeproj"
        let bazelIntegrationDirectory: Path = "stubs"
        let outputPath: Path = "P.xcodeproj"

        let filePathResolver = FilePathResolver(
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )

        let mergedTargets: [TargetID: Target] = [
            "I 1": Target.mock(
                label: "//:I1",
                configuration: "1a2b3",
                product: .init(type: .application, name: "I 1", path: "")
            ),
            "I 2": Target.mock(
                label: "//:I2",
                configuration: "1a2b3",
                product: .init(type: .application, name: "I 2", path: "")
            ),
            "WKE": Target.mock(
                label: "//:WKE",
                platform: .device(os: .watchOS),
                product: .init(
                    type: .watch2Extension,
                    name: "WKE",
                    path: .generated("z/WK.appex")
                )
            ),
            "Y": Target.mock(
                label: "//:Y",
                configuration: "a1b2c",
                product: .init(type: .staticLibrary, name: "Y", path: "")
            ),
            "Z": Target.mock(
                label: "//:Z",
                configuration: "1a2b3",
                product: .init(type: .application, name: "Z", path: "")
            ),
        ]
        let consolidatedTargets = ConsolidatedTargets(
            keys: [
                "I 1": "I 1",
                "I 2": "I 2",
                "WKE": "WKE",
                "Y": "Y",
                "Z": "Z",
            ],
            targets: [
                "I 1": .init(
                    targets: ["I 1": mergedTargets["I 1"]!]
                ),
                "I 2": .init(
                    targets: ["I 2": mergedTargets["I 2"]!]
                ),
                "WKE": .init(
                    targets: ["WKE": mergedTargets["WKE"]!]
                ),
                "Y": .init(
                    targets: ["Y": mergedTargets["Y"]!]
                ),
                "Z": .init(
                    targets: ["Z": mergedTargets["Z"]!]
                ),
            ]
        )
        let disambiguatedTargets = DisambiguatedTargets(
            keys: [
                "A": "A",
                "I 1": "I 1",
                "I 2": "I 2",
                "WKE": "WKE",
            ],
            targets: [
                "A": .init(
                    name: "A (3456a)",
                    target: consolidatedTargets.targets["Y"]!
                ),
                "I 1": .init(
                    name: "I1 (3456a)",
                    target: consolidatedTargets.targets["I 1"]!
                ),
                "I 2": .init(
                    name: "I2 (3456a)",
                    target: consolidatedTargets.targets["I 2"]!
                ),
                "WKE": .init(
                    name: "WKE (3456a)",
                    target: consolidatedTargets.targets["WKE"]!
                ),
            ]
        )
        let (files, filesAndGroups, xcodeGeneratedFiles) = Fixtures.files(
            in: pbxProj,
            internalDirectoryName: internalDirectoryName,
            workspaceOutputPath: workspaceOutputPath
        )
        let rootElements = [filesAndGroups["a"]!, filesAndGroups["x"]!]
        let products = Fixtures.products(in: pbxProj)

        let productsGroup = PBXGroup(name: "42")
        let bazelDependenciesTarget = PBXAggregateTarget(name: "BD")
        let pbxTargets: [ConsolidatedTarget.Key: PBXTarget] = [
            "A": PBXNativeTarget(name: "A (3456a)"),
            "I 1": PBXNativeTarget(name: "I1 (3456a)"),
            "I 2": PBXNativeTarget(name: "I2 (3456a)"),
            "WKE": PBXNativeTarget(name: "WKE (3456a)"),
        ]
        // TODO(chuck): FIX ME!
        let customXcodeSchemes = [XcodeScheme]()
        let customXCSchemes = [XCScheme]()
        // let customXcodeSchemes = [
        //     XcodeScheme(name: "Custom Scheme"),
        // ]
        // let customXCSchemes = [
        //     XCScheme(name: "Custom Scheme", lastUpgradeVersion: nil, version: nil),
        // ]
        let autogeneratedXCSchemes = [
            XCScheme(name: "Autogenerated Scheme", lastUpgradeVersion: nil, version: nil),
        ]
        let allXCSchemes = customXCSchemes + autogeneratedXCSchemes
        let sharedData = XCSharedData(schemes: allXCSchemes)
        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: pbxProj,
            sharedData: sharedData
        )

        let expectedMessagesLogged: [StubLogger.MessageLogged] = []

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
        ) throws {
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

        // MARK: consolidateTargets()

        struct ConsolidateTargetsCalled: Equatable {
            let targets: [TargetID: Target]
        }

        var consolidateTargetsCalled: [ConsolidateTargetsCalled] = []
        func consolidateTargets(
            _ targets: [TargetID: Target],
            logger _: Logger
        ) -> ConsolidatedTargets {
            consolidateTargetsCalled.append(.init(
                targets: targets
            ))
            return consolidatedTargets
        }

        let expectedConsolidateTargetsCalled = [ConsolidateTargetsCalled(
            targets: mergedTargets
        )]

        // MARK: createFilesAndGroups()

        struct CreateFilesAndGroupsCalled: Equatable {
            let pbxProj: PBXProj
            let buildMode: BuildMode
            let targets: [TargetID: Target]
            let extraFiles: Set<FilePath>
            let xccurrentversions: [XCCurrentVersion]
            let filePathResolver: FilePathResolver
        }

        var createFilesAndGroupsCalled: [CreateFilesAndGroupsCalled] = []
        func createFilesAndGroups(
            in pbxProj: PBXProj,
            buildMode: BuildMode,
            targets: [TargetID: Target],
            extraFiles: Set<FilePath>,
            xccurrentversions: [XCCurrentVersion],
            filePathResolver: FilePathResolver,
            logger _: Logger
        ) -> (
            files: [FilePath: File],
            rootElements: [PBXFileElement],
            xcodeGeneratedFiles: Set<FilePath>
        ) {
            createFilesAndGroupsCalled.append(.init(
                pbxProj: pbxProj,
                buildMode: buildMode,
                targets: targets,
                extraFiles: extraFiles,
                xccurrentversions: xccurrentversions,
                filePathResolver: filePathResolver
            ))
            return (files, rootElements, xcodeGeneratedFiles)
        }

        let expectedCreateFilesAndGroupsCalled = [CreateFilesAndGroupsCalled(
            pbxProj: pbxProj,
            buildMode: buildMode,
            targets: mergedTargets,
            extraFiles: project.extraFiles,
            xccurrentversions: xccurrentversions,
            filePathResolver: filePathResolver
        )]

        // MARK: createProducts()

        struct CreateProductsCalled: Equatable {
            let pbxProj: PBXProj
            let consolidatedTargets: ConsolidatedTargets
        }

        var createProductsCalled: [CreateProductsCalled] = []
        func createProducts(
            pbxProj: PBXProj,
            consolidatedTargets: ConsolidatedTargets
        ) -> (Products, PBXGroup) {
            createProductsCalled.append(.init(
                pbxProj: pbxProj,
                consolidatedTargets: consolidatedTargets
            ))
            return (products, productsGroup)
        }

        let expectedCreateProductsCalled = [CreateProductsCalled(
            pbxProj: pbxProj,
            consolidatedTargets: consolidatedTargets
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
            let consolidatedTargets: ConsolidatedTargets
        }

        var disambiguateTargetsCalled: [DisambiguateTargetsCalled] = []
        func disambiguateTargets(
            consolidatedTargets: ConsolidatedTargets
        ) -> DisambiguatedTargets {
            disambiguateTargetsCalled.append(.init(
                consolidatedTargets: consolidatedTargets
            ))
            return disambiguatedTargets
        }

        let expectedDisambiguateTargetsCalled = [DisambiguateTargetsCalled(
            consolidatedTargets: consolidatedTargets
        )]

        // MARK: addBazelDependenciesTarget()

        struct AddBazelDependenciesTargetCalled: Equatable {
            let pbxProj: PBXProj
            let buildMode: BuildMode
            let forceBazelDependencies: Bool
            let files: [FilePath: File]
            let filePathResolver: FilePathResolver
            let xcodeprojBazelLabel: BazelLabel
            let xcodeprojConfiguration: String
            let consolidatedTargets: ConsolidatedTargets
        }

        var addBazelDependenciesTargetCalled: [AddBazelDependenciesTargetCalled]
            = []
        func addBazelDependenciesTarget(
            in pbxProj: PBXProj,
            buildMode: BuildMode,
            forceBazelDependencies: Bool,
            files: [FilePath: File],
            filePathResolver: FilePathResolver,
            xcodeprojBazelLabel: BazelLabel,
            xcodeprojConfiguration: String,
            consolidatedTargets: ConsolidatedTargets
        ) throws -> PBXAggregateTarget? {
            addBazelDependenciesTargetCalled.append(.init(
                pbxProj: pbxProj,
                buildMode: buildMode,
                forceBazelDependencies: forceBazelDependencies,
                files: files,
                filePathResolver: filePathResolver,
                xcodeprojBazelLabel: xcodeprojBazelLabel,
                xcodeprojConfiguration: xcodeprojConfiguration,
                consolidatedTargets: consolidatedTargets
            ))
            return bazelDependenciesTarget
        }

        let expectedAddBazelDependenciesTargetCalled = [
            AddBazelDependenciesTargetCalled(
                pbxProj: pbxProj,
                buildMode: buildMode,
                forceBazelDependencies: project.forceBazelDependencies,
                files: files,
                filePathResolver: filePathResolver,
                xcodeprojBazelLabel: project.label,
                xcodeprojConfiguration: project.configuration,
                consolidatedTargets: consolidatedTargets
            ),
        ]

        // MARK: addTargets()

        struct AddTargetsCalled: Equatable {
            let pbxProj: PBXProj
            let disambiguatedTargets: DisambiguatedTargets
            let buildMode: BuildMode
            let products: Products
            let files: [FilePath: File]
            let filePathResolver: FilePathResolver
            let bazelDependenciesTarget: PBXAggregateTarget?
        }

        var addTargetsCalled: [AddTargetsCalled] = []
        func addTargets(
            in pbxProj: PBXProj,
            for disambiguatedTargets: DisambiguatedTargets,
            buildMode: BuildMode,
            products: Products,
            files: [FilePath: File],
            filePathResolver: FilePathResolver,
            bazelDependenciesTarget: PBXAggregateTarget?
        ) throws -> [ConsolidatedTarget.Key: PBXTarget] {
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
            let disambiguatedTargets: DisambiguatedTargets
            let buildMode: BuildMode
            let pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
            let hostIDs: [TargetID: [TargetID]]
            let xcodeGeneratedFiles: Set<FilePath>
            let filePathResolver: FilePathResolver
        }

        var setTargetConfigurationsCalled: [SetTargetConfigurationsCalled] = []
        func setTargetConfigurations(
            in pbxProj: PBXProj,
            for disambiguatedTargets: DisambiguatedTargets,
            buildMode: BuildMode,
            pbxTargets: [ConsolidatedTarget.Key: PBXTarget],
            hostIDs: [TargetID: [TargetID]],
            xcodeGeneratedFiles: Set<FilePath>,
            filePathResolver: FilePathResolver
        ) {
            setTargetConfigurationsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                buildMode: buildMode,
                pbxTargets: pbxTargets,
                hostIDs: hostIDs,
                xcodeGeneratedFiles: xcodeGeneratedFiles,
                filePathResolver: filePathResolver
            ))
        }

        let expectedSetTargetConfigurationsCalled = [
            SetTargetConfigurationsCalled(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                buildMode: buildMode,
                pbxTargets: pbxTargets,
                hostIDs: project.targetHosts,
                xcodeGeneratedFiles: xcodeGeneratedFiles,
                filePathResolver: filePathResolver
            ),
        ]

        // MARK: setTargetDependencies()

        struct SetTargetDependenciesCalled: Equatable {
            let disambiguatedTargets: DisambiguatedTargets
            let pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
        }

        var setTargetDependenciesCalled: [SetTargetDependenciesCalled] = []
        func setTargetDependencies(
            disambiguatedTargets: DisambiguatedTargets,
            pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
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

        // MARK: createCustomXCSchemes()

        struct CreateCustomXCSchemesCalled: Equatable {
            let schemes: [XcodeScheme]
            let buildMode: BuildMode
            let filePathResolver: FilePathResolver
            let targets: [TargetID: Target]
            let consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key]
            let pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
        }

        var createCustomXCSchemesCalled: [CreateCustomXCSchemesCalled] = []
        func createCustomXCSchemes(
            schemes: [XcodeScheme],
            buildMode: BuildMode,
            filePathResolver: FilePathResolver,
            targets: [TargetID: Target],
            consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key],
            pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
        ) throws -> [XCScheme] {
            createCustomXCSchemesCalled.append(.init(
                schemes: schemes,
                buildMode: buildMode,
                filePathResolver: filePathResolver,
                targets: targets,
                consolidatedTargetKeys: consolidatedTargetKeys,
                pbxTargets: pbxTargets
            ))
            return customXCSchemes
        }

        let expectedCreateCustomXCSchemesCalled = [CreateCustomXCSchemesCalled(
            schemes: customXcodeSchemes,
            buildMode: buildMode,
            filePathResolver: filePathResolver,
            targets: mergedTargets,
            consolidatedTargetKeys: consolidatedTargets.keys,
            pbxTargets: pbxTargets
        )]

        // MARK: createAutogeneratedXCSchemes()

        struct CreateAutogeneratedXCSchemesCalled: Equatable {
            let schemeAutogenerationMode: SchemeAutogenerationMode
            let buildMode: BuildMode
            let targetHosts: [TargetID: [TargetID]]
            let extensionPointIdentifiers:
                [TargetID: ExtensionPointIdentifier]
            let filePathResolver: FilePathResolver
            let consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key]
            let pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
        }

        var createAutogeneratedXCSchemesCalled: [CreateAutogeneratedXCSchemesCalled] = []
        func createAutogeneratedXCSchemes(
            schemeAutogenerationMode: SchemeAutogenerationMode,
            buildMode: BuildMode,
            targetHosts: [TargetID: [TargetID]],
            extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
            filePathResolver: FilePathResolver,
            consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key],
            pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
        ) throws -> [XCScheme] {
            createAutogeneratedXCSchemesCalled.append(.init(
                schemeAutogenerationMode: schemeAutogenerationMode,
                buildMode: buildMode,
                targetHosts: targetHosts,
                extensionPointIdentifiers: extensionPointIdentifiers,
                filePathResolver: filePathResolver,
                consolidatedTargetKeys: consolidatedTargetKeys,
                pbxTargets: pbxTargets
            ))
            return autogeneratedXCSchemes
        }

        let expectedCreateAutogeneratedXCSchemesCalled = [CreateAutogeneratedXCSchemesCalled(
            schemeAutogenerationMode: schemeAutogenerationMode,
            buildMode: buildMode,
            targetHosts: project.targetHosts,
            extensionPointIdentifiers: extensionPointIdentifiers,
            filePathResolver: filePathResolver,
            consolidatedTargetKeys: disambiguatedTargets.keys,
            pbxTargets: pbxTargets
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
            schemes: allXCSchemes
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
            let bazelIntegrationDirectory: Path
            let outputPath: Path
        }

        var writeXcodeProjCalled: [WriteXcodeProjCalled] = []
        func writeXcodeProj(
            xcodeProj: XcodeProj,
            files: [FilePath: File],
            internalDirectoryName: String,
            bazelIntegrationDirectory: Path,
            to outputPath: Path
        ) {
            writeXcodeProjCalled.append(.init(
                xcodeProj: xcodeProj,
                files: files,
                internalDirectoryName: internalDirectoryName,
                bazelIntegrationDirectory: bazelIntegrationDirectory,
                outputPath: outputPath
            ))
        }

        let expectedWriteXcodeProjCalled = [WriteXcodeProjCalled(
            xcodeProj: xcodeProj,
            files: files,
            internalDirectoryName: internalDirectoryName,
            bazelIntegrationDirectory: bazelIntegrationDirectory,
            outputPath: outputPath
        )]

        // MARK: generate()

        let logger = StubLogger()
        let environment = Environment(
            createProject: createProject,
            processTargetMerges: processTargetMerges,
            consolidateTargets: consolidateTargets,
            createFilesAndGroups: createFilesAndGroups,
            createProducts: createProducts,
            populateMainGroup: populateMainGroup,
            disambiguateTargets: disambiguateTargets,
            addBazelDependenciesTarget: addBazelDependenciesTarget,
            addTargets: addTargets,
            setTargetConfigurations: setTargetConfigurations,
            setTargetDependencies: setTargetDependencies,
            createCustomXCSchemes: createCustomXCSchemes,
            createAutogeneratedXCSchemes: createAutogeneratedXCSchemes,
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
            extensionPointIdentifiers: extensionPointIdentifiers,
            projectRootDirectory: projectRootDirectory,
            internalDirectoryName: internalDirectoryName,
            bazelIntegrationDirectory: bazelIntegrationDirectory,
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
            consolidateTargetsCalled,
            expectedConsolidateTargetsCalled
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
            createCustomXCSchemesCalled,
            expectedCreateCustomXCSchemesCalled
        )
        XCTAssertNoDifference(
            createAutogeneratedXCSchemesCalled,
            expectedCreateAutogeneratedXCSchemesCalled
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

    struct MessageLogged: Equatable, Hashable {
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

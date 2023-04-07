import CustomDump
import PathKit
import XCTest

@testable import generator
@testable import XcodeProj

final class GeneratorTests: XCTestCase {
    func test_generate() async throws {
        // Arrange

        let targets: [TargetID: Target] = [
            "I 1": Target.mock(
                label: "@//:I1",
                configuration: "1a2b3",
                product: .init(type: .application, name: "I 1", path: "")
            ),
            "I 2": Target.mock(
                label: "@//:I2",
                configuration: "1a2b3",
                product: .init(type: .application, name: "I 2", path: "")
            ),
            "WKE": Target.mock(
                label: "@//:WKE",
                platform: .device(os: .watchOS),
                product: .init(
                    type: .watch2Extension,
                    name: "WKE",
                    path: .generated("z/WK.appex")
                )
            ),
            "Y": Target.mock(
                label: "@//:Y",
                configuration: "a1b2c",
                product: .init(type: .staticLibrary, name: "Y", path: "")
            ),
            "Z": Target.mock(
                label: "@//:Z",
                configuration: "1a2b3",
                product: .init(type: .application, name: "Z", path: "")
            ),
        ]

        let project = Project(
            name: "P",
            options: Project.Options(
                developmentRegion: "enGB",
                indentWidth: 5,
                tabWidth: 3,
                usesTabs: false
            ),
            bazelConfig: "rules_xcodeproj_test",
            xcodeConfigurations: ["Debug", "Release", "AppStore"],
            defaultXcodeConfiguration: "Release",
            runnerLabel: "@//a/P:xcodeproj",
            minimumXcodeVersion: "13.2.0",
            targets: targets,
            targetHosts: [
                "WKE": ["I 1", "I 2"],
            ],
            args: ["I 1": ["--command_line_args=-AppleLanguages,(en)"]],
            envs: ["I 1": ["I_1_TESTENVS_ENVVAR": "TRUE"]],
            extraFiles: [],
            schemeAutogenerationMode: .auto,
            customXcodeSchemes: [],
            targetIdsFile: "/tmp/target_ids",
            indexImport: "/tmp/index-import",
            preBuildScript: "./pre-build.sh",
            postBuildScript: "./post-build.sh"
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
        let workspaceDirectory: Path = "/Users/TimApple/project"
        let projectRootDirectory: Path = "/Users/TimApple/project/subdir"
        let executionRootDirectory: Path = "/some/bazel"
        let internalDirectoryName = "rules_xcodeproj"
        let workspaceOutputPath: Path = "P.xcodeproj"
        let outputPath: Path = "P.xcodeproj"

        let directories = Directories(
            workspace: workspaceDirectory,
            projectRoot: projectRootDirectory,
            executionRoot: executionRootDirectory,
            internalDirectoryName: internalDirectoryName,
            workspaceOutput: workspaceOutputPath
        )

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
                    targets: ["I 1": targets["I 1"]!]
                ),
                "I 2": .init(
                    targets: ["I 2": targets["I 2"]!]
                ),
                "WKE": .init(
                    targets: ["WKE": targets["WKE"]!]
                ),
                "Y": .init(
                    targets: ["Y": targets["Y"]!]
                ),
                "Z": .init(
                    targets: ["Z": targets["Z"]!]
                ),
            ]
        )
        let disambiguatedTargets = DisambiguatedTargets(
            keys: [
                "Y": "Y",
                "Z": "Z",
                "I 1": "I 1",
                "I 2": "I 2",
                "WKE": "WKE",
            ],
            targets: [
                "Y": .init(
                    name: "Y (3456a)",
                    target: consolidatedTargets.targets["Y"]!
                ),
                "Z": .init(
                    name: "Z (3456a)",
                    target: consolidatedTargets.targets["Z"]!
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
        let xcodeGeneratedFiles = Fixtures
            .xcodeGeneratedFiles(buildMode: buildMode)
        let (
            files,
            filesAndGroups,
            _,
            _,
            resolvedRepositories,
            _
        ) = Fixtures.files(
            in: pbxProj,
            buildMode: buildMode,
            directories: directories
        )
        let rootElements = [filesAndGroups["a"]!, filesAndGroups["x"]!]
        let products = Fixtures.products(in: pbxProj)

        let productsGroup = PBXGroup(name: "42")
        let bazelDependenciesTarget = PBXAggregateTarget(name: "BD")
        let pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget] = [
            "Y": PBXNativeTarget(name: "Y (3456a)"),
            "Z": PBXNativeTarget(name: "Z (3456a)"),
            "I 1": PBXNativeTarget(name: "I1 (3456a)"),
            "I 2": PBXNativeTarget(name: "I2 (3456a)"),
            "WKE": PBXNativeTarget(name: "WKE (3456a)"),
        ]
        let targetResolver = try TargetResolver(
            referencedContainer: directories.containerReference,
            targets: targets,
            targetHosts: project.targetHosts,
            extensionPointIdentifiers: extensionPointIdentifiers,
            consolidatedTargetKeys: disambiguatedTargets.keys,
            pbxTargets: pbxTargets
        )
        let schemeArgs: [TargetID: [String]] = [
            "I 1": ["--command_line_args=-AppleLanguages,(en)"],
        ]
        let schemeEnvs: [TargetID: [String: String]] = [
            "I 1": ["I_1_TESTENVS_ENVVAR": "TRUE"],
        ]
        let customXcodeSchemes = [XcodeScheme]()
        let customXCSchemes: [XCScheme] = [
            .init(name: "Custom Scheme", lastUpgradeVersion: nil, version: nil),
        ]
        let customSchemeNames = Set(customXCSchemes.map(\.name))
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
            let directories: Directories
        }

        var createProjectCalled: [CreateProjectCalled] = []
        func createProject(
            buildMode: BuildMode,
            _forFixtures _: Bool,
            project: Project,
            directories: Directories
        ) -> PBXProj {
            createProjectCalled.append(.init(
                buildMode: buildMode,
                project: project,
                directories: directories
            ))
            return pbxProj
        }

        let expectedCreateProjectCalled = [CreateProjectCalled(
            buildMode: buildMode,
            project: project,
            directories: directories
        )]

        // MARK: calculateXcodeGeneratedFiles()

        struct CalculateXcodeGeneratedFilesCalled: Equatable {
            let buildMode: BuildMode
            let targets: [TargetID: Target]
        }

        var calculateXcodeGeneratedFilesCalled:
            [CalculateXcodeGeneratedFilesCalled] = []
        func calculateXcodeGeneratedFiles(
            buildMode: BuildMode,
            targets: [TargetID: Target]
        ) throws -> [FilePath: FilePath] {
            calculateXcodeGeneratedFilesCalled.append(.init(
                buildMode: buildMode,
                targets: targets
            ))
            return xcodeGeneratedFiles
        }

        let expectedCalculateXcodeGeneratedFilesCalled = [
            CalculateXcodeGeneratedFilesCalled(
                buildMode: buildMode,
                targets: targets
            ),
        ]

        // MARK: createFilesAndGroups()

        struct CreateFilesAndGroupsCalled: Equatable {
            let pbxProj: PBXProj
            let buildMode: BuildMode
            let targets: [TargetID: Target]
            let extraFiles: Set<FilePath>
            let xccurrentversions: [XCCurrentVersion]
            let directories: Directories
        }

        var createFilesAndGroupsCalled: [CreateFilesAndGroupsCalled] = []
        func createFilesAndGroups(
            in pbxProj: PBXProj,
            buildMode: BuildMode,
            _forFixtures _: Bool,
            targets: [TargetID: Target],
            extraFiles: Set<FilePath>,
            xccurrentversions: [XCCurrentVersion],
            directories: Directories,
            logger _: Logger
        ) -> (
            files: [FilePath: File],
            rootElements: [PBXFileElement],
            compileStub: PBXFileReference?,
            resolvedRepositories: [(Path, Path)],
            internalFiles: [Path: String],
            usesExternalFileList: Bool,
            usesGeneratedFileList: Bool
        ) {
            createFilesAndGroupsCalled.append(.init(
                pbxProj: pbxProj,
                buildMode: buildMode,
                targets: targets,
                extraFiles: extraFiles,
                xccurrentversions: xccurrentversions,
                directories: directories
            ))
            return (
                files,
                rootElements,
                nil,
                resolvedRepositories,
                [:],
                true,
                true
            )
        }

        let expectedCreateFilesAndGroupsCalled = [CreateFilesAndGroupsCalled(
            pbxProj: pbxProj,
            buildMode: buildMode,
            targets: targets,
            extraFiles: project.extraFiles,
            xccurrentversions: xccurrentversions,
            directories: directories
        )]

        // MARK: setAdditionalProjectConfiguration()

        struct SetAdditionalProjectConfigurationCalled: Equatable {
            let pbxProj: PBXProj
        }

        var setAdditionalProjectConfigurationCalled:
            [SetAdditionalProjectConfigurationCalled] = []
        func setAdditionalProjectConfiguration(
            in pbxProj: PBXProj,
            resolvedRepositories _: [(Path, Path)]
        ) {
            setAdditionalProjectConfigurationCalled.append(.init(
                pbxProj: pbxProj
            ))
        }

        let expectedSetAdditionalProjectConfigurationCalled = [
            SetAdditionalProjectConfigurationCalled(
                pbxProj: pbxProj
            ),
        ]

        // MARK: consolidateTargets()

        struct ConsolidateTargetsCalled: Equatable {
            let targets: [TargetID: Target]
            let xcodeGeneratedFiles: [FilePath: FilePath]
        }

        var consolidateTargetsCalled: [ConsolidateTargetsCalled] = []
        func consolidateTargets(
            _ targets: [TargetID: Target],
            _ xcodeGeneratedFiles: [FilePath: FilePath],
            logger _: Logger
        ) -> ConsolidatedTargets {
            consolidateTargetsCalled.append(.init(
                targets: targets,
                xcodeGeneratedFiles: xcodeGeneratedFiles
            ))
            return consolidatedTargets
        }

        let expectedConsolidateTargetsCalled = [ConsolidateTargetsCalled(
            targets: targets,
            xcodeGeneratedFiles: xcodeGeneratedFiles
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
            let minimumXcodeVersion: SemanticVersion
            let xcodeConfigurations: Set<String>
            let defaultXcodeConfiguration: String
            let targetIdsFile: String
            let indexImport: String
            let usesExternalFileList: Bool
            let usesGeneratedFileList: Bool
            let bazelConfig: String
            let preBuildScript: String?
            let postBuildScript: String?
            let consolidatedTargets: ConsolidatedTargets
        }

        var addBazelDependenciesTargetCalled: [AddBazelDependenciesTargetCalled]
            = []
        func addBazelDependenciesTarget(
            in pbxProj: PBXProj,
            buildMode: BuildMode,
            minimumXcodeVersion: SemanticVersion,
            xcodeConfigurations: Set<String>,
            defaultXcodeConfiguration: String,
            targetIdsFile: String,
            indexImport: String,
            usesExternalFileList: Bool,
            usesGeneratedFileList: Bool,
            bazelConfig: String,
            preBuildScript: String?,
            postBuildScript: String?,
            consolidatedTargets: ConsolidatedTargets
        ) throws -> PBXAggregateTarget? {
            addBazelDependenciesTargetCalled.append(.init(
                pbxProj: pbxProj,
                buildMode: buildMode,
                minimumXcodeVersion: minimumXcodeVersion,
                xcodeConfigurations: xcodeConfigurations,
                defaultXcodeConfiguration: defaultXcodeConfiguration,
                targetIdsFile: targetIdsFile,
                indexImport: indexImport,
                usesExternalFileList: usesExternalFileList,
                usesGeneratedFileList: usesGeneratedFileList,
                bazelConfig: bazelConfig,
                preBuildScript: preBuildScript,
                postBuildScript: postBuildScript,
                consolidatedTargets: consolidatedTargets
            ))
            return bazelDependenciesTarget
        }

        let expectedAddBazelDependenciesTargetCalled = [
            AddBazelDependenciesTargetCalled(
                pbxProj: pbxProj,
                buildMode: buildMode,
                minimumXcodeVersion: project.minimumXcodeVersion,
                xcodeConfigurations: project.xcodeConfigurations,
                defaultXcodeConfiguration: project.defaultXcodeConfiguration,
                targetIdsFile: project.targetIdsFile,
                indexImport: project.indexImport,
                usesExternalFileList: true,
                usesGeneratedFileList: true,
                bazelConfig: project.bazelConfig,
                preBuildScript: project.preBuildScript,
                postBuildScript: project.postBuildScript,
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
            let compileStub: PBXFileReference?
        }

        var addTargetsCalled: [AddTargetsCalled] = []
        func addTargets(
            in pbxProj: PBXProj,
            for disambiguatedTargets: DisambiguatedTargets,
            buildMode: BuildMode,
            products: Products,
            files: [FilePath: File],
            compileStub: PBXFileReference?
        ) throws -> [ConsolidatedTarget.Key: PBXNativeTarget] {
            addTargetsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                buildMode: buildMode,
                products: products,
                files: files,
                compileStub: compileStub
            ))
            return pbxTargets
        }

        let expectedAddTargetsCalled = [AddTargetsCalled(
            pbxProj: pbxProj,
            disambiguatedTargets: disambiguatedTargets,
            buildMode: buildMode,
            products: products,
            files: files,
            compileStub: nil
        )]

        // MARK: setTargetConfigurations()

        struct SetTargetConfigurationsCalled: Equatable {
            let pbxProj: PBXProj
            let disambiguatedTargets: DisambiguatedTargets
            let targets: [TargetID: Target]
            let buildMode: BuildMode
            let minimumXcodeVersion: SemanticVersion
            let xcodeConfigurations: Set<String>
            let defaultXcodeConfiguration: String
            let pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget]
            let hostIDs: [TargetID: [TargetID]]
            let hasBazelDependencies: Bool
        }

        var setTargetConfigurationsCalled: [SetTargetConfigurationsCalled] = []
        func setTargetConfigurations(
            in pbxProj: PBXProj,
            for disambiguatedTargets: DisambiguatedTargets,
            targets: [TargetID: Target],
            buildMode: BuildMode,
            minimumXcodeVersion: SemanticVersion,
            xcodeConfigurations: Set<String>,
            defaultXcodeConfiguration: String,
            pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
            hostIDs: [TargetID: [TargetID]],
            hasBazelDependencies: Bool
        ) {
            setTargetConfigurationsCalled.append(.init(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                targets: targets,
                buildMode: buildMode,
                minimumXcodeVersion: minimumXcodeVersion,
                xcodeConfigurations: xcodeConfigurations,
                defaultXcodeConfiguration: defaultXcodeConfiguration,
                pbxTargets: pbxTargets,
                hostIDs: hostIDs,
                hasBazelDependencies: hasBazelDependencies
            ))
        }

        let expectedSetTargetConfigurationsCalled = [
            SetTargetConfigurationsCalled(
                pbxProj: pbxProj,
                disambiguatedTargets: disambiguatedTargets,
                targets: targets,
                buildMode: buildMode,
                minimumXcodeVersion: project.minimumXcodeVersion,
                xcodeConfigurations: project.xcodeConfigurations,
                defaultXcodeConfiguration: project.defaultXcodeConfiguration,
                pbxTargets: pbxTargets,
                hostIDs: project.targetHosts,
                hasBazelDependencies: true
            ),
        ]

        // MARK: setTargetDependencies()

        struct SetTargetDependenciesCalled: Equatable {
            let buildMode: BuildMode
            let disambiguatedTargets: DisambiguatedTargets
            let pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget]
            let bazelDependenciesTarget: PBXAggregateTarget?
        }

        var setTargetDependenciesCalled: [SetTargetDependenciesCalled] = []
        func setTargetDependencies(
            buildMode: BuildMode,
            disambiguatedTargets: DisambiguatedTargets,
            pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
            bazelDependenciesTarget: PBXAggregateTarget?
        ) {
            setTargetDependenciesCalled.append(SetTargetDependenciesCalled(
                buildMode: buildMode,
                disambiguatedTargets: disambiguatedTargets,
                pbxTargets: pbxTargets,
                bazelDependenciesTarget: bazelDependenciesTarget
            ))
        }

        let expectedSetTargetDependenciesCalled = [SetTargetDependenciesCalled(
            buildMode: buildMode,
            disambiguatedTargets: disambiguatedTargets,
            pbxTargets: pbxTargets,
            bazelDependenciesTarget: bazelDependenciesTarget
        )]

        // MARK: createCustomXCSchemes()

        struct CreateCustomXCSchemesCalled: Equatable {
            let schemes: [XcodeScheme]
            let buildMode: BuildMode
            let xcodeConfigurations: Set<String>
            let defaultBuildConfigurationName: String
            let targetResolver: TargetResolver
            let runnerLabel: BazelLabel
            let args: [TargetID: [String]]
            let envs: [TargetID: [String: String]]
        }

        var createCustomXCSchemesCalled: [CreateCustomXCSchemesCalled] = []
        func createCustomXCSchemes(
            schemes: [XcodeScheme],
            buildMode: BuildMode,
            xcodeConfigurations: Set<String>,
            defaultBuildConfigurationName: String,
            targetResolver: TargetResolver,
            runnerLabel: BazelLabel,
            args: [TargetID: [String]],
            envs: [TargetID: [String: String]]
        ) throws -> [XCScheme] {
            createCustomXCSchemesCalled.append(.init(
                schemes: schemes,
                buildMode: buildMode,
                xcodeConfigurations: xcodeConfigurations,
                defaultBuildConfigurationName: defaultBuildConfigurationName,
                targetResolver: targetResolver,
                runnerLabel: runnerLabel,
                args: args,
                envs: envs
            ))
            return customXCSchemes
        }

        let expectedCreateCustomXCSchemesCalled = [CreateCustomXCSchemesCalled(
            schemes: customXcodeSchemes,
            buildMode: buildMode,
            xcodeConfigurations: project.xcodeConfigurations,
            defaultBuildConfigurationName: project.defaultXcodeConfiguration,
            targetResolver: targetResolver,
            runnerLabel: project.runnerLabel,
            args: schemeArgs,
            envs: schemeEnvs
        )]

        // MARK: createAutogeneratedXCSchemes()

        struct CreateAutogeneratedXCSchemesCalled: Equatable {
            let schemeAutogenerationMode: SchemeAutogenerationMode
            let buildMode: BuildMode
            let targetResolver: TargetResolver
            let customSchemeNames: Set<String>
            let args: [TargetID: [String]]
            let envs: [TargetID: [String: String]]
        }

        var createAutogeneratedXCSchemesCalled: [CreateAutogeneratedXCSchemesCalled] = []
        func createAutogeneratedXCSchemes(
            schemeAutogenerationMode: SchemeAutogenerationMode,
            buildMode: BuildMode,
            targetResolver: TargetResolver,
            customSchemeNames: Set<String>,
            args: [TargetID: [String]],
            envs: [TargetID: [String: String]]
        ) throws -> [XCScheme] {
            createAutogeneratedXCSchemesCalled.append(.init(
                schemeAutogenerationMode: schemeAutogenerationMode,
                buildMode: buildMode,
                targetResolver: targetResolver,
                customSchemeNames: customSchemeNames,
                args: args,
                envs: envs
            ))
            return autogeneratedXCSchemes
        }

        let expectedCreateAutogeneratedXCSchemesCalled = [CreateAutogeneratedXCSchemesCalled(
            schemeAutogenerationMode: schemeAutogenerationMode,
            buildMode: buildMode,
            targetResolver: targetResolver,
            customSchemeNames: customSchemeNames,
            args: schemeArgs,
            envs: schemeEnvs
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
            let directories: Directories
            let internalFiles: [Path: String]
            let outputPath: Path
        }

        var writeXcodeProjCalled: [WriteXcodeProjCalled] = []
        func writeXcodeProj(
            xcodeProj: XcodeProj,
            directories: Directories,
            internalFiles: [Path: String],
            to outputPath: Path
        ) {
            writeXcodeProjCalled.append(.init(
                xcodeProj: xcodeProj,
                directories: directories,
                internalFiles: internalFiles,
                outputPath: outputPath
            ))
        }

        let expectedWriteXcodeProjCalled = [WriteXcodeProjCalled(
            xcodeProj: xcodeProj,
            directories: directories,
            internalFiles: [:],
            outputPath: outputPath
        )]

        // MARK: generate()

        let logger = StubLogger()
        let environment = Environment(
            createProject: createProject,
            calculateXcodeGeneratedFiles: calculateXcodeGeneratedFiles,
            consolidateTargets: consolidateTargets,
            createFilesAndGroups: createFilesAndGroups,
            setAdditionalProjectConfiguration:
                setAdditionalProjectConfiguration,
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

        try await generator.generate(
            buildMode: buildMode,
            forFixtures: false,
            project: project,
            xccurrentversions: xccurrentversions,
            extensionPointIdentifiers: extensionPointIdentifiers,
            directories: directories,
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
            calculateXcodeGeneratedFilesCalled,
            expectedCalculateXcodeGeneratedFilesCalled
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
            setAdditionalProjectConfigurationCalled,
            expectedSetAdditionalProjectConfigurationCalled
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

    func logDebug(_ message: String) {
        messagesLogged.append(.init(.debug, message))
    }

    func logInfo(_ message: String) {
        messagesLogged.append(.init(.info, message))
    }

    func logWarning(_ message: String) {
        messagesLogged.append(.init(.warning, message))
    }

    func logError(_ message: String) {
        messagesLogged.append(.init(.error, message))
    }
}

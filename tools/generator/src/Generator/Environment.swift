import PathKit
import XcodeProj

/// Provides `Generator`'s dependencies.
///
/// The main purpose of `Environment` is to enable dependency injection,
/// allowing for different implementations to be used in tests.
struct Environment {
    let createProject: (
        _ buildMode: BuildMode,
        _ forFixtures: Bool,
        _ project: Project,
        _ directories: Directories
    ) -> PBXProj

    let calculateXcodeGeneratedFiles: (
        _ buildMode: BuildMode,
        _ targets: [TargetID: Target]
    ) throws -> [FilePath: FilePath]

    let consolidateTargets: (
        _ targets: [TargetID: Target],
        _ xcodeGeneratedFiles: [FilePath: FilePath],
        _ logger: Logger
    ) throws -> ConsolidatedTargets

    let createFilesAndGroups: (
        _ pbxProj: PBXProj,
        _ buildMode: BuildMode,
        _ forFixtures: Bool,
        _ targets: [TargetID: Target],
        _ extraFiles: Set<FilePath>,
        _ xccurrentversions: [XCCurrentVersion],
        _ directories: Directories,
        _ logger: Logger
    ) throws -> (
        files: [FilePath: File],
        rootElements: [PBXFileElement],
        compileStub: PBXFileReference?,
        resolvedRepositories: [(Path, Path)],
        internalFiles: [Path: String],
        usesExternalFileList: Bool,
        usesGeneratedFileList: Bool
    )

    let setAdditionalProjectConfiguration: (
        _ pbxProj: PBXProj,
        _ resolvedRepositories: [(Path, Path)]
    ) -> Void

    let createProducts: (
        _ pbxProj: PBXProj,
        _ consolidatedTargets: ConsolidatedTargets
    ) -> (Products, PBXGroup)

    let populateMainGroup: (
        _ mainGroup: PBXGroup,
        _ pbxProj: PBXProj,
        _ rootElements: [PBXFileElement],
        _ productsGroup: PBXGroup
    ) -> Void

    let disambiguateTargets: (
        _ consolidatedTargets: ConsolidatedTargets
    ) -> DisambiguatedTargets

    let addBazelDependenciesTarget: (
        _ pbxProj: PBXProj,
        _ buildMode: BuildMode,
        _ minimumXcodeVersion: SemanticVersion,
        _ xcodeConfigurations: Set<String>,
        _ defaultXcodeConfiguration: String,
        _ indexImport: String,
        _ usesExternalFileList: Bool,
        _ usesGeneratedFileList: Bool,
        _ bazelConfig: String,
        _ generatorLabel: BazelLabel,
        _ preBuildScript: String?,
        _ postBuildScript: String?,
        _ consolidatedTargets: ConsolidatedTargets
    ) throws -> PBXAggregateTarget?

    let addTargets: (
        _ pbxProj: PBXProj,
        _ disambiguatedTargets: DisambiguatedTargets,
        _ buildMode: BuildMode,
        _ products: Products,
        _ files: [FilePath: File],
        _ compileStub: PBXFileReference?
    ) async throws -> [ConsolidatedTarget.Key: PBXNativeTarget]

    let setTargetConfigurations: (
        _ pbxProj: PBXProj,
        _ disambiguatedTargets: DisambiguatedTargets,
        _ targets: [TargetID: Target],
        _ buildMode: BuildMode,
        _ minimumXcodeVersion: SemanticVersion,
        _ xcodeConfigurations: Set<String>,
        _ defaultXcodeConfiguration: String,
        _ pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
        _ hostIDs: [TargetID: [TargetID]],
        _ hasBazelDependencies: Bool
    ) async throws -> Void

    let setTargetDependencies: (
        _ buildMode: BuildMode,
        _ disambiguatedTargets: DisambiguatedTargets,
        _ pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
        _ bazelDependenciesTarget: PBXAggregateTarget?
    ) throws -> Void

    let createCustomXCSchemes: (
        _ schemes: [XcodeScheme],
        _ buildMode: BuildMode,
        _ xcodeConfigurations: Set<String>,
        _ defaultBuildConfigurationName: String,
        _ targetResolver: TargetResolver,
        _ xcodeprojLabel: BazelLabel,
        _ args: [TargetID: [String]],
        _ envs: [TargetID: [String: String]]
    ) throws -> [XCScheme]

    let createAutogeneratedXCSchemes: (
        _ schemeAutogenerationMode: SchemeAutogenerationMode,
        _ buildMode: BuildMode,
        _ targetResolver: TargetResolver,
        _ customSchemeNames: Set<String>,
        _ args: [TargetID: [String]],
        _ envs: [TargetID: [String: String]]
    ) throws -> [XCScheme]

    let createXCSharedData: (_ schemes: [XCScheme]) -> XCSharedData

    let createXcodeProj: (
        _ pbxProj: PBXProj,
        _ sharedData: XCSharedData?
    ) -> XcodeProj

    let writeXcodeProj: (
        _ xcodeProj: XcodeProj,
        _ directories: Directories,
        _ internalFiles: [Path: String],
        _ outputPath: Path
    ) throws -> Void
}

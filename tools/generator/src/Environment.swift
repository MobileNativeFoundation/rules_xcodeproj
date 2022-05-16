import PathKit
import XcodeProj

/// Provides `Generator`'s dependencies.
///
/// The main purpose of `Environment` is to enable dependency injection,
/// allowing for different implementations to be used in tests.
struct Environment {
    let createProject: (
        _ buildMode: BuildMode,
        _ project: Project,
        _ projectRootDirectory: Path,
        _ filePathResolver: FilePathResolver
    ) -> PBXProj

    let processTargetMerges: (
        _ targets: inout [TargetID: Target],
        _ targetMerges: [TargetID: Set<TargetID>]
    ) throws -> Void

    let createFilesAndGroups: (
        _ pbxProj: PBXProj,
        _ buildMode: BuildMode,
        _ targets: [TargetID: Target],
        _ extraFiles: Set<FilePath>,
        _ xccurrentversions: [XCCurrentVersion],
        _ filePathResolver: FilePathResolver,
        _ logger: Logger
    ) throws -> (
        files: [FilePath: File],
        rootElements: [PBXFileElement]
    )

    let createProducts: (
        _ pbxProj: PBXProj,
        _ targets: [TargetID: Target]
    ) -> (Products, PBXGroup)

    let populateMainGroup: (
        _ mainGroup: PBXGroup,
        _ pbxProj: PBXProj,
        _ rootElements: [PBXFileElement],
        _ productsGroup: PBXGroup
    ) -> Void

    let disambiguateTargets: (
        _ targets: [TargetID: Target]
    ) -> [TargetID: DisambiguatedTarget]

    let addBazelDependenciesTarget: (
        _ pbxProj: PBXProj,
        _ buildMode: BuildMode,
        _ files: [FilePath: File],
        _ filePathResolver: FilePathResolver,
        _ xcodeprojBazelLabel: String,
        _ xcodeprojConfiguration: String
    ) throws -> PBXAggregateTarget?

    let addTargets: (
        _ pbxProj: PBXProj,
        _ disambiguatedTargets: [TargetID: DisambiguatedTarget],
        _ buildMode: BuildMode,
        _ products: Products,
        _ files: [FilePath: File],
        _ filePathResolver: FilePathResolver,
        _ bazelDependenciesTarget: PBXAggregateTarget?
    ) throws -> [TargetID: PBXTarget]

    let setTargetConfigurations: (
        _ pbxProj: PBXProj,
        _ disambiguatedTargets: [TargetID: DisambiguatedTarget],
        _ pbxTargets: [TargetID: PBXTarget],
        _ filePathResolver: FilePathResolver
    ) throws -> Void

    let setTargetDependencies: (
        _ disambiguatedTargets: [TargetID: DisambiguatedTarget],
        _ pbxTargets: [TargetID: PBXTarget]
    ) throws -> Void

    let createXCSchemes: (
        _ buildMode: BuildMode,
        _ filePathResolver: FilePathResolver,
        _ pbxTargets: [TargetID: PBXTarget]
    ) throws -> [XCScheme]

    let createXCSharedData: (_ schemes: [XCScheme]) -> XCSharedData

    let createXcodeProj: (
        _ pbxProj: PBXProj,
        _ sharedData: XCSharedData?
    ) -> XcodeProj

    let writeXcodeProj: (
        _ xcodeProj: XcodeProj,
        _ buildMode: BuildMode,
        _ files: [FilePath: File],
        _ internalDirectoryName: String,
        _ bazelIntegrationDirectory: Path,
        _ outputPath: Path
    ) throws -> Void
}

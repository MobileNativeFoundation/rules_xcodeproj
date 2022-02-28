import PathKit
import XcodeProj

/// Provides `Generator`'s dependencies.
///
/// The main purpose of `Environment` is to enable dependency injection,
/// allowing for different implementations to be used in tests.
struct Environment {
    let createProject: (
        _ project: Project,
        _ projectRootDirectory: Path
    ) -> PBXProj

    let processTargetMerges: (
        _ targets: inout [TargetID: Target],
        _ potentialTargetMerges: [TargetID: Set<TargetID>],
        _ requiredLinks: Set<Path>
    ) throws -> [InvalidMerge]

    let createFilesAndGroups: (
        _ pbxProj: PBXProj,
        _ targets: [TargetID: Target],
        _ extraFiles: Set<Path>,
        _ externalDirectory: Path,
        _ internalDirectoryName: String,
        _ workspaceOutputPath: Path
    ) -> (
        elements: [FilePath: PBXFileElement],
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
}

import PathKit
import XcodeProj

/// Provides `Generator`'s dependencies.
///
/// The main purpose of `Environment` is to enable dependency injection,
/// allowing for different implementations to be used in tests.
struct Environment {
    let createProject: (_ project: Project) -> PBXProj

    let processTargetMerges: (
        _ targets: inout [TargetID: Target],
        _ potentialTargetMerges: [TargetID: Set<TargetID>],
        _ requiredLinks: Set<Path>
    ) throws -> [InvalidMerge]

    let logger: Logger
}

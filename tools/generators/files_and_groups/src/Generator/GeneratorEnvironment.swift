import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculatePathTree: (_ paths: Set<BazelPath>) -> PathTreeNode

        let elements: ElementCreator.Environment

        let filesAndGroupsPartial: (
            _ elementsPartial: String
        ) -> String

        let knownRegionsPartial: (
            _ knownRegions: Set<String>,
            _ developmentRegion: String,
            _ useBaseInternationalization: Bool
        ) -> String

        let resolvedRepositoriesBuildSetting: (
            _ resolvedRepositories: [ResolvedRepository]
        ) -> String

        let write: (_ content: String, _ outputPath: URL) throws -> Void
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculatePathTree: Generator.calculatePathTree,
        elements: ElementCreator.Environment.default,
        filesAndGroupsPartial: Generator.filesAndGroupsPartial,
        knownRegionsPartial: Generator.knownRegionsPartial,
        resolvedRepositoriesBuildSetting:
            Generator.resolvedRepositoriesBuildSetting,
        write: Generator.write
    )
}

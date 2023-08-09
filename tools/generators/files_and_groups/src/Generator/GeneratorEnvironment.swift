import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculateTargetFilesPartial: CalculateTargetFilesPartial

        let calculatePathTree: (_ paths: Set<BazelPath>) -> PathTreeNode

        let createTargetFileObjects: CreateTargetFileObjects

        let elements: ElementCreator.Environment

        let filesAndGroupsPartial: (
            _ buildFilesPartial: String,
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

        let write: Write
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculateTargetFilesPartial: Generator.CalculateTargetFilesPartial(),
        calculatePathTree: Generator.calculatePathTree,
        createTargetFileObjects: Generator.CreateTargetFileObjects(
            createShardTargetFileObjects:
                Generator.CreateShardTargetFileObjects(
                    createBuildFileObject: Generator.CreateBuildFileObject(),
                    readBuildFileSubIdentifiersFile:
                        Generator.ReadBuildFileSubIdentifiersFile()
                )
        ),
        elements: ElementCreator.Environment.default,
        filesAndGroupsPartial: Generator.filesAndGroupsPartial,
        knownRegionsPartial: Generator.knownRegionsPartial,
        resolvedRepositoriesBuildSetting:
            Generator.resolvedRepositoriesBuildSetting,
        write: Write()
    )
}

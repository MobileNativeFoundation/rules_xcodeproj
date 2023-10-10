import Foundation
import PBXProj
import ToolCommon

/// A type that generates and writes to disk the `PBXTargetDependency` `PBXProj`
/// partial, `PBXProject.attributes.TargetAttributes` `PBXProj` partial,
/// `PBXProject.targets` `PBXProj` partial, and target consolidation map files.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXTargetDependency` `PBXProj` partial,
    /// `PBXProject.attributes.TargetAttributes` `PBXProj` partial,
    /// `PBXProject.targets` `PBXProj` partial, , and target consolidation map
    /// files. Then it writes them to disk.
    func generate(arguments: Arguments, logger: Logger) async throws {
        let testHosts = arguments.testHosts
        let watchKitExtensions = arguments.watchKitExtensions

        let identifiedTargets = try await environment.identifyTargets(
            consolidationMapArguments: try .parse(
                from: arguments.consolidationMapsInputsFile,
                testHosts: testHosts,
                watchKitExtensions: watchKitExtensions
            ),
            logger: logger
        )

        let writeTargetsTask = Task {
            try environment.write(
                environment.calculateTargetsPartial(
                    identifiers: identifiedTargets.map(\.identifier.full)
                ),
                to: arguments.targetsOutputPath
            )
        }

        let identifiedTargetsMap = environment
            .calculateIdentifiedTargetsMap(identifiedTargets: identifiedTargets)

        let writeConsolidationMapsTask = Task {
            try await environment.writeConsolidationMaps(
                try environment.calculateConsolidationMaps(
                    identifiedTargets: identifiedTargets,
                    identifiedTargetsMap: identifiedTargetsMap
                )
            )
        }

        let writeTargetAttributesTask = Task {
            try environment.write(
                environment.calculateTargetAttributesPartial(
                    objects: environment.createTargetAttributesObjects(
                        identifiedTargets: identifiedTargets,
                        identifiedTargetsMap: identifiedTargetsMap,
                        testHosts: testHosts,
                        createdOnToolsVersion: environment
                            .calculateCreatedOnToolsVersion(
                                minimumXcodeVersion: arguments
                                    .minimumXcodeVersion
                            )
                    )
                ),
                to: arguments.targetAttributesOutputPath
            )
        }

        let writeTargetDependenciesTask = Task {
            try environment.write(
                environment.calculateTargetDependenciesPartial(
                    objects: environment.createDependencyObjects(
                        identifiedTargets: identifiedTargets,
                        identifiedTargetsMap: identifiedTargetsMap
                    )
                ),
                to: arguments.targetDependenciesOutputPath
            )
        }

        // Wait for all of the writes to complete
        try await writeConsolidationMapsTask.value
        try await writeTargetsTask.value
        try await writeTargetAttributesTask.value
        try await writeTargetDependenciesTask.value
    }
}

import Foundation
import GeneratorCommon
import PBXProj

/// A type that generates and writes to disk the
/// `PBXProject.attributes.TargetAttributes` `PBXProj` partial,
/// `PBXProject.targets` `PBXProj` partial, `PBXTargetDependency` `PBXProj`
/// partial, and target consolidation map files.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXProject.attributes.TargetAttributes` `PBXProj`
    /// partial, `PBXProject.targets` `PBXProj` partial, `PBXTargetDependency`
    // `PBXProj` partial, and target consolidation map files. Then it writes
    /// them to disk.
    func generate(arguments: Arguments, logger: Logger) async throws {
        let identifiedTargets = try environment.identifyTargets(
            consolidationMapArguments: arguments
                .consolidationMapsArguments.toConsolidationMapArguments(),
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

        let identifiers = environment
            .calculateTargetIdentifierMap(identifiedTargets: identifiedTargets)

        let writeConsolidationMapsTask = Task {
            try await environment.writeConsolidationMaps(
                try environment.calculateConsolidationMaps(
                    identifiedTargets: identifiedTargets,
                    identifiers: identifiers
                )
            )
        }

        let writeTargetAttributesTask = Task {
            try environment.write(
                environment.calculateTargetAttributesPartial(
                    elements: environment.calculateTargetAttributes(
                        identifiedTargets: identifiedTargets,
                        testHosts: arguments.testHosts,
                        identifiers: identifiers,
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
                    elements: environment.calculateTargetDependencies(
                        identifiedTargets: identifiedTargets,
                        identifiers: identifiers
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

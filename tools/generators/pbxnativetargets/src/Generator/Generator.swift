import Foundation
import OrderedCollections
import PBXProj
import ToolCommon

/// A type that generates and writes to disk the `PBXNativeTarget` `PBXProj`
/// partial, `PBXBuildFile` map files, and automatic `.xcscheme` files.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXNativeTarget` `PBXProj` partial, `PBXBuildFile` map
    /// files, and automatic `.xcscheme` files. Then it writes them to disk.
    func generate(arguments: Arguments) async throws {
        let consolidationMapEntries = try await ConsolidationMapEntry
            .decode(from: arguments.consolidationMap)

        let targetArguments = try await [TargetID: TargetArguments]
            .parse(from: arguments.targetArgumentsFile)

        let topLevelTargetAttributes =
            try await [TargetID: TopLevelTargetAttributes].parse(
                from: arguments.topLevelTargetAttributesFile
            )
        let unitTestHosts =
            try await [TargetID: Target.UnitTestHost].parse(
                from: arguments.unitTestHostAttributesFile
            )

        let defaultXcodeConfiguration = arguments.defaultXcodeConfiguration
        let xcodeConfigurations: Set<String> = targetArguments.values
            .reduce(into: []) { xcodeConfigurations, targetArguments in
                xcodeConfigurations
                    .formUnion(targetArguments.xcodeConfigurations)
            }

        guard
            let shard = UInt8(arguments.consolidationMap.lastPathComponent)
        else {
            throw PreconditionError(message: #"""
Consolidation map (\#(arguments.consolidationMap)) basename is not formatted \#
correctly
"""#)
        }

        var buildFileSubIdentifiers:
            [Identifiers.BuildFiles.SubIdentifier] = []
        var objects: [Object] = []
        for entry in consolidationMapEntries {
            let (
                targetBuildFileSubIdentifiers,
                targetObjects
            ) = try await environment.createTarget(
                consolidationMapEntry: entry,
                defaultXcodeConfiguration: defaultXcodeConfiguration,
                shard: shard,
                targetArguments: targetArguments,
                topLevelTargetAttributes: topLevelTargetAttributes,
                unitTestHosts: unitTestHosts,
                xcodeConfigurations: xcodeConfigurations
            )
            buildFileSubIdentifiers
                .append(contentsOf: targetBuildFileSubIdentifiers)
            objects.append(contentsOf: targetObjects)
        }

        let finalBuildFileSubIdentifiers = buildFileSubIdentifiers
        let finalObjects = objects

        let writeTargetsTask = Task {
            try environment.write(
                environment.calculatePartial(objects: finalObjects),
                to: arguments.targetsOutputPath
            )
        }
        let writeBuildFileSubIdentifiersTask = Task {
            try environment.writeBuildFileSubIdentifiers(
                finalBuildFileSubIdentifiers,
                to: arguments.buildFileSubIdentifiersOutputPath
            )
        }

        // Wait for all of the writes to complete
        try await writeTargetsTask.value
        try await writeBuildFileSubIdentifiersTask.value
    }
}

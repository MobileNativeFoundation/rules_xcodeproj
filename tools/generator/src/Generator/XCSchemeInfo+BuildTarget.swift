import XcodeProj

extension XCSchemeInfo {
    struct BuildTarget: Equatable, Hashable {
        let targetInfo: XCSchemeInfo.TargetInfo
        let buildFor: BuildFor

        init(
            targetInfo: XCSchemeInfo.TargetInfo,
            buildFor: BuildFor = .init()
        ) {
            self.targetInfo = targetInfo
            self.buildFor = buildFor
        }
    }
}

extension Sequence where Element == XCSchemeInfo.BuildTarget {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        get throws {
            // Create a (BuildableReference, BuildFor) for all buildable references
            let buildRefAndBuildFors = flatMap { buildTarget in
                return buildTarget.targetInfo.buildableReferences.map { ($0, buildTarget.buildFor) }
            }

            // Collect the buildFors by BuildableReference, create the BuildAction.Entry values, and
            // sort the result.
            return try Dictionary(grouping: buildRefAndBuildFors, by: { $0.0 })
                .map { buildableReference, buildRefAndBuildFors in
                    return XCScheme.BuildAction.Entry(
                        buildableReference: buildableReference,
                        buildFor: try buildRefAndBuildFors.map(\.1).merged().asXCSchemeBuildFor
                    )
                }
                // Sort by in stable order by blueprint name
                .sortedLocalizedStandard(\.buildableReference.blueprintName)
        }
    }
}

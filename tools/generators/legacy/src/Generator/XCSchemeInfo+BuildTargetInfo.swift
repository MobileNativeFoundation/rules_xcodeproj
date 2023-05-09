import XcodeProj

extension XCSchemeInfo {
    struct BuildTargetInfo: Equatable, Hashable {
        let targetInfo: XCSchemeInfo.TargetInfo
        var buildFor: XcodeScheme.BuildFor

        init(
            targetInfo: XCSchemeInfo.TargetInfo,
            buildFor: XcodeScheme.BuildFor
        ) {
            self.targetInfo = targetInfo
            self.buildFor = buildFor
        }
    }
}

extension Sequence where Element == XCSchemeInfo.BuildTargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        get throws {
            // Create a (BuildableReference, BuildFor) for all buildable references
            let buildRefAndBuildFors = flatMap { buildTargetInfo in
                return buildTargetInfo.targetInfo.buildableReferences.map {
                    ($0, buildTargetInfo.buildFor)
                }
            }

            // Collect the buildFors by BuildableReference, create the BuildAction.Entry values, and
            // sort the result.
            return try Dictionary(grouping: buildRefAndBuildFors, by: { $0.0 })
                .map { buildableReference, buildRefAndBuildFors in
                    return try XCScheme.BuildAction.Entry(
                        buildableReference: buildableReference,
                        buildFor: buildRefAndBuildFors.map(\.1).merged().xcSchemeValue
                    )
                }
                // Sort by in stable order by blueprint name
                .sortedLocalizedStandard(\.buildableReference.blueprintName)
        }
    }
}

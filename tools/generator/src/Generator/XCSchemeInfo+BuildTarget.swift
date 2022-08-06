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
        // Create a (BuildableReference, BuildFor) for all buildable references
        return flatMap { buildTarget in
                return buildTarget.targetInfo.buildableReferences.map { ($0, buildTarget.buildFor) }
            }
            // Sort by in stable order by blueprint name
            .sortedLocalizedStandard(\.0.blueprintName)
            // GH573: Pass the buildFor information to BuildAction.Entry init
            // TODO(chuck): Do I need to dedupe and merge buildFor due to the same host appearing
            // multiple times in the list?
            .map { buildableReference, _ in .init(withDefaults: buildableReference) }
    }
}

import XcodeProj

extension XCScheme {
    struct PBXTargetInfo {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference
        let hostInfos: [PBXHostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool

        init<PBXHostInfos: Sequence, ExtPointIdentifiers: Sequence>(
            pbxTarget: PBXTarget,
            referencedContainer: String,
            hostInfos: PBXHostInfos,
            extensionPointIdentifiers: ExtPointIdentifiers
        ) where PBXHostInfos.Element == XCScheme.PBXHostInfo,
            ExtPointIdentifiers.Element == ExtensionPointIdentifier
        {
            self.pbxTarget = pbxTarget
            buildableReference = .init(
                pbxTarget: pbxTarget,
                referencedContainer: referencedContainer
            )
            self.hostInfos = Array(hostInfos)
            disambiguateHost = self.hostInfos.count > 1
            self.extensionPointIdentifiers = Set(extensionPointIdentifiers)
        }
    }
}

// MARK: BuildableReference Accessor

extension Sequence where Element == XCScheme.PBXTargetInfo {
    /// Return all of the buildable references.
    var buildableReferences: [XCScheme.BuildableReference] {
        return map(\.buildableReference) + flatMap(\.hostInfos).map(\.buildableReference)
    }
}

// MARK: BuildAction.Entry Accessor

extension Sequence where Element == XCScheme.PBXTargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        return buildableReferences.map { .init(withDefaults: $0) }
    }
}

// MARK: ExecutionActions Accessors

extension XCScheme.PBXTargetInfo {
    var bazelBuildPreActions: [XCScheme.ExecutionAction] {
        guard pbxTarget is PBXNativeTarget else {
            return []
        }
        if hostInfos.isEmpty {
            return [.init(bazelBuildFor: buildableReference, name: pbxTarget.name, hostIndex: nil)]
        }
        return hostInfos.map(\.index).map {
            .init(bazelBuildFor: buildableReference, name: pbxTarget.name, hostIndex: $0)
        }
    }
}

extension Sequence where Element == XCScheme.PBXTargetInfo {
    var bazelBuildPreActions: [XCScheme.ExecutionAction] {
        return [.initBazelBuildOutputGroupsFile] + flatMap(\.bazelBuildPreActions)
    }
}

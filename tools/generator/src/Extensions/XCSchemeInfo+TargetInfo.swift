import XcodeProj

extension XCSchemeInfo {
    struct TargetInfo {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference
        let hostInfos: [HostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool

        init<HostInfos: Sequence, ExtPointIdentifiers: Sequence>(
            pbxTarget: PBXTarget,
            referencedContainer: String,
            hostInfos: HostInfos,
            extensionPointIdentifiers: ExtPointIdentifiers
        ) where HostInfos.Element == XCSchemeInfo.HostInfo,
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

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    /// Return all of the buildable references.
    var buildableReferences: [XCScheme.BuildableReference] {
        return map(\.buildableReference) + flatMap(\.hostInfos).map(\.buildableReference)
    }
}

// MARK: BuildAction.Entry Accessor

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        return buildableReferences.map { .init(withDefaults: $0) }
    }
}

// MARK: ExecutionActions Accessors

extension XCSchemeInfo.TargetInfo {
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

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    var bazelBuildPreActions: [XCScheme.ExecutionAction] {
        return [.initBazelBuildOutputGroupsFile] + flatMap(\.bazelBuildPreActions)
    }
}

// MARK: isWidgetKitExtension

extension XCSchemeInfo.TargetInfo {
    var isWidgetKitExtension: Bool {
        return extensionPointIdentifiers.contains(.widgetKitExtension)
    }
}

// MARK: productType

extension XCSchemeInfo.TargetInfo {
    var productType: PBXProductType {
        return pbxTarget.productType ?? .none
    }
}

import XcodeProj

extension XCSchemeInfo {
    struct TargetInfo {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference
        let hostInfos: [HostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool
        let selectedHostInfo: HostInfo?

        /// Initializer used when creating a TargetInfo for the first time.
        init<HostInfos: Sequence, ExtPointIdentifiers: Sequence>(
            pbxTarget: PBXTarget,
            referencedContainer: String,
            hostInfos: HostInfos,
            extensionPointIdentifiers: ExtPointIdentifiers
        ) where HostInfos.Element == XCSchemeInfo.HostInfo,
            ExtPointIdentifiers.Element == ExtensionPointIdentifier
        {
            self.init(
                pbxTarget: pbxTarget,
                buildableReference: .init(
                    pbxTarget: pbxTarget,
                    referencedContainer: referencedContainer
                ),
                hostInfos: Array(hostInfos),
                extensionPointIdentifiers: Set(extensionPointIdentifiers),
                selectedHostInfo: nil
            )
        }

        /// Initializer used when resolving a selected host.
        init(
            resolveHostFor original: XCSchemeInfo.TargetInfo,
            topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
        ) {
            // Look for a host that is one of the top-level targets.
            let topLevelPBXTargetInfos = Set(topLevelTargetInfos.map(\.pbxTarget))
            var selectedHostInfo = original.hostInfos
                .filter { topLevelPBXTargetInfos.contains($0.pbxTarget) }
                .first
            // If a top-level host was not found, then just pick one of the hosts.
            if selectedHostInfo == nil {
                selectedHostInfo = original.hostInfos.first
            }

            self.init(
                pbxTarget: original.pbxTarget,
                buildableReference: original.buildableReference,
                hostInfos: original.hostInfos,
                extensionPointIdentifiers: original.extensionPointIdentifiers,
                selectedHostInfo: selectedHostInfo
            )
        }

        /// Low-level initializer used by the other initializers.
        private init(
            pbxTarget: PBXTarget,
            buildableReference: XCScheme.BuildableReference,
            hostInfos: [HostInfo],
            extensionPointIdentifiers: Set<ExtensionPointIdentifier>,
            selectedHostInfo: HostInfo?
        ) {
            self.pbxTarget = pbxTarget
            self.buildableReference = buildableReference
            self.hostInfos = hostInfos
            self.extensionPointIdentifiers = extensionPointIdentifiers
            disambiguateHost = self.hostInfos.count > 1
            self.selectedHostInfo = selectedHostInfo
        }
    }
}

// MARK: buildableReferences

extension XCSchemeInfo.TargetInfo {
    /// Returns the target buildable reference along with the selected host's buildable reference,
    /// if applicable.
    var buildableReferences: [XCScheme.BuildableReference] {
        var results = [buildableReference]
        // Only include the selected host, not all of the hosts.
        if let selectedHostInfo = selectedHostInfo {
            results.append(selectedHostInfo.buildableReference)
        }
        return results
    }
}

// MARK: bazelBuildPreActions

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

// MARK: Sequence Extensions

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        return buildableReferences.map { .init(withDefaults: $0) }
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    // TODO(chuck): I would prefer to return a Set<XCScheme.BuildableReference> from
    // buildableReferences, but it is not hashable. Can we extend it to be Hashable?

    /// Return all of the buildable references for all of the target infos.
    var buildableReferences: [XCScheme.BuildableReference] {
        return flatMap(\.buildableReferences)
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    var bazelBuildPreActions: [XCScheme.ExecutionAction] {
        return [.initBazelBuildOutputGroupsFile] + flatMap(\.bazelBuildPreActions)
    }
}

import XcodeProj

extension XCSchemeInfo {
    enum HostResolution: Equatable, Hashable {
        /// Host resolution has not occurred.
        case unresolved
        /// Host resoultion has occurred. No host was selected.
        case none
        /// Host resolution has occurred. Host was selected.
        case selected(HostInfo)
    }

    struct TargetInfo: Equatable, Hashable {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference
        let hostInfos: [HostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool
        let hostResolution: HostResolution

        /// Initializer used when creating a `TargetInfo` for the first time.
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
                hostResolution: .unresolved
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

            // GH573: Update "best" host logic to select by platform.  Since this will cause
            // that host to be built, ideally it's the "best" host (based on platform similar to
            // other "best"s).

            // If a top-level host was not found, then just pick one of the hosts.
            if selectedHostInfo == nil {
                selectedHostInfo = original.hostInfos.first
            }

            let hostResolution: HostResolution
            if let selectedHostInfo = selectedHostInfo {
                hostResolution = .selected(selectedHostInfo)
            } else {
                hostResolution = .none
            }

            self.init(
                pbxTarget: original.pbxTarget,
                buildableReference: original.buildableReference,
                hostInfos: original.hostInfos,
                extensionPointIdentifiers: original.extensionPointIdentifiers,
                hostResolution: hostResolution
            )
        }

        /// Low-level initializer used by the other initializers.
        private init(
            pbxTarget: PBXTarget,
            buildableReference: XCScheme.BuildableReference,
            hostInfos: [HostInfo],
            extensionPointIdentifiers: Set<ExtensionPointIdentifier>,
            hostResolution: HostResolution
        ) {
            self.pbxTarget = pbxTarget
            self.buildableReference = buildableReference
            self.hostInfos = hostInfos
            self.extensionPointIdentifiers = extensionPointIdentifiers
            disambiguateHost = self.hostInfos.count > 1
            self.hostResolution = hostResolution
        }
    }
}

// MARK: `selectedHostInfo`

extension XCSchemeInfo.TargetInfo {
    var selectedHostInfo: XCSchemeInfo.HostInfo? {
        get throws {
            switch hostResolution {
            case .unresolved:
                throw PreconditionError(message: """
Cannot access `selectedHostInfo` until host resolution has occurred.
""")
            case .none:
                return nil
            case let .selected(selectedHostInfo):
                return selectedHostInfo
            }
        }
    }
}

// MARK: `buildableReferences`

extension XCSchemeInfo.TargetInfo {
    /// Returns the target buildable reference along with the selected host's buildable reference,
    /// if applicable.
    var buildableReferences: [XCScheme.BuildableReference] {
        var results = [buildableReference]
        // Only include the selected host, not all of the hosts.
        if case let .selected(selectedHostInfo) = hostResolution {
            results.append(selectedHostInfo.buildableReference)
        }
        return results
    }
}

// MARK: `bazelBuildPreActions`

extension XCSchemeInfo.TargetInfo {
    func buildPreAction(buildMode: BuildMode) throws -> XCScheme.ExecutionAction? {
        guard pbxTarget is PBXNativeTarget else {
            return nil
        }
        return .init(
            buildFor: buildableReference,
            buildMode: buildMode,
            name: pbxTarget.name,
            hostIndex: try selectedHostInfo?.index
        )
    }
}

// MARK: `isWidgetKitExtension`

extension XCSchemeInfo.TargetInfo {
    var isWidgetKitExtension: Bool {
        return extensionPointIdentifiers.contains(.widgetKitExtension)
    }
}

// MARK: `productType`

extension XCSchemeInfo.TargetInfo {
    var productType: PBXProductType {
        return pbxTarget.productType ?? .none
    }
}

// MARK: Sequence Extensions

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    /// Return all of the buildable references for all of the target infos.
    var buildableReferences: [XCScheme.BuildableReference] {
        return flatMap(\.buildableReferences)
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        return buildableReferences.map { .init(withDefaults: $0) }
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    func buildPreActions(buildMode: BuildMode) throws -> [XCScheme.ExecutionAction] {
        let preActions = try compactMap { try $0.buildPreAction(buildMode: buildMode) }
        return [.initBazelBuildOutputGroupsFile] + preActions
    }
}

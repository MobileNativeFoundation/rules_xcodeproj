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
        // The platforms property is a sorted list of unique platforms.
        let platforms: [Platform]
        let buildableReference: XCScheme.BuildableReference
        // The hostInfos property is a sorted list of unique HostInfo.
        let hostInfos: [HostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool
        let hostResolution: HostResolution

        private init<HIs: Sequence, EPIs: Sequence, Platforms: Sequence>(
            pbxTarget: PBXTarget,
            platforms: Platforms,
            buildableReference: XCScheme.BuildableReference,
            hostInfos: HIs,
            extensionPointIdentifiers: EPIs,
            hostResolution: HostResolution = .unresolved
        ) where HIs.Element == XCSchemeInfo.HostInfo,
            EPIs.Element == ExtensionPointIdentifier,
            Platforms.Element == Platform
        {
            self.pbxTarget = pbxTarget
            self.platforms = Set(platforms).sorted()
            self.buildableReference = buildableReference
            self.hostInfos = Set(hostInfos).sorted()
            self.extensionPointIdentifiers = Set(extensionPointIdentifiers)
            disambiguateHost = self.hostInfos.count > 1
            self.hostResolution = hostResolution
        }
    }
}

extension XCSchemeInfo.TargetInfo {
    init<HIs: Sequence, EPIs: Sequence, Platforms: Sequence>(
        pbxTarget: PBXTarget,
        platforms: Platforms,
        referencedContainer: String,
        hostInfos: HIs,
        extensionPointIdentifiers: EPIs
    ) where HIs.Element == XCSchemeInfo.HostInfo,
        EPIs.Element == ExtensionPointIdentifier,
        Platforms.Element == Platform
    {
        self.init(
            pbxTarget: pbxTarget,
            platforms: platforms,
            buildableReference: .init(
                pbxTarget: pbxTarget,
                referencedContainer: referencedContainer
            ),
            hostInfos: hostInfos,
            extensionPointIdentifiers: extensionPointIdentifiers
        )
    }
}

extension XCSchemeInfo.TargetInfo {
    init<HIs: Sequence>(
        pbxTargetInfo: TargetResolver.PBXTargetInfo,
        hostInfos: HIs
    ) where HIs.Element == XCSchemeInfo.HostInfo {
        self.init(
            pbxTarget: pbxTargetInfo.pbxTarget,
            platforms: pbxTargetInfo.platforms,
            buildableReference: pbxTargetInfo.buildableReference,
            hostInfos: hostInfos,
            extensionPointIdentifiers: pbxTargetInfo.extensionPointIdentifiers
        )
    }
}

extension XCSchemeInfo.TargetInfo {
    /// Initializer used when resolving a selected host.
    init<TargetInfos: Sequence>(
        resolveHostFor original: XCSchemeInfo.TargetInfo,
        topLevelTargetInfos: TargetInfos
    ) where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        self.init(
            pbxTarget: original.pbxTarget,
            platforms: original.platforms,
            buildableReference: original.buildableReference,
            hostInfos: original.hostInfos,
            extensionPointIdentifiers: original.extensionPointIdentifiers,
            hostResolution: original.hostInfos.resolve(topLevelTargetInfos: topLevelTargetInfos)
        )
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
    func buildPreAction(buildMode _: BuildMode) throws -> XCScheme.ExecutionAction? {
        guard pbxTarget is PBXNativeTarget else {
            return nil
        }
        return .init(
            buildFor: buildableReference,
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
    var inStableOrder: [XCSchemeInfo.TargetInfo] {
        return sortedLocalizedStandard(\.pbxTarget.name)
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    func buildPreActions(buildMode: BuildMode) throws -> [XCScheme.ExecutionAction] {
        let targetInfos = inStableOrder

        guard let buildableReference =
                targetInfos.first?.buildableReference
        else {
            return []
        }

        let preActions = try targetInfos
            .compactMap { try $0.buildPreAction(buildMode: buildMode) }

        return [.initBazelBuildOutputGroupsFile(
            buildableReference: buildableReference
        )] + preActions
    }
}

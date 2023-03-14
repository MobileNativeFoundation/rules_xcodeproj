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
        let pbxTarget: PBXNativeTarget
        // The platforms property is a sorted list of unique platforms.
        let platforms: [Platform]
        let buildableReference: XCScheme.BuildableReference
        // The hostInfos property is a sorted list of unique HostInfo.
        let hostInfos: [HostInfo]
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let disambiguateHost: Bool
        let hostResolution: HostResolution
        let additionalBuildableReferences: [XCScheme.BuildableReference]

        private init<HIs: Sequence, EPIs: Sequence, Platforms: Sequence>(
            pbxTarget: PBXNativeTarget,
            platforms: Platforms,
            buildableReference: XCScheme.BuildableReference,
            hostInfos: HIs,
            extensionPointIdentifiers: EPIs,
            hostResolution: HostResolution = .unresolved,
            additionalBuildableReferences: [XCScheme.BuildableReference] = []
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
            self.additionalBuildableReferences = additionalBuildableReferences
        }
    }
}

extension XCSchemeInfo.TargetInfo {
    init<HIs: Sequence, EPIs: Sequence, Platforms: Sequence>(
        pbxTarget: PBXNativeTarget,
        platforms: Platforms,
        referencedContainer: String,
        hostInfos: HIs,
        extensionPointIdentifiers: EPIs,
        additionalBuildableReferences: [XCScheme.BuildableReference] = []
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
            extensionPointIdentifiers: extensionPointIdentifiers,
            additionalBuildableReferences: additionalBuildableReferences
        )
    }
}

extension XCSchemeInfo.TargetInfo {
    init<HIs: Sequence>(
        pbxTargetInfo: TargetResolver.PBXTargetInfo,
        hostInfos: HIs,
        additionalBuildableReferences: [XCScheme.BuildableReference] = []
    ) where HIs.Element == XCSchemeInfo.HostInfo {
        self.init(
            pbxTarget: pbxTargetInfo.pbxTarget,
            platforms: pbxTargetInfo.platforms,
            buildableReference: pbxTargetInfo.buildableReference,
            hostInfos: hostInfos,
            extensionPointIdentifiers: pbxTargetInfo.extensionPointIdentifiers,
            additionalBuildableReferences: additionalBuildableReferences
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
            hostResolution: original.hostInfos
                .resolve(topLevelTargetInfos: topLevelTargetInfos),
            additionalBuildableReferences: original
                .additionalBuildableReferences
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
    /// Returns the target buildable reference along with any additionally
    /// required buildable references (e.g. the selected host, or SwiftUI
    /// Preview dependencies).
    var buildableReferences: [XCScheme.BuildableReference] {
        var results = [buildableReference]
        // Only include the selected host, not all of the hosts.
        if case let .selected(selectedHostInfo) = hostResolution {
            results.append(selectedHostInfo.buildableReference)
        }
        results.append(contentsOf: additionalBuildableReferences)
        return results
    }
}

// MARK: `bazelBuildPreActions`

extension XCSchemeInfo.TargetInfo {
    func buildPreAction() throws -> XCScheme.ExecutionAction {
        return try .init(
            buildFor: buildableReference,
            name: pbxTarget.name,
            hostIndex: selectedHostInfo?.index
        )
    }
}

// MARK: `isWidgetKitExtension`

extension XCSchemeInfo.TargetInfo {
    var isMessageAppExtension: Bool {
        return extensionPointIdentifiers.contains(.messagePayloadProvider)
    }

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

// MARK: `macroExpansion`

extension XCSchemeInfo.TargetInfo {
    var macroExpansion: XCScheme.BuildableReference? {
        get throws {
            if let hostBuildableReference = try selectedHostInfo?.buildableReference,
                !productType.isWatchApplication
            {
                return hostBuildableReference
            } else if pbxTarget.isTestable {
                return buildableReference
            }
            return nil
        }
    }
}

// MARK: Sequence Extensions

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    var inStableOrder: [XCSchemeInfo.TargetInfo] {
        return sortedLocalizedStandard(\.pbxTarget.name)
    }
}

extension Sequence where Element == XCSchemeInfo.TargetInfo {
    func buildPreActions() throws -> [XCScheme.ExecutionAction] {
        let targetInfos = inStableOrder

        guard let buildableReference =
                targetInfos.first?.buildableReference
        else {
            return []
        }

        let preActions = try targetInfos.compactMap { try $0.buildPreAction() }

        return [
            .initBazelBuildOutputGroupsFile(
                buildableReference: buildableReference
            ),
        ] + preActions
    }
}

import OrderedCollections
import XcodeProj

struct TargetResolver: Equatable {
    let referencedContainer: String
    let targets: [TargetID: Target]
    let targetHosts: [TargetID: [TargetID]]
    let extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier]
    let consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key]
    let pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget]
    let pbxTargetInfos: [ConsolidatedTarget.Key: PBXTargetInfo]

    init(
        referencedContainer: String,
        targets: [TargetID: Target],
        targetHosts: [TargetID: [TargetID]],
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key],
        pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget]
    ) throws {
        self.referencedContainer = referencedContainer
        self.targets = targets
        self.targetHosts = targetHosts
        self.extensionPointIdentifiers = extensionPointIdentifiers
        self.consolidatedTargetKeys = consolidatedTargetKeys
        self.pbxTargets = pbxTargets

        let hostKeys: [
            ConsolidatedTarget.Key: Set<ConsolidatedTarget.Key>
        ] = try Dictionary(
            targetHosts.map { targetID, hostIDs in
                let key = try consolidatedTargetKeys.value(for: targetID)
                let hostKeys = try hostIDs
                    .map { try consolidatedTargetKeys.value(for: $0) }
                    .reduce(into: Set()) { keys, key in keys.insert(key) }
                return (key, hostKeys)
            },
            uniquingKeysWith: { $0.union($1) }
        )

        let additionalKeys: [
            ConsolidatedTarget.Key: Set<ConsolidatedTarget.Key>
        ] = try Dictionary(
            targets.map { targetID, target in
                let key = try consolidatedTargetKeys.value(for: targetID)
                let additionalKeys = try target.additionalSchemeTargets
                    .map { try consolidatedTargetKeys.value(for: $0) }
                    .reduce(into: Set()) { keys, key in keys.insert(key) }
                return (key, additionalKeys)
            },
            uniquingKeysWith: { $0.union($1) }
        )

        let platformsByKey = try consolidatedTargetKeys.collectPlatformsByKey(targets: targets)
        var keyedExtensionPointIdentifiers: [
            ConsolidatedTarget.Key: Set<ExtensionPointIdentifier>
        ] = [:]
        for (id, extensionPointIdentifier) in extensionPointIdentifiers {
            let key = try consolidatedTargetKeys.value(for: id, message: """
`key` for extension point identifier target id "\(id)" not found in \
`consolidatedTargetKeys`.
""")
            keyedExtensionPointIdentifiers[key, default: []]
                .insert(extensionPointIdentifier)
        }

        let pbxTargetInfoList: [PBXTargetInfo] = try pbxTargets.map { key, pbxTarget in
            try PBXTargetInfo(
                key: key,
                pbxTarget: pbxTarget,
                platforms: platformsByKey.value(for: key),
                extensionPointIdentifiers: keyedExtensionPointIdentifiers[key, default: []],
                buildableReference: .init(
                    pbxTarget: pbxTarget,
                    referencedContainer: referencedContainer
                ),
                hostKeys: hostKeys[key, default: []],
                additionalKeys: additionalKeys[key, default: []]
            )
        }
        pbxTargetInfos = .init(uniqueKeysWithValues: pbxTargetInfoList.map { ($0.key, $0) })
    }
}

extension TargetResolver {
    static let pbxTargetInfoCtx = "finding a `PBXTargetInfo`"

    func pbxTargetInfo(for targetID: TargetID) throws -> PBXTargetInfo {
        let key = try consolidatedTargetKeys.value(for: targetID, context: Self.pbxTargetInfoCtx)
        return try pbxTargetInfos.value(for: key, context: Self.pbxTargetInfoCtx)
    }
}

// MARK: XCScheme.TargetInfo Helpers

extension TargetResolver {
    private func targetInfo(pbxTargetInfo: PBXTargetInfo) throws -> XCSchemeInfo.TargetInfo {
        return try .init(
            pbxTargetInfo: pbxTargetInfo,
            hostInfos: pbxTargetInfo.hostKeys
                .enumerated()
                .map { hostIndex, hostKey in
                    try .init(
                        pbxTargetInfo: pbxTargetInfos.value(for: hostKey),
                        index: hostIndex
                    )
                },
            additionalBuildableReferences: pbxTargetInfo.additionalKeys
                .map { try pbxTargetInfos.value(for: $0).buildableReference }
        )
    }

    func targetInfo(targetID: TargetID) throws -> XCSchemeInfo.TargetInfo {
        let pbxTargetInfo = try pbxTargetInfo(for: targetID)
        return try targetInfo(pbxTargetInfo: pbxTargetInfo)
    }

    /// Creates `XCSchemeInfo.TargetInfo` values for all eligible targets.
    var targetInfos: Set<XCSchemeInfo.TargetInfo> {
        get throws {
            let targetInfoList = try pbxTargetInfos.values.map { try targetInfo(pbxTargetInfo: $0) }
            return .init(targetInfoList)
        }
    }
}

// MARK: `PBXTargetInfo`

extension TargetResolver {
    struct PBXTargetInfo: Equatable, Hashable {
        let key: ConsolidatedTarget.Key
        let pbxTarget: PBXNativeTarget
        let platforms: Set<Platform>
        let extensionPointIdentifiers: Set<ExtensionPointIdentifier>
        let buildableReference: XCScheme.BuildableReference
        let hostKeys: Set<ConsolidatedTarget.Key>
        let additionalKeys: Set<ConsolidatedTarget.Key>
    }
}

import OrderedCollections
import XcodeProj

struct TargetResolver: Equatable {
    let referencedContainer: String
    let targets: [TargetID: Target]
    let targetHosts: [TargetID: [TargetID]]
    let extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier]
    let consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key]
    let pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
    let keyedHostPBXTargets: [ConsolidatedTarget.Key: OrderedSet<PBXTarget>]
    let keyedExtensionPointIdentifiers: [ConsolidatedTarget.Key: Set<ExtensionPointIdentifier>]

    init(
        referencedContainer: String,
        targets: [TargetID: Target],
        targetHosts: [TargetID: [TargetID]],
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        consolidatedTargetKeys: [TargetID: ConsolidatedTarget.Key],
        pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
    ) throws {
        self.referencedContainer = referencedContainer
        self.targets = targets
        self.targetHosts = targetHosts
        self.extensionPointIdentifiers = extensionPointIdentifiers
        self.consolidatedTargetKeys = consolidatedTargetKeys
        self.pbxTargets = pbxTargets

        var keyedHostPBXTargets: [
            ConsolidatedTarget.Key: OrderedSet<PBXTarget>
        ] = [:]
        for (id, hostIDs) in targetHosts {
            guard let key = consolidatedTargetKeys[id] else {
                throw PreconditionError(message: """
`key` for hosted target target id "\(id)" not found in `consolidatedTargetKeys`.
""")
            }

            for hostID in hostIDs {
                guard let hostKey = consolidatedTargetKeys[hostID] else {
                    throw PreconditionError(message: """
`key` "\(hostID)" for host target target id "\(id)" not found in `consolidatedTargetKeys`.
""")
                }
                guard let hostPBXTarget = pbxTargets[hostKey] else {
                    throw PreconditionError(message: """
Host target, "\(hostKey)", for "\(key)" not found in `pbxTargets`.
""")
                }

                keyedHostPBXTargets[key, default: []].append(hostPBXTarget)
            }
        }
        self.keyedHostPBXTargets = keyedHostPBXTargets

        var keyedExtensionPointIdentifiers: [
            ConsolidatedTarget.Key: Set<ExtensionPointIdentifier>
        ] = [:]
        for (id, extensionPointIdentifier) in extensionPointIdentifiers {
            guard let key = consolidatedTargetKeys[id] else {
                throw PreconditionError(message: """
`key` for extension point identifier target id "\(id)" not found in \
`consolidatedTargetKeys`.
""")
            }
            keyedExtensionPointIdentifiers[key, default: []]
                .insert(extensionPointIdentifier)
        }
        self.keyedExtensionPointIdentifiers = keyedExtensionPointIdentifiers
    }
}

extension TargetResolver {
    func pbxTargetAndKey(
        for targetID: TargetID
    ) throws -> (key: ConsolidatedTarget.Key, pbxTarget: PBXTarget) {
        let context = "finding a `PBXTarget` and `ConsolidatedTarget.Key`"
        let key = try consolidatedTargetKeys.value(for: targetID, context: context)
        return (key: key, pbxTarget: try pbxTargets.value(for: key, context: context))
    }
}

// MARK: XCScheme.TargetInfo Helpers

extension TargetResolver {
    private func targetInfo(
        key: ConsolidatedTarget.Key,
        pbxTarget: PBXTarget
    ) -> XCSchemeInfo.TargetInfo {
        return .init(
            pbxTarget: pbxTarget,
            referencedContainer: referencedContainer,
            hostInfos: keyedHostPBXTargets[key, default: []].elements.enumerated()
                .map { hostIndex, hostPBXTarget in
                    .init(
                        pbxTarget: hostPBXTarget,
                        referencedContainer: referencedContainer,
                        index: hostIndex
                    )
                },
            extensionPointIdentifiers: keyedExtensionPointIdentifiers[key, default: []]
        )
    }

    func targetInfo(targetID: TargetID) throws -> XCSchemeInfo.TargetInfo {
        let pbxTargetAndKey = try pbxTargetAndKey(for: targetID)
        return targetInfo(key: pbxTargetAndKey.key, pbxTarget: pbxTargetAndKey.pbxTarget)
    }

    /// Creates `XCSchemeInfo.TargetInfo` values for all eligible targets.
    var targetInfos: [XCSchemeInfo.TargetInfo] {
        return pbxTargets.map { key, pbxTarget in
            return targetInfo(key: key, pbxTarget: pbxTarget)
        }
    }
}

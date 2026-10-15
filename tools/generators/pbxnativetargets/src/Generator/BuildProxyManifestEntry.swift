import Foundation
import PBXProj
import ToolCommon

/// One deterministic build mapping consumed by the build-service proxy.
///
/// The complete manifest is assembled from generator-shard JSON Lines files by
/// `build_proxy_manifest_generator`. Keeping the PBX target GUID calculation in
/// this generator ensures that the manifest and `project.pbxproj` use the same
/// identifier source of truth.
struct BuildProxyManifestEntry: Codable, Equatable {
    struct Product: Codable, Equatable {
        let basename: String
        let name: String
        let path: String?
        let type: String
    }

    struct Variant: Codable, Equatable {
        let arch: String
        let minimumOSVersion: String
        let platform: String
    }

    let action: String
    let bazelLabel: String
    let configuration: String
    let outputGroup: String
    let product: Product
    let targetID: String
    let variant: Variant
    let xcodeTargetGUID: String
}

extension BuildProxyManifestEntry {
    static func calculate(
        consolidationMapEntries: [ConsolidationMapEntry],
        targetArguments: [TargetID: TargetArguments],
        topLevelTargetAttributes: [TargetID: TopLevelTargetAttributes]
    ) throws -> [Self] {
        var entries: [Self] = []

        for consolidationMapEntry in consolidationMapEntries {
            let xcodeTargetGUID = Identifiers.Targets.id(
                subIdentifier: consolidationMapEntry.subIdentifier,
                name: consolidationMapEntry.name
            ).withoutComment

            for targetID in consolidationMapEntry.key.sortedIds {
                guard let arguments = targetArguments[targetID] else {
                    throw PreconditionError(message: """
Missing target arguments for build proxy manifest target ID \(targetID).
""")
                }

                let topLevelAttributes = topLevelTargetAttributes[targetID]
                let product = Product(
                    basename: arguments.productBasename,
                    name: arguments.productName,
                    path: topLevelAttributes?.outputsProductPath,
                    type: arguments.productType.identifier
                )
                let variant = Variant(
                    arch: arguments.arch,
                    minimumOSVersion: arguments.osVersion.description,
                    platform: arguments.platform.rawValue
                )

                for configuration in Set(arguments.xcodeConfigurations).sorted() {
                    entries.append(
                        Self(
                            action: "build",
                            bazelLabel: consolidationMapEntry.label.description,
                            configuration: configuration,
                            outputGroup: "bp \(targetID.rawValue)",
                            product: product,
                            targetID: targetID.rawValue,
                            variant: variant,
                            xcodeTargetGUID: xcodeTargetGUID
                        )
                    )
                }
            }
        }

        return entries.sorted(by: stableLessThan)
    }

    static func encodeJSONLines(_ entries: [Self]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        var data = Data()
        for entry in entries.sorted(by: stableLessThan) {
            try data.append(encoder.encode(entry))
            data.append(0x0A)
        }
        return data
    }

    private static func stableLessThan(_ lhs: Self, _ rhs: Self) -> Bool {
        let lhsValues = [
            lhs.xcodeTargetGUID,
            lhs.configuration,
            lhs.action,
            lhs.variant.platform,
            lhs.variant.arch,
            lhs.variant.minimumOSVersion,
            lhs.targetID,
        ]
        let rhsValues = [
            rhs.xcodeTargetGUID,
            rhs.configuration,
            rhs.action,
            rhs.variant.platform,
            rhs.variant.arch,
            rhs.variant.minimumOSVersion,
            rhs.targetID,
        ]
        return lhsValues.lexicographicallyPrecedes(rhsValues)
    }
}

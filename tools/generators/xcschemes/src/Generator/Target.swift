import PBXProj
import XCScheme

/// An Xcode target, from the point of view of a scheme.
struct Target: Equatable {
    typealias Key = ConsolidationMapEntry.Key

    let key: Key
    let productType: PBXProductType
    let buildableReference: BuildableReference
}

import PBXProj
import XCScheme

struct Target: Equatable {
    typealias Key = ConsolidationMapEntry.Key

    let key: Key
    let productType: PBXProductType
    let buildableReference: BuildableReference
}

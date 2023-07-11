import GeneratorCommon
import PBXProj

struct Target: Equatable {
    let id: TargetID
    let label: BazelLabel
    let xcodeConfigurations: [String]
    let productType: PBXProductType
    let productPath: String
    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String
    let dependencies: [TargetID]
}

import PBXProj
import ToolCommon

struct Target: Equatable {
    let id: TargetID
    let label: BazelLabel
    let xcodeConfigurations: [String]
    let productType: PBXProductType
    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String

    /// e.g. "generator" or "App.app"
    let originalProductBasename: String

    /// e.g. "generator_codesigned" or "App.app"
    let productBasename: String

    let moduleName: String
    let uiTestHost: TargetID?
    let watchKitExtension: TargetID?
    let dependencies: [TargetID]
}

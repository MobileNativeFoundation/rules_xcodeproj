import GeneratorCommon
import PBXProj

struct Target: Equatable {
    let id: TargetID
    let label: BazelLabel
    let xcodeConfigurations: [String]
    let productType: PBXProductType
    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String

    /// e.g. "bazel-out/generator" or "bazel-out/App.app"
    let productPath: String

    /// e.g. "generator_codesigned" or "App.app"
    let productBasename: String

    let moduleName: String
    let uiTestHost: TargetID?
    let watchKitExtension: TargetID?
    let dependencies: [TargetID]
}

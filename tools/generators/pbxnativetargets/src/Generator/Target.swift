import Foundation
import GeneratorCommon
import OrderedCollections
import PBXProj

enum Target {
    struct ConsolidatedInputs: Equatable {
        var srcs: [BazelPath]
        var nonArcSrcs: [BazelPath]
        var hdrs: [BazelPath]
    }

    struct Host: Equatable {
        let pbxProjEscapedID: String
        let pbxProjEscapedLabel: String
    }

    struct PlatformVariant: Equatable {
        let xcodeConfigurations: [String]
        let id: TargetID
        let bundleID: String?
        let compileTargetIDs: String?
        let packageBinDir: String
        let outputsProductPath: String?
        let productName: String
        let productBasename: String
        let moduleName: String
        let platform: Platform
        let osVersion: SemanticVersion
        let arch: String
        let executableName: String?
        let conditionalFiles: Set<BazelPath>
        let compilerBuildSettingsFile: URL?
        let linkParams: String?
        let hosts: [Host]
        let unitTestHost: UnitTestHost?
        let dSYMPathsBuildSetting: String?
    }

    struct UnitTestHost: Equatable {
        let packageBinDir: String
        let productPath: String
        let executableName: String
    }
}

import Foundation
import OrderedCollections
import PBXProj
import ToolCommon

enum Target {
    struct ConsolidatedInputs: Equatable {
        var srcs: [BazelPath]
        var nonArcSrcs: [BazelPath]
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
        let buildSettingsFromFile: [PlatformVariantBuildSetting]
        let linkParams: String?
        let unitTestHost: UnitTestHost?
        let dSYMPathsBuildSetting: String?
    }

    struct UnitTestHost: Equatable {
        let packageBinDir: String
        let productPath: String
        let executableName: String
    }
}

extension Dictionary<TargetID, Target.UnitTestHost> {
    static func parse(from url: URL) async throws -> Self {
        var rawArgs = ArraySlice(try await url.allLines.collect())

        guard rawArgs.count.isMultiple(of: 4) else {
            throw PreconditionError(message: """
"\(url.path)": Number of lines must be a multiple of 4.
""")
        }

        let targetCount = rawArgs.count / 4

        var keysWithValues: [(TargetID, Target.UnitTestHost)] = []
        for _ in (0..<targetCount) {
            let id =
                try rawArgs.consumeArg("target-id", as: TargetID.self, in: url)
            let packageBinDir =
                try rawArgs.consumeArg("package-bin-dir", in: url)
            let productPath = try rawArgs.consumeArg("product-path", in: url)
            let executableName =
                try rawArgs.consumeArg("executable-name", in: url)

            keysWithValues.append(
                (
                    id,
                    .init(
                        packageBinDir: packageBinDir,
                        productPath: productPath,
                        executableName: executableName
                    )
                )
            )
        }

        return Dictionary(uniqueKeysWithValues: keysWithValues)
    }
}

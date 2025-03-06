import ArgumentParser
import Foundation
import PBXProj
import ToolCommon

struct TargetArguments: Equatable {
    let xcodeConfigurations: [String]
    let productType: PBXProductType
    let packageBinDir: String

    /// e.g. "generator" or "App"
    let productName: String

    /// e.g. "generator_codesigned" or "App.app"
    let productBasename: String

    let moduleName: String

    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String

    let buildSettingsFromFile: [PlatformVariantBuildSetting]
    let hasCParams: Bool
    let hasCxxParams: Bool

    // FIXME: Extract to `Inputs` type
    let srcs: [BazelPath]
    let nonArcSrcs: [BazelPath]

    let dSYMPathsBuildSetting: String
    let librarySearchPaths: [BazelPath]
    let librariesToLinkPaths: [BazelPath]
}

extension Dictionary<TargetID, TargetArguments> {
    static func parse(from url: URL) async throws -> Self {
        var rawArgs = ArraySlice(try await url.allLines.collect())

        let targetCount =
            try rawArgs.consumeArg("target-count", as: Int.self, in: url)

        var keysWithValues: [(TargetID, TargetArguments)] = []
        for _ in (0..<targetCount) {
            let id =
                try rawArgs.consumeArg("target-id", as: TargetID.self, in: url)
            let productType = try rawArgs.consumeArg(
                "product-type",
                as: PBXProductType.self,
                in: url
            )
            let packageBinDir =
                try rawArgs.consumeArg("package-bin-dir", in: url)
            let productName = try rawArgs.consumeArg("product-name", in: url)
            let productBasename =
                try rawArgs.consumeArg("product-basename", in: url)
            let moduleName = try rawArgs.consumeArg("module-name", in: url)
            let platform =
                try rawArgs.consumeArg("platform", as: Platform.self, in: url)
            let osVersion = try rawArgs.consumeArg(
                "os-version",
                as: SemanticVersion.self,
                in: url
            )
            let arch = try rawArgs.consumeArg("arch", in: url)
            let dSYMPathsBuildSetting =
                try rawArgs.consumeArg("dsym-paths-build-setting", in: url)
            let buildSettingsFile = try rawArgs.consumeArg(
                "build-settings-file",
                as: URL?.self,
                in: url,
                transform: { path in
                    guard !path.isEmpty else {
                        return nil
                    }
                    return URL(fileURLWithPath: path, isDirectory: false)
                }
            )
            let hasCParams =
                try rawArgs.consumeArg("has-c-params", as: Bool.self, in: url)
            let hasCxxParams =
                try rawArgs.consumeArg("has-cxx-params", as: Bool.self, in: url)
            let srcs = try rawArgs.consumeArgs(
                "srcs",
                as: BazelPath.self,
                in: url
            )
            let nonArcSrcs = try rawArgs.consumeArgs(
                "non-arc-srcs",
                as: BazelPath.self,
                in: url
            )
            let xcodeConfigurations = try rawArgs.consumeArgs(
                "xcode-configurations",
                in: url
            )
            let librarySearchPaths = try rawArgs.consumeArgs(
                "library-search-paths",
                as: BazelPath.self,
                in: url
            )
            let librariesToLinkPaths = try rawArgs.consumeArgs(
                "libraries_to_link_paths",
                as: BazelPath.self,
                in: url
            )

            var buildSettings: [PlatformVariantBuildSetting] = []
            if let buildSettingsFile {
                // FIXME: Wrap in better precondition error that mentions url
                for try await line in buildSettingsFile.lines {
                    let components = line.split(separator: "\t", maxSplits: 1)
                    guard components.count == 2 else {
                        throw PreconditionError(message: """
"\(buildSettingsFile.path)": Invalid format, missing tab separator.
""")
                    }
                    buildSettings.append(
                        .init(
                            key: String(components[0]),
                            value: components[1].nullsToNewlines
                        )
                    )
                }
            }

            keysWithValues.append(
                (
                    id,
                    .init(
                        xcodeConfigurations: xcodeConfigurations,
                        productType: productType,
                        packageBinDir: packageBinDir,
                        productName: productName,
                        productBasename: productBasename,
                        moduleName: moduleName,
                        platform: platform,
                        osVersion: osVersion,
                        arch: arch,
                        buildSettingsFromFile: buildSettings,
                        hasCParams: hasCParams,
                        hasCxxParams: hasCxxParams,
                        srcs: srcs,
                        nonArcSrcs: nonArcSrcs,
                        dSYMPathsBuildSetting: dSYMPathsBuildSetting,
                        librarySearchPaths: librarySearchPaths,
                        librariesToLinkPaths: librariesToLinkPaths
                    )
                )
            )
        }

        return Dictionary(uniqueKeysWithValues: keysWithValues)
    }
}

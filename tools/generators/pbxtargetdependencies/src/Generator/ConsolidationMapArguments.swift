import ArgumentParser
import Foundation
import ToolCommon
import PBXProj

struct ConsolidationMapArguments: Equatable {
    let outputPath: URL
    let targets: [Target]
}

extension Array<ConsolidationMapArguments> {
    static func parse(
        from url: URL,
        testHosts: [TargetID: TargetID],
        watchKitExtensions: [TargetID: TargetID]
    ) async throws -> Self {
        var rawArgs = ArraySlice(try await url.allLines.collect())

        let outputPaths = try rawArgs.consumeArgsUntilNull(
            "output-paths",
            as: URL.self,
            in: url,
            transform: { URL(fileURLWithPath: $0, isDirectory: false) }
        )

        var consolidationMapArguments: [ConsolidationMapArguments] = []
        for outputPath in outputPaths {
            let labelCount =
                try rawArgs.consumeArg("label-count", as: Int.self, in: url)

            var targets: [Target] = []
            for _ in (0..<labelCount) {
                let label = try rawArgs.consumeArg(
                    "label",
                    as: BazelLabel.self,
                    in: url
                )
                let targetCount = try rawArgs.consumeArg(
                    "target-count",
                    as: Int.self,
                    in: url
                )

                for _ in (0..<targetCount) {
                    let id = try rawArgs.consumeArg(
                        "target-id",
                        as: TargetID.self,
                        in: url
                    )
                    let productType = try rawArgs.consumeArg(
                        "product-type",
                        as: PBXProductType.self,
                        in: url
                    )
                    let platform = try rawArgs.consumeArg(
                        "platform",
                        as: Platform.self,
                        in: url
                    )
                    let osVersion = try rawArgs.consumeArg(
                        "os-version",
                        as: SemanticVersion.self,
                        in: url
                    )
                    let arch = try rawArgs.consumeArg("arch", in: url)
                    let moduleName =
                        try rawArgs.consumeArg("module-name", in: url)
                    let originalProductBasename = try rawArgs.consumeArg(
                        "original-product-basename",
                        in: url
                    )
                    let productBasename =
                        try rawArgs.consumeArg("product-basename", in: url)
                    let dependencies = try rawArgs.consumeArgsUntilNull(
                        "dependencies",
                        as: TargetID.self,
                        in: url
                    )
                    let xcodeConfigurations = try rawArgs.consumeArgsUntilNull(
                        "xcode-configurations",
                        in: url
                    )

                    let uiTestHost: TargetID?
                    if productType == .uiTestBundle {
                        uiTestHost = try testHosts
                            .value(for: id, context: "UI test")
                    } else {
                        uiTestHost = nil
                    }

                    let watchKitExtension: TargetID?
                    if productType == .watch2App {
                        watchKitExtension = try watchKitExtensions
                            .value(for: id, context: "WatchKit extension")
                    } else {
                        watchKitExtension = nil
                    }

                    targets.append(
                        .init(
                            id: id,
                            label: label,
                            xcodeConfigurations: xcodeConfigurations,
                            productType: productType,
                            platform: platform,
                            osVersion: osVersion,
                            arch: arch,
                            originalProductBasename: originalProductBasename,
                            productBasename: productBasename,
                            moduleName: moduleName,
                            uiTestHost: uiTestHost,
                            watchKitExtension: watchKitExtension,
                            dependencies: dependencies
                        )
                    )
                }
            }

            consolidationMapArguments.append(
                .init(
                    outputPath: outputPath,
                    targets: targets
                )
            )
        }

        return consolidationMapArguments
    }
}

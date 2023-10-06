import ArgumentParser
import Foundation
import GeneratorCommon
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

        let outputPaths = try rawArgs.consumeArgs(
            URL.self,
            in: url,
            transform: { URL(fileURLWithPath: $0, isDirectory: false) },
            terminator: "--"
        )

        var consolidationMapArguments: [ConsolidationMapArguments] = []
        for outputPath in outputPaths {
            let labelCount = try rawArgs.consumeArg(Int.self, in: url)

            var targetArguments: [Target] = []
            for _ in (0..<labelCount) {
                let label = try rawArgs.consumeArg(BazelLabel.self, in: url)
                let targetCount = try rawArgs.consumeArg(Int.self, in: url)

                for _ in (0..<targetCount) {
                    let id = try rawArgs.consumeArg(TargetID.self, in: url)
                    let productType =
                        try rawArgs.consumeArg(PBXProductType.self, in: url)
                    let platform =
                        try rawArgs.consumeArg(Platform.self, in: url)
                    let osVersion =
                        try rawArgs.consumeArg(SemanticVersion.self, in: url)
                    let arch = try rawArgs.consumeArg(String.self, in: url)
                    let moduleName =
                        try rawArgs.consumeArg(String.self, in: url)
                    let productPath =
                        try rawArgs.consumeArg(String.self, in: url)
                    let productBasename =
                        try rawArgs.consumeArg(String.self, in: url)
                    let dependencies =
                        try rawArgs.consumeArgs(TargetID.self, in: url)
                    let xcodeConfigurations = try rawArgs
                        .consumeArgs(String.self, in: url)

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

                    targetArguments.append(
                        .init(
                            id: id,
                            label: label,
                            xcodeConfigurations: xcodeConfigurations,
                            productType: productType,
                            platform: platform,
                            osVersion: osVersion,
                            arch: arch,
                            productPath: productPath,
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
                    targets: targetArguments
                )
            )
        }

        return consolidationMapArguments
    }
}

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
            transform: { URL(fileURLWithPath: $0, isDirectory: false) },
            terminator: "--"
        )

        var consolidationMapArguments: [ConsolidationMapArguments] = []
        for outputPath in outputPaths {
            let labelCount = try rawArgs.consumeArg(Int.self)

            var targetArguments: [Target] = []
            for _ in (0..<labelCount) {
                let label = try rawArgs.consumeArg(BazelLabel.self)
                let targetCount = try rawArgs.consumeArg(Int.self)

                for _ in (0..<targetCount) {
                    let id = try rawArgs.consumeArg(TargetID.self)
                    let productType =
                        try rawArgs.consumeArg(PBXProductType.self)
                    let platform =
                        try rawArgs.consumeArg(Platform.self)
                    let osVersion = try rawArgs.consumeArg(SemanticVersion.self)
                    let arch = try rawArgs.consumeArg(String.self)
                    let moduleName = try rawArgs.consumeArg(String.self)
                    let productPath = try rawArgs.consumeArg(String.self)
                    let productBasename = try rawArgs.consumeArg(String.self)
                    let dependencies = try rawArgs.consumeArgs(TargetID.self)
                    let xcodeConfigurations = try rawArgs
                        .consumeArgs(String.self)

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

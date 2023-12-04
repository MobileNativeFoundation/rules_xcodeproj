import ArgumentParser
import Foundation
import PBXProj
import ToolCommon
import XCScheme

extension Generator {
    struct ReadTargetArgsAndEnvFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable =
                ReadTargetArgsAndEnvFile.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads the file at `url`, returning mappings of `TargetID` to
        /// `[CommandLineArgument]` and `[EnvironmentVariable]`.
        func callAsFunction(
            _ url: URL
        ) async throws -> (
            commandLineArguments: [TargetID: [CommandLineArgument]],
            environmentVariables: [TargetID: [EnvironmentVariable]]
        ) {
            return try await callable(url)
        }
    }
}

// MARK: - ReadTargetArgsAndEnvFile.Callable

extension Generator.ReadTargetArgsAndEnvFile {
    typealias Callable = (
        _ url: URL
    ) async throws -> (
        commandLineArguments: [TargetID: [CommandLineArgument]],
        environmentVariables: [TargetID: [EnvironmentVariable]]
    )

    static func defaultCallable(
        _ url: URL
    ) async throws -> (
        commandLineArguments: [TargetID: [CommandLineArgument]],
        environmentVariables: [TargetID: [EnvironmentVariable]]
    ) {
        var rawArgsAndEnv = ArraySlice(try await url.allLines.collect())

        let argsTargetCount = try rawArgsAndEnv.consumeArg(
            "args-target-count",
            as: Int.self,
            in: url
        )

        var argsKeysWithValues: [(TargetID, [CommandLineArgument])] = []
        for _ in (0..<argsTargetCount) {
            let id = try rawArgsAndEnv.consumeArg(
                "arg-target-id",
                as: TargetID.self,
                in: url
            )
            let argsCount = try rawArgsAndEnv.consumeArg(
                "args-count",
                as: Int.self,
                in: url
            )

            var args: [CommandLineArgument] = []
            for _ in (0..<argsCount) {
                args.append(
                    .init(
                        value: try rawArgsAndEnv.consumeArg("arg", in: url)
                    )
                )
            }

            argsKeysWithValues.append((id, args))
        }

        let envTargetCount = try rawArgsAndEnv.consumeArg(
            "env-target-count",
            as: Int.self,
            in: url
        )

        var envKeysWithValues: [(TargetID, [EnvironmentVariable])] = []
        for _ in (0..<envTargetCount) {
            let id = try rawArgsAndEnv.consumeArg(
                "env-target-id",
                as: TargetID.self,
                in: url
            )
            let envCount =
                try rawArgsAndEnv.consumeArg("env-count", as: Int.self, in: url)

            var env: [EnvironmentVariable] = []
            for _ in (0..<envCount) {
                let key =
                    try rawArgsAndEnv.consumeArg("env-variable-key", in: url)
                let value =
                    try rawArgsAndEnv.consumeArg("env-variable-value", in: url)
                env.append(.init(key: key, value: value))
            }

            envKeysWithValues.append((id, env))
        }

        return (
            Dictionary(uniqueKeysWithValues: argsKeysWithValues),
            Dictionary(uniqueKeysWithValues: envKeysWithValues)
        )
    }
}

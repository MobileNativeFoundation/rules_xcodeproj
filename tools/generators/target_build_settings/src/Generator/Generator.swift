import ArgumentParser
import Foundation
import OrderedCollections
import PBXProj
import ToolCommon

/// A type that generates and writes to disk a file containing certain build
/// settings for a target, to be consumed by `pbxnativetargets`. It also
/// generates and writes to disk a file containing information about Swift
/// debug settings, to be consumed by this generator on other targets and
/// finally by `swift_debug_settings`.
///
/// The `Generator` type is stateless. It can be used to generate files for
/// multiple targets. The `generate()` method is passed all the inputs needed to
/// generate the files.
struct Generator {
    static let argsSeparator = "---"

    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the build settings and Swift debug settings and writes them
    /// to disk.
    func generate(rawArguments: ArraySlice<String>) async throws {
        var rawArguments = rawArguments

        let buildSettingsOutputPath = try rawArguments
            .consumeArg("build-settings-output-path", as: URL?.self)
        let swiftDebugSettingsOutputPath = try rawArguments
            .consumeArg("swift-debug-settings-output-path", as: URL?.self)

        let includeSelfSwiftDebugSettings: Bool
        let transitiveSwiftDebugSettingPaths: [URL]
        if swiftDebugSettingsOutputPath != nil {
            includeSelfSwiftDebugSettings = try rawArguments.consumeArg(
                "include-self-swift-debug-settings",
                as: Bool.self
            )
            // This doesn't use `consumeArgsUntilNull` because these arguments
            // are normally passed on the command-line, and Bazel can't handle
            // passing \0 on the command-line
            transitiveSwiftDebugSettingPaths = try rawArguments.consumeArgs(
                "transitive-swift-debug-setting-paths",
                as: URL.self
            )
        } else {
            includeSelfSwiftDebugSettings = false
            transitiveSwiftDebugSettingPaths = []
        }

        let (buildSettings, clangArgs, frameworkIncludes, swiftIncludes) =
            try await environment.processArgs(
                rawArguments: rawArguments,
                generateBuildSettings: buildSettingsOutputPath != nil,
                includeSelfSwiftDebugSettings: includeSelfSwiftDebugSettings,
                transitiveSwiftDebugSettingPaths:
                    transitiveSwiftDebugSettingPaths
            )

        let writeBuildSettingsTask = Task {
            guard let buildSettingsOutputPath else { return }

            try environment.writeBuildSettings(
                buildSettings,
                to: buildSettingsOutputPath
            )
        }

        let writeSwiftDebugSettingsTask = Task {
            guard let swiftDebugSettingsOutputPath else { return }

            try environment.writeTargetSwiftDebugSettings(
                clangArgs: clangArgs,
                frameworkIncludes: frameworkIncludes,
                swiftIncludes: swiftIncludes,
                to: swiftDebugSettingsOutputPath
            )
        }

        try await writeBuildSettingsTask.value
        try await writeSwiftDebugSettingsTask.value
    }
}

private extension ArraySlice<String> {
    mutating func consumeArg(
        _ name: String,
        as type: URL?.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> URL? {
        return try consumeArg(
            name,
            as: type,
            transform: { path in
                guard !path.isEmpty else {
                    return nil
                }
                return URL(fileURLWithPath: path, isDirectory: false)
            },
            file: file,
            line: line
        )
    }

    mutating func consumeArgs(
        _ name: String,
        as type: URL.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [URL] {
        return try consumeArgs(
            name,
            as: type,
            transform: { URL(fileURLWithPath: $0, isDirectory: false) },
            file: file,
            line: line
        )
    }
}

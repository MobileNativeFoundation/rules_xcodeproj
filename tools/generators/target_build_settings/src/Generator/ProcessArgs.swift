import Foundation
import OrderedCollections

extension Generator {
    struct ProcessArgs {
        private let processCArgs: ProcessCArgs
        private let processCxxArgs: ProcessCxxArgs
        private let processSwiftArgs: ProcessSwiftArgs

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            processCArgs: ProcessCArgs,
            processCxxArgs: ProcessCxxArgs,
            processSwiftArgs: ProcessSwiftArgs,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.processCArgs = processCArgs
            self.processCxxArgs = processCxxArgs
            self.processSwiftArgs = processSwiftArgs

            self.callable = callable
        }

        /// Processes all of the Swift, C, and/or C++ arguments.
        func callAsFunction(
            rawArguments: Array<String>.SubSequence,
            generateBuildSettings: Bool,
            includeSelfSwiftDebugSettings: Bool,
            transitiveSwiftDebugSettingPaths: [URL]
        ) async throws -> (
            buildSettings: [(key: String, value: String)],
            clangArgs: [String],
            frameworkIncludes: OrderedSet<String>,
            swiftIncludes: OrderedSet<String>
        ) {
            try await callable(
                /*rawArguments:*/ rawArguments,
                /*generateBuildSettings:*/ generateBuildSettings,
                /*includeSelfSwiftDebugSettings:*/
                    includeSelfSwiftDebugSettings,
                /*transitiveSwiftDebugSettingPaths:*/
                    transitiveSwiftDebugSettingPaths,
                /*processCArgs:*/ processCArgs,
                /*processCxxArgs:*/ processCxxArgs,
                /*processSwiftArgs:*/ processSwiftArgs
            )
        }
    }
}

// MARK: - ProcessArgs.Callable

extension Generator.ProcessArgs {
    typealias Callable = (
        _ rawArguments: Array<String>.SubSequence,
        _ generateBuildSettings: Bool,
        _ includeSelfSwiftDebugSettings: Bool,
        _ transitiveSwiftDebugSettingPaths: [URL],
        _ processCArgs: Generator.ProcessCArgs,
        _ processCxxArgs: Generator.ProcessCxxArgs,
        _ processSwiftArgs: Generator.ProcessSwiftArgs
    ) async throws -> (
        buildSettings: [(key: String, value: String)],
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>
    )

    static func defaultCallable(
        rawArguments: Array<String>.SubSequence,
        generateBuildSettings: Bool,
        includeSelfSwiftDebugSettings: Bool,
        transitiveSwiftDebugSettingPaths: [URL],
        processCArgs: Generator.ProcessCArgs,
        processCxxArgs: Generator.ProcessCxxArgs,
        processSwiftArgs: Generator.ProcessSwiftArgs
    ) async throws -> (
        buildSettings: [(key: String, value: String)],
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>
    ) {
        var rawArguments = rawArguments

        let deviceFamily = try rawArguments.consumeArg("device-family")
        let extensionSafe =
            try rawArguments.consumeArg("extension-safe", as: Bool.self)
        let generatesDsyms =
            try rawArguments.consumeArg("generates-dsyms", as: Bool.self)
        let infoPlist = try rawArguments.consumeArg("info-plist")
        let entitlements = try rawArguments.consumeArg("entitlements")
        let skipCodesigning =
            try rawArguments.consumeArg("skip-codesigning", as: Bool.self)
        let certificateName = try rawArguments.consumeArg("certificate-name")
        let provisioningProfileName =
            try rawArguments.consumeArg("provisioning-profile-name")
        let teamID = try rawArguments.consumeArg("team-id")
        let provisioningProfileIsXcodeManaged = try rawArguments.consumeArg(
            "provisioning-profile-is-xcode-managed",
            as: Bool.self
        )
        let previewsFrameworkPaths =
            try rawArguments.consumeArg("previews-framework-paths")
        let previewsIncludePath =
            try rawArguments.consumeArg("previews-include-path")

        let argsStream = argsStream(from: rawArguments)

        var buildSettings: [(key: String, value: String)] = []

        let (
            swiftHasDebugInfo,
            clangArgs,
            frameworkIncludes,
            swiftIncludes
        ) = try await processSwiftArgs(
            argsStream: argsStream,
            buildSettings: &buildSettings,
            includeSelfSwiftDebugSettings: includeSelfSwiftDebugSettings,
            previewsFrameworkPaths: previewsFrameworkPaths,
            previewsIncludePath: previewsIncludePath,
            transitiveSwiftDebugSettingPaths: transitiveSwiftDebugSettingPaths
        )

        guard generateBuildSettings else {
            return ([], clangArgs, frameworkIncludes, swiftIncludes)
        }

        let cHasDebugInfo = try await processCArgs(
            argsStream: argsStream,
            buildSettings: &buildSettings
        )

        let cxxHasDebugInfo = try await processCxxArgs(
            argsStream: argsStream,
            buildSettings: &buildSettings
        )

        if generatesDsyms || swiftHasDebugInfo || cHasDebugInfo ||
            cxxHasDebugInfo
        {
            // Set to dwarf, because Bazel will generate the dSYMs. We don't set
            // "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set that at the
            // project level
        } else {
            buildSettings.append(
                ("DEBUG_INFORMATION_FORMAT", #""""#)
            )
        }

        if !deviceFamily.isEmpty {
            buildSettings.append(
                ("TARGETED_DEVICE_FAMILY", deviceFamily.pbxProjEscaped)
            )
        }

        if extensionSafe {
            buildSettings.append(("APPLICATION_EXTENSION_API_ONLY", "YES"))
        }

        if !infoPlist.isEmpty {
            buildSettings.append(
                (
                    "INFOPLIST_FILE",
                    infoPlist.buildSettingPath().pbxProjEscaped
                )
            )
        }

        if !entitlements.isEmpty {
            buildSettings.append(
                (
                    "CODE_SIGN_ENTITLEMENTS",
                    entitlements.buildSettingPath().pbxProjEscaped
                )
            )

            // This is required because otherwise Xcode can fails the build
            // due to a generated entitlements file being modified by the
            // Bazel build script. We only set this for BwB mode though,
            // because when this is set, Xcode uses the entitlements as
            // provided instead of modifying them, which is needed in BwX
            // mode.
            buildSettings.append(
                ("CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION", "YES")
            )
        }

        if skipCodesigning {
            buildSettings.append(("CODE_SIGNING_ALLOWED", "NO"))
        }

        if !certificateName.isEmpty {
            buildSettings.append(
                ("CODE_SIGN_IDENTITY", certificateName.pbxProjEscaped)
            )
        }

        if !teamID.isEmpty {
            buildSettings.append(("DEVELOPMENT_TEAM", teamID.pbxProjEscaped))
        }

        if !provisioningProfileName.isEmpty {
            buildSettings.append(
                (
                    "PROVISIONING_PROFILE_SPECIFIER",
                    provisioningProfileName.pbxProjEscaped
                )
            )
        }

        if provisioningProfileIsXcodeManaged {
            buildSettings.append(("CODE_SIGN_STYLE", "Automatic"))
        }

        return (buildSettings, clangArgs, frameworkIncludes, swiftIncludes)
    }
}

private func argsStream(
    from rawArguments: Array<String>.SubSequence
) -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { continuation in
        let argsTask = Task {
            for arg in rawArguments {
                guard !arg.starts(with: "@") else {
                    let path = String(arg.dropFirst())
                    for try await line in URL(fileURLWithPath: path).lines {
                        // Change params files from `shell` to `multiline`
                        // format
                        // https://bazel.build/versions/6.1.0/rules/lib/Args#set_param_file_format.format
                        if line.hasPrefix("'") && line.hasSuffix("'") {
                            let startIndex = line
                                .index(line.startIndex, offsetBy: 1)
                            let endIndex = line.index(before: line.endIndex)
                            continuation
                                .yield(String(line[startIndex ..< endIndex]))
                        } else {
                            continuation.yield(line)
                        }
                    }
                    continue
                }
                continuation.yield(arg)
            }
            continuation.finish()
        }
        continuation.onTermination = { @Sendable _ in
            argsTask.cancel()
        }
    }
}

import Foundation
import PBXProj
import ToolCommon
import XCScheme

extension Generator {
    struct CreateCustomSchemeInfos {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.callable = callable
        }

        /// Creates `SchemeInfo`s for custom schemes.
        func callAsFunction(
            commandLineArguments: [TargetID: [CommandLineArgument]],
            customSchemesFile: URL,
            environmentVariables: [TargetID: [EnvironmentVariable]],
            executionActionsFile: URL,
            extensionHostIDs: [TargetID: [TargetID]],
            targetsByID: [TargetID: Target]
        ) async throws -> [SchemeInfo] {
            try await callable(
                /*commandLineArguments:*/ commandLineArguments,
                /*customSchemesFile:*/ customSchemesFile,
                /*environmentVariables:*/ environmentVariables,
                /*executionActionsFile:*/ executionActionsFile,
                /*extensionHostIDs:*/ extensionHostIDs,
                /*targetsByID:*/ targetsByID
            )
        }
    }
}

// MARK: - CreateCustomSchemeInfos.Callable

extension Generator.CreateCustomSchemeInfos {
    typealias Callable = (
        _ commandLineArguments: [TargetID: [CommandLineArgument]],
        _ customSchemesFile: URL,
        _ environmentVariables: [TargetID: [EnvironmentVariable]],
        _ executionActionsFile: URL,
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ targetsByID: [TargetID: Target]
    ) async throws -> [SchemeInfo]

    static func defaultCallable(
        commandLineArguments: [TargetID: [CommandLineArgument]],
        customSchemesFile: URL,
        environmentVariables: [TargetID: [EnvironmentVariable]],
        executionActionsFile: URL,
        extensionHostIDs: [TargetID: [TargetID]],
        targetsByID: [TargetID: Target]
    ) async throws -> [SchemeInfo] {
        let executionActions: [String: [SchemeInfo.ExecutionAction]] =
            try await .parse(
                from: executionActionsFile,
                targetsByID: targetsByID
            )

        var rawArgs = ArraySlice(try await customSchemesFile.allLines.collect())

        let schemeCount = try rawArgs.consumeArg(
            "scheme-count",
            as: Int.self,
            in: customSchemesFile
        )

        var schemeInfos: [SchemeInfo] = []
        for _ in (0..<schemeCount) {
            let name =
                try rawArgs.consumeArg("scheme-name", in: customSchemesFile)

            var allTargetIDs: Set<TargetID> = []

            let test = try rawArgs.consumeArg(
                as: SchemeInfo.Test.self,
                in: customSchemesFile,
                allTargetIDs: &allTargetIDs,
                targetCommandLineArguments: commandLineArguments,
                targetEnvironmentVariables: environmentVariables,
                targetsByID: targetsByID
            )

            let run = try rawArgs.consumeArg(
                as: SchemeInfo.Run.self,
                in: customSchemesFile,
                allTargetIDs: &allTargetIDs,
                extensionHostIDs: extensionHostIDs,
                name: name,
                targetCommandLineArguments: commandLineArguments,
                targetEnvironmentVariables: environmentVariables,
                targetsByID: targetsByID
            )

            let profile = try rawArgs.consumeArg(
                as: SchemeInfo.Profile.self,
                in: customSchemesFile,
                allTargetIDs: &allTargetIDs,
                extensionHostIDs: extensionHostIDs,
                name: name,
                targetCommandLineArguments: commandLineArguments,
                targetEnvironmentVariables: environmentVariables,
                targetsByID: targetsByID
            )

            schemeInfos.append(
                SchemeInfo(
                    name: name,
                    test: test,
                    run: run,
                    profile: profile,
                    executionActions: executionActions[name, default: []]
                )
            )
        }

        return schemeInfos
    }
}

private extension ArraySlice where Element == String {
    // MARK: - CommandLineArgument

    mutating func consumeArgs(
        _ namePrefix: String,
        as type: CommandLineArgument.Type,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [CommandLineArgument]? {
        let count = try consumeArg(
            "\(namePrefix)-arg-count",
            as: Int.self,
            in: url,
            file: file,
            line: line
        )
        guard count != -1 else {
            return nil
        }

        var commandLineArguments: [CommandLineArgument] = []
        for _ in (0..<count) {
            let value = try consumeArg(
                "\(namePrefix)-arg",
                in: url,
                file: file,
                line: line
            ).nullsToNewlines
            let isEnabled = try consumeArg(
                "\(namePrefix)-arg-isEnabled",
                as: Bool.self,
                in: url,
                file: file,
                line: line
            )
            let isLiteralString = try consumeArg(
                "\(namePrefix)-arg-isLiteralString",
                as: Bool.self,
                in: url,
                file: file,
                line: line
            )

            commandLineArguments.append(
                .init(
                    value: value,
                    isEnabled: isEnabled,
                    isLiteralString: isLiteralString
                )
            )
        }

        return commandLineArguments
    }

    // MARK: - EnvironmentVariable

    mutating func consumeArgs(
        _ namePrefix: String,
        as type: EnvironmentVariable.Type,
        in url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [EnvironmentVariable]? {
        let count = try consumeArg(
            "\(namePrefix)-env-var-count",
            as: Int.self,
            in: url,
            file: file,
            line: line
        )
        guard count != -1 else {
            return nil
        }

        var environmentVariables: [EnvironmentVariable] = []
        for _ in (0..<count) {
            let key = try consumeArg(
                "\(namePrefix)-env-var-key",
                in: url,
                file: file,
                line: line
            ).nullsToNewlines
            let value = try consumeArg(
                "\(namePrefix)-env-var-value",
                in: url,
                file: file,
                line: line
            ).nullsToNewlines
            let isEnabled = try consumeArg(
                "\(namePrefix)-env-var-isEnabled",
                as: Bool.self,
                in: url,
                file: file,
                line: line
            )

            environmentVariables.append(
                .init(key: key, value: value, isEnabled: isEnabled)
            )
        }

        return environmentVariables
    }

    // MARK: - SchemeInfo.LaunchTarget

    mutating func consumeArg(
        _ namePrefix: String,
        as type: SchemeInfo.LaunchTarget?.Type,
        in url: URL,
        allTargetIDs: inout Set<TargetID>,
        context: @autoclosure () -> String,
        commandLineArguments: [CommandLineArgument]?,
        environmentVariables: [EnvironmentVariable]?,
        extensionHostIDs: [TargetID: [TargetID]],
        targetCommandLineArguments: [TargetID: [CommandLineArgument]],
        targetEnvironmentVariables: [TargetID: [EnvironmentVariable]],
        targetsByID: [TargetID: Target],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (
        SchemeInfo.LaunchTarget?,
        [CommandLineArgument],
        [EnvironmentVariable]
    ) {
        let isPath = try consumeArg(
            "\(namePrefix)-launch-target-is-path",
            as: Bool.self,
            in: url,
            file: file,
            line: line
        )

        if isPath {
            let path = try consumeArg(
                "\(namePrefix)-launch-target-path",
                as: String.self,
                in: url,
                file: file,
                line: line
            )
            return (
                SchemeInfo.LaunchTarget.path(path),
                commandLineArguments ?? [],
                environmentVariables ?? []
            )
        }

        let id = try consumeArg(
            "\(namePrefix)-launch-target-id",
            as: TargetID?.self,
            in: url,
            file: file,
            line: line
        )
        let extensionHostID = try consumeArg(
            "\(namePrefix)-extension-host",
            as: TargetID?.self,
            in: url,
            file: file,
            line: line
        )

        guard let id else {
            return (nil, commandLineArguments ?? [], environmentVariables ?? [])
        }

        allTargetIDs.insert(id)

        let target = try targetsByID.value(
            for: id,
            context: context()
        )

        guard !target.productType.needsExtensionHost || extensionHostID != nil
        else {
            throw UsageError(message: """
\(context()) (\(id)) is an app extension and requires `extension_host` to be \
set
""")
        }

        let extensionHost = try extensionHostID.flatMap { extensionHostID in
            guard extensionHostIDs[id, default: []]
                .contains(where: { $0 == extensionHostID })
            else {
                throw UsageError(message: """
\(context()) `extension_host` (\(extensionHostID)) does not host the extension \
(\(id))
""")
            }
            return try targetsByID.value(
                for: extensionHostID,
                context: "\(context()) extension host"
            )
        }

        // Only set from-rule args and env if the custom scheme sets them as
        // `inherit` (which is represented as `nil` here)
        let finalCommandLineArguments: [CommandLineArgument]
        if let commandLineArguments {
            finalCommandLineArguments = commandLineArguments
        } else {
            finalCommandLineArguments =
            targetCommandLineArguments[id, default: []]
        }

        let finalEnvironmentVariables: [EnvironmentVariable]
        if let environmentVariables {
            finalEnvironmentVariables = environmentVariables
        } else {
            finalEnvironmentVariables =
                targetEnvironmentVariables[id, default: []]
        }

        return (
            SchemeInfo.LaunchTarget.target(
                primary: target,
                extensionHost: extensionHost
            ),
            finalCommandLineArguments,
            finalEnvironmentVariables
        )
    }

    // MARK: - SchemeInfo.Profile

    mutating func consumeArg(
        as type: SchemeInfo.Profile.Type,
        in url: URL,
        allTargetIDs: inout Set<TargetID>,
        extensionHostIDs: [TargetID: [TargetID]],
        name: String,
        targetCommandLineArguments: [TargetID: [CommandLineArgument]],
        targetEnvironmentVariables: [TargetID: [EnvironmentVariable]],
        targetsByID: [TargetID: Target],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> SchemeInfo.Profile {
        let buildTargets = try consumeArgs(
            "profile-build-targets",
            as: Target.self,
            in: url,
            transform: { id in
                return try targetsByID.value(
                    for: TargetID(id),
                    context: "Profile build target"
                )
            }
        )
        allTargetIDs.formUnion(buildTargets.map(\.key.sortedIds.first!))

        let specifiedCommandLineArguments =
            try consumeArgs("profile", as: CommandLineArgument.self, in: url)
        let specifiedEnvironmentVariables =
            try consumeArgs("profile", as: EnvironmentVariable.self, in: url)
        let environmentVariablesIncludeDefaults = try consumeArg(
            "profile-include-default-env",
            as: Bool.self,
            in: url
        )

        let useRunArgsAndEnv = try consumeArg(
            "profile-use-run-args-and-env",
            as: Bool.self,
            in: url
        )
        let xcodeConfiguration = try consumeArg(
            "profile-xcode-configuration",
            as: String?.self,
            in: url
        )

        var (
            launchTarget,
            commandLineArguments,
            environmentVariables
        ) = try consumeArg(
            "profile",
            as: SchemeInfo.LaunchTarget?.self,
            in: url,
            allTargetIDs: &allTargetIDs,
            context: #"Custom scheme "\#(name)"'s profile launch target"#,
            commandLineArguments: specifiedCommandLineArguments,
            environmentVariables: specifiedEnvironmentVariables,
            extensionHostIDs: extensionHostIDs,
            targetCommandLineArguments: targetCommandLineArguments,
            targetEnvironmentVariables: targetEnvironmentVariables,
            targetsByID: targetsByID
        )
        let customWorkingDirectory = try consumeArg(
            "profile-custom-working-directory",
            as: String?.self,
            in: url
        )

        if let launchTarget, launchTarget.canExpandMacros &&
            environmentVariablesIncludeDefaults
        {
            environmentVariables.insert(
                contentsOf: Array.defaultEnvironmentVariables,
                at: 0
            )
        }

        return SchemeInfo.Profile(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            customWorkingDirectory: customWorkingDirectory,
            environmentVariables: environmentVariables,
            launchTarget: launchTarget,
            useRunArgsAndEnv: useRunArgsAndEnv,
            xcodeConfiguration: xcodeConfiguration
        )
    }

    // MARK: - SchemeInfo.Run

    mutating func consumeArg(
        as type: SchemeInfo.Run.Type,
        in url: URL,
        allTargetIDs: inout Set<TargetID>,
        extensionHostIDs: [TargetID: [TargetID]],
        name: String,
        targetCommandLineArguments: [TargetID: [CommandLineArgument]],
        targetEnvironmentVariables: [TargetID: [EnvironmentVariable]],
        targetsByID: [TargetID: Target],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> SchemeInfo.Run {
        let buildTargets = try consumeArgs(
            "run-build-targets",
            as: Target.self,
            in: url,
            transform: { id in
                return try targetsByID
                    .value(for: TargetID(id), context: "Run build target")
            }
        )
        allTargetIDs.formUnion(buildTargets.map(\.key.sortedIds.first!))

        let specifiedCommandLineArguments =
            try consumeArgs("run", as: CommandLineArgument.self, in: url)
        let specifiedEnvironmentVariables =
            try consumeArgs("run", as: EnvironmentVariable.self, in: url)
        let environmentVariablesIncludeDefaults =
            try consumeArg("run-include-default-env", as: Bool.self, in: url)

        let enableAddressSanitizer = try consumeArg(
            "run-enable-address-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableThreadSanitizer = try consumeArg(
            "run-enable-thread-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableUBSanitizer = try consumeArg(
            "run-enable-undefined-behavior-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableMainThreadChecker = try consumeArg(
            "run-disable-main-thread-checker",
            as: Bool.self,
            in: url
        )
        let enableThreadPerformanceChecker = try consumeArg(
            "run-disable-performance-anti-pattern-checker",
            as: Bool.self,
            in: url
        )
        let xcodeConfiguration =
            try consumeArg("run-xcode-configuration", as: String?.self, in: url)

        var (
            launchTarget,
            commandLineArguments,
            environmentVariables
        ) = try consumeArg(
            "run",
            as: SchemeInfo.LaunchTarget?.self,
            in: url,
            allTargetIDs: &allTargetIDs,
            context: #"Custom scheme "\#(name)"'s run launch target"#,
            commandLineArguments: specifiedCommandLineArguments,
            environmentVariables: specifiedEnvironmentVariables,
            extensionHostIDs: extensionHostIDs,
            targetCommandLineArguments: targetCommandLineArguments,
            targetEnvironmentVariables: targetEnvironmentVariables,
            targetsByID: targetsByID
        )
        let customWorkingDirectory = try consumeArg(
            "run-custom-working-directory",
            as: String?.self,
            in: url
        )

        if let launchTarget,
            launchTarget.canExpandMacros && environmentVariablesIncludeDefaults
        {
            environmentVariables.insert(
                contentsOf: Array.defaultEnvironmentVariables,
                at: 0
            )
        }

        return SchemeInfo.Run(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            customWorkingDirectory: customWorkingDirectory,
            enableAddressSanitizer: enableAddressSanitizer,
            enableThreadSanitizer: enableThreadSanitizer,
            enableUBSanitizer: enableUBSanitizer,
            enableMainThreadChecker: enableMainThreadChecker,
            enableThreadPerformanceChecker: enableThreadPerformanceChecker,
            environmentVariables: environmentVariables,
            launchTarget: launchTarget,
            xcodeConfiguration: xcodeConfiguration
        )
    }

    // MARK: - SchemeInfo.Test

    mutating func consumeArg(
        as type: SchemeInfo.Test.Type,
        in url: URL,
        allTargetIDs: inout Set<TargetID>,
        targetCommandLineArguments: [TargetID: [CommandLineArgument]],
        targetEnvironmentVariables: [TargetID: [EnvironmentVariable]],
        targetsByID: [TargetID: Target],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> SchemeInfo.Test {
        let testTargetCount =
            try consumeArg("test-target-count", as: Int.self, in: url)

        var testTargets: [SchemeInfo.TestTarget] = []
        for _ in (0..<testTargetCount) {
            let id =
                try consumeArg("test-target-id", as: TargetID.self, in: url)
            let isEnabled =
                try consumeArg("test-isEnabled", as: Bool.self, in: url)

            testTargets.append(
                .init(
                    target: try targetsByID.value(
                        for: id,
                        context: "Test target"
                    ),
                    isEnabled: isEnabled
                )
            )
        }
        allTargetIDs.formUnion(testTargets.map(\.target.key.sortedIds.first!))

        let buildTargets = try consumeArgs(
            "test-build-targets",
            as: Target.self,
            in: url,
            transform: { id in
                return try targetsByID
                    .value(for: TargetID(id), context: "Test build target")
            }
        )
        allTargetIDs.formUnion(buildTargets.map(\.key.sortedIds.first!))

        let specifiedCommandLineArguments =
            try consumeArgs("test", as: CommandLineArgument.self, in: url)
        let specifiedEnvironmentVariables =
            try consumeArgs("test", as: EnvironmentVariable.self, in: url)
        let environmentVariablesIncludeDefaults =
            try consumeArg("test-include-default-env", as: Bool.self, in: url)

        let useRunArgsAndEnv =
            try consumeArg("test-use-run-args-and-env", as: Bool.self, in: url)

        let enableAddressSanitizer = try consumeArg(
            "test-enable-address-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableThreadSanitizer = try consumeArg(
            "test-enable-thread-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableUBSanitizer = try consumeArg(
            "test-enable-undefined-behavior-sanitizer",
            as: Bool.self,
            in: url
        )
        let enableMainThreadChecker = try consumeArg(
            "test-enable-main-thread-checker",
            as: Bool.self,
            in: url
        )
        let enableThreadPerformanceChecker = try consumeArg(
            "test-enable-performance-anti-pattern-checker",
            as: Bool.self,
            in: url
        )
        let appLanguage = try consumeArg(
            "test-app-language",
            as: String?.self,
            in: url
        )
        let appRegion = try consumeArg(
            "test-app-region",
            as: String?.self,
            in: url
        )
        let codeCoverage = try consumeArg(
            "test-code-coverage",
            as: Bool.self,
            in: url
        )
        let xcodeConfiguration = try consumeArg(
            "test-xcode-configuration",
            as: String?.self,
            in: url
        )

        let firstTestTargetID = testTargets.first?.target.key.sortedIds.first!

        let commandLineArguments: [CommandLineArgument]
        if let specifiedCommandLineArguments {
            commandLineArguments = specifiedCommandLineArguments
        } else if let firstTestTargetID, let aCommandLineArguments =
            targetCommandLineArguments[firstTestTargetID]
        {
            // If the custom scheme inherits command-line arguments, and every
            // test target defines the same args, then use them
            var allCommandLineArgumentsTheSame = true
            for testTarget in testTargets {
                let id = testTarget.target.key.sortedIds.first!
                guard aCommandLineArguments == targetCommandLineArguments[id]
                else {
                    allCommandLineArgumentsTheSame = false
                    break
                }
            }

            if allCommandLineArgumentsTheSame {
                commandLineArguments = aCommandLineArguments
            } else {
                commandLineArguments = []
            }
        } else {
            commandLineArguments = []
        }

        var environmentVariables: [EnvironmentVariable]
        if let specifiedEnvironmentVariables {
            environmentVariables = specifiedEnvironmentVariables
        } else if let firstTestTargetID, let aEnvironmentVariables =
            targetEnvironmentVariables[firstTestTargetID]
        {
            // If the custom scheme inherits environment variables, and every
            // test target defines the same env, then use them
            var allEnvironmentVariablesTheSame = true
            for testTarget in testTargets {
                let id = testTarget.target.key.sortedIds.first!
                guard aEnvironmentVariables ==
                    targetEnvironmentVariables[id]
                else {
                    allEnvironmentVariablesTheSame = false
                    break
                }
            }

            if allEnvironmentVariablesTheSame {
                environmentVariables = aEnvironmentVariables
            } else {
                environmentVariables = []
            }
        } else {
            environmentVariables = []
        }

        if environmentVariablesIncludeDefaults && !testTargets.isEmpty {
            environmentVariables.insert(
                contentsOf: Array.defaultEnvironmentVariables,
                at: 0
            )
        }

        return SchemeInfo.Test(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            enableAddressSanitizer: enableAddressSanitizer,
            enableThreadSanitizer: enableThreadSanitizer,
            enableUBSanitizer: enableUBSanitizer,
            enableMainThreadChecker: enableMainThreadChecker,
            enableThreadPerformanceChecker: enableThreadPerformanceChecker,
            environmentVariables: environmentVariables,
            options: .init(appLanguage: appLanguage,
                           appRegion: appRegion,
                           codeCoverage: codeCoverage),
            testTargets: testTargets,
            useRunArgsAndEnv: useRunArgsAndEnv,
            xcodeConfiguration: xcodeConfiguration
        )
    }
}

private extension Dictionary where
    Key == String, Value == [SchemeInfo.ExecutionAction]
{
    // MARK: - [String: [SchemeInfo.ExecutionAction]]

    /// Maps scheme name -> `[SchemeInfo.ExecutionAction]`.
    static func parse(
        from url: URL,
        targetsByID: [TargetID: Target]
    ) async throws -> Self {
        var rawArgs = ArraySlice(try await url.allLines.collect())

        var ret: [String: [SchemeInfo.ExecutionAction]] = [:]

        while !rawArgs.isEmpty {
            let schemeName = try rawArgs.consumeArg("scheme-name", in: url)
            let action = try rawArgs.consumeArg(
                "action",
                as: SchemeInfo.ExecutionAction.Action.self,
                in: url
            )
            let isPreAction =
                try rawArgs.consumeArg("is-pre-action", as: Bool.self, in: url)
            let title = try rawArgs.consumeArg("title", in: url).nullsToNewlines
            let scriptText =
                try rawArgs.consumeArg("script-text", in: url).nullsToNewlines
            let id =
                try rawArgs.consumeArg("target-id", as: TargetID.self, in: url)
            let order = try rawArgs.consumeArg("order", as: Int?.self, in: url)

            // if target id is empty then there is no target associated with this pre/post action.
            let target = try id.rawValue.isEmpty ? nil : targetsByID.value(
                for: id,
                context: "Execution action associated target ID"
            )

            ret[schemeName, default: []].append(
                .init(
                    title: title,
                    scriptText: scriptText,
                    action: action,
                    isPreAction: isPreAction,
                    target: target,
                    order: order
                )
            )
        }

        return ret
    }
}

private extension PBXProductType {
    var needsExtensionHost: Bool {
        switch self {
        case .appExtension,
             .intentsServiceExtension,
             .messagesExtension,
             .tvExtension,
             .extensionKitExtension:
            return true
        default:
            return false
        }
    }
}

private extension SchemeInfo.LaunchTarget {
    var canExpandMacros: Bool {
        switch self {
        case .target: return true
        case .path: return false
        }
    }
}

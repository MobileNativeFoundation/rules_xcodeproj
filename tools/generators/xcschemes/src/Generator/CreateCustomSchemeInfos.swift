import Foundation
import PBXProj
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

        /// Creates and writes automatically generated `.xcscheme`s to disk.
        func callAsFunction(
            customSchemeArguments: CustomSchemesArguments,
            targetsByID: [TargetID: Target]
        ) throws -> [SchemeInfo] {
            try callable(
                /*customSchemeArguments:*/ customSchemeArguments,
                /*targetsByID:*/ targetsByID
            )
        }
    }
}

// MARK: - CreateCustomSchemeInfos.Callable

extension Generator.CreateCustomSchemeInfos {
    typealias Callable = (
        _ customSchemeArguments: CustomSchemesArguments,
        _ targetsByID: [TargetID: Target]
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        customSchemeArguments: CustomSchemesArguments,
        targetsByID: [TargetID: Target]
    ) throws -> [SchemeInfo] {
        return try customSchemeArguments.calculateSchemeInfos(
            targetsByID: targetsByID
        )
    }
}

extension CustomSchemesArguments {
    func calculateSchemeInfos(
        targetsByID: [TargetID: Target]
    ) throws -> [SchemeInfo] {
        let executionActions = executionActionsArguments
            .calculateExecutionActions()

        var testBuildOnlyTargetsStartIndex = testBuildOnlyTargets.startIndex
        var testCommandLineArgumentsStartIndex =
            testCommandLineArguments.startIndex
        var testEnvironmentVariablesStartIndex =
            testEnvironmentVariables.startIndex
        var testTargetsStartIndex = testTargets.startIndex

        var runBuildOnlyTargetsStartIndex = runBuildOnlyTargets.startIndex
        var runCommandLineArgumentsStartIndex =
            runCommandLineArguments.startIndex
        var runEnvironmentVariablesStartIndex =
            runEnvironmentVariables.startIndex

        var profileBuildOnlyTargetsStartIndex =
            profileBuildOnlyTargets.startIndex
        var profileCommandLineArgumentsStartIndex =
            profileCommandLineArguments.startIndex
        var profileEnvironmentVariablesStartIndex =
            profileEnvironmentVariables.startIndex

        var schemeInfos: [SchemeInfo] = []
        for schemeIndex in customSchemes.indices {
            let name = customSchemes[schemeIndex]

            let executionActions = executionActions[name, default: [:]]

            // MARK: Test

            let testExecutionActions = executionActions[.test, default: [:]]
            let testBuildOnlyTargets = try testBuildOnlyTargets
                .buildableTargetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: testBuildOnlyTargetCounts,
                    startIndex: &testBuildOnlyTargetsStartIndex,
                    executionActions: testExecutionActions,
                    targetsByID: targetsByID,
                    context: "Test build only target"
                )
            let testCommandLineArguments = testCommandLineArguments.slicedBy(
                schemeIndex: schemeIndex,
                counts: testCommandLineArgumentCounts,
                startIndex: &testCommandLineArgumentsStartIndex
            )
            var testEnvironmentVariables = testEnvironmentVariables
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: testEnvironmentVariableCounts,
                    startIndex: &testEnvironmentVariablesStartIndex
                )
            let testTargets = try testTargets.buildableTargetsSlicedBy(
                schemeIndex: schemeIndex,
                counts: testTargetCounts,
                startIndex: &testTargetsStartIndex,
                executionActions: testExecutionActions,
                targetsByID: targetsByID,
                context: "Test target"
            )
            let testUseRunArgsAndEnv = testUseRunArgsAndEnv[schemeIndex]

            if !testUseRunArgsAndEnv {
                testEnvironmentVariables
                    .insert(contentsOf: Array.baseEnvironmentVariables, at: 0)
            }

            // MARK: Run

            let runExecutionActions = executionActions[.run, default: [:]]
            let runBuildOnlyTargets = try runBuildOnlyTargets
                .buildableTargetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: runBuildOnlyTargetCounts,
                    startIndex: &runBuildOnlyTargetsStartIndex,
                    executionActions: runExecutionActions,
                    targetsByID: targetsByID,
                    context: "Run build only target"
                )
            let runCommandLineArguments = runCommandLineArguments.slicedBy(
                schemeIndex: schemeIndex,
                counts: runCommandLineArgumentCounts,
                startIndex: &runCommandLineArgumentsStartIndex
            )
            let runEnvironmentVariables = runEnvironmentVariables
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: runEnvironmentVariableCounts,
                    startIndex: &runEnvironmentVariablesStartIndex
                )

            // MARK: Profile

            let profileExecutionActions = executionActions[.run, default: [:]]
            let profileBuildOnlyTargets = try profileBuildOnlyTargets
                .buildableTargetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileBuildOnlyTargetCounts,
                    startIndex: &profileBuildOnlyTargetsStartIndex,
                    executionActions: profileExecutionActions,
                    targetsByID: targetsByID,
                    context: "Profile build only target"
                )
            let profileCommandLineArguments = profileCommandLineArguments
                .slicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileCommandLineArgumentCounts,
                    startIndex: &profileCommandLineArgumentsStartIndex
                )
            var profileEnvironmentVariables = profileEnvironmentVariables
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileEnvironmentVariableCounts,
                    startIndex: &profileEnvironmentVariablesStartIndex
                )
            let profileUseRunArgsAndEnv =
                profileUseRunArgsAndEnv[schemeIndex]

            if !profileUseRunArgsAndEnv {
                profileEnvironmentVariables
                    .insert(contentsOf: Array.baseEnvironmentVariables, at: 0)
            }

            schemeInfos.append(
                SchemeInfo(
                    name: name,
                    test: SchemeInfo.Test(
                        buildOnlyTargets: testBuildOnlyTargets,
                        commandLineArguments: testCommandLineArguments,
                        enableAddressSanitizer:
                            testEnableAddressSanitizer[schemeIndex],
                        enableThreadSanitizer:
                            testEnableThreadSanitizer[schemeIndex],
                        enableUBSanitizer: testEnableUBSanitizer[schemeIndex],
                        environmentVariables: testEnvironmentVariables,
                        testTargets: testTargets,
                        useRunArgsAndEnv: testUseRunArgsAndEnv,
                        xcodeConfiguration: testXcodeConfiguration[schemeIndex]
                    ),
                    run: SchemeInfo.Run(
                        buildOnlyTargets: runBuildOnlyTargets,
                        commandLineArguments: runCommandLineArguments,
                        customWorkingDirectory:
                            runCustomWorkingDirectory[schemeIndex],
                        enableAddressSanitizer:
                            runEnableAddressSanitizer[schemeIndex],
                        enableThreadSanitizer:
                            runEnableThreadSanitizer[schemeIndex],
                        enableUBSanitizer: runEnableUBSanitizer[schemeIndex],
                        environmentVariables: .baseEnvironmentVariables +
                            runEnvironmentVariables,
                        launchTarget: try runLaunchTarget[schemeIndex]
                            .flatMap { id in
                                try .init(
                                    target: id,
                                    extensionHost: runLaunchExtensionHost[
                                        schemeIndex
                                    ],
                                    executionActions: runExecutionActions,
                                    targetsByID: targetsByID,
                                    context: "Run"
                                )
                            },
                        // FIXME: Calculate `transitivePreviewReferences`
                        transitivePreviewReferences: [],
                        xcodeConfiguration: runXcodeConfiguration[schemeIndex]
                    ),
                    profile: SchemeInfo.Profile(
                        buildOnlyTargets: profileBuildOnlyTargets,
                        commandLineArguments: profileCommandLineArguments,
                        customWorkingDirectory:
                            profileCustomWorkingDirectory[schemeIndex],
                        environmentVariables: profileEnvironmentVariables,
                        launchTarget: try profileLaunchTarget[schemeIndex]
                            .flatMap { id in
                                try .init(
                                    target: id,
                                    extensionHost: profileLaunchExtensionHost[
                                        schemeIndex
                                    ],
                                    executionActions: profileExecutionActions,
                                    targetsByID: targetsByID,
                                    context: "Profile"
                                )
                            },
                        useRunArgsAndEnv: profileUseRunArgsAndEnv,
                        xcodeConfiguration:
                            profileXcodeConfiguration[schemeIndex]
                    )
                )
            )
        }

        return schemeInfos
    }
}

private extension SchemeInfo.BuildableTarget {
    init(
        target: Target,
        executionActions: [Bool: [SchemeInfo.ExecutionAction]]
    ) {
        self.init(
            target: target,
            preActions: executionActions[true, default: []],
            postActions: executionActions[false, default: []]
        )
    }
}

private extension SchemeInfo.LaunchTarget {
    init(
        target: TargetID,
        extensionHost: TargetID?,
        executionActions: [TargetID: [Bool: [SchemeInfo.ExecutionAction]]],
        targetsByID: [TargetID: Target],
        context: @autoclosure () -> String
    ) throws {
        self.init(
            primary: .init(
                target: try targetsByID.value(
                    for: target,
                    context:
                        "\(context()) launch target"
                ),
                executionActions: executionActions[target, default: [:]]
            ),
            extensionHost: try extensionHost.flatMap { id in
                return try targetsByID.value(
                    for: id,
                    context: "\(context()) launch extension host"
                )
            }
        )
    }
}

private extension Array {
    func slicedBy<CountsCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> Self where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return self
        }

        let endIndex = startIndex.advanced(by: counts[schemeIndex])
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return Array(self[range])
    }
}

private extension Array where Element == TargetID {
    func buildableTargetsSlicedBy<CountsCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index,
        executionActions: [TargetID: [Bool: [SchemeInfo.ExecutionAction]]],
        targetsByID: [TargetID: Target],
        context: @autoclosure () -> String
    ) throws -> [SchemeInfo.BuildableTarget] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let endIndex = startIndex.advanced(by: counts[schemeIndex])
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return try self[range].map { id in
            return .init(
                target: try targetsByID.value(for: id, context: context()),
                executionActions: executionActions[id, default: [:]]
            )
        }
    }
}

private extension Array where Element == String {
    func environmentVariablesSlicedBy<CountsCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> [EnvironmentVariable] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let endIndex = startIndex.advanced(by: counts[schemeIndex] * 2)
        defer {
            startIndex = endIndex
        }

        return stride(from: startIndex, to: endIndex, by: 2)
            .lazy
            .map { EnvironmentVariable(key: self[$0], value: self[$0+1]) }
    }
}

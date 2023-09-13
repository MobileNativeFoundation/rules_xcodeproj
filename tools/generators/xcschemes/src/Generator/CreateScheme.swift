import OrderedCollections
import PBXProj
import XCScheme

extension Generator {
    struct CreateScheme {
        private let createAnalyzeAction: CreateAnalyzeAction
        private let createArchiveAction: CreateArchiveAction
        private let createBuildAction: CreateBuildAction
        private let createLaunchAction: CreateLaunchAction
        private let createProfileAction: CreateProfileAction
        private let createSchemeXML: XCScheme.CreateScheme
        private let createTestAction: CreateTestAction

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAnalyzeAction: CreateAnalyzeAction,
            createArchiveAction: CreateArchiveAction,
            createBuildAction: CreateBuildAction,
            createLaunchAction: CreateLaunchAction,
            createProfileAction: CreateProfileAction,
            createSchemeXML: XCScheme.CreateScheme,
            createTestAction: CreateTestAction,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createAnalyzeAction = createAnalyzeAction
            self.createArchiveAction = createArchiveAction
            self.createBuildAction = createBuildAction
            self.createLaunchAction = createLaunchAction
            self.createProfileAction = createProfileAction
            self.createSchemeXML = createSchemeXML
            self.createTestAction = createTestAction

            self.callable = callable
        }

        /// Creates the XML for an automatically generated `.xcscheme` file.
        func callAsFunction(
            defaultXcodeConfiguration: String,
            extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
            schemeInfo: SchemeInfo
        ) throws -> (name: String, scheme: String) {
            return try callable(
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration,
                /*extensionPointIdentifiers:*/ extensionPointIdentifiers,
                /*schemeInfo:*/ schemeInfo,
                /*createAnalyzeAction:*/ createAnalyzeAction,
                /*createArchiveAction:*/ createArchiveAction,
                /*createBuildAction:*/ createBuildAction,
                /*createLaunchAction:*/ createLaunchAction,
                /*createProfileAction:*/ createProfileAction,
                /*createSchemeXML:*/ createSchemeXML,
                /*createTestAction:*/ createTestAction
            )
        }
    }
}

// MARK: - CreateScheme.Callable

extension Generator.CreateScheme {
    typealias Callable = (
        _ defaultXcodeConfiguration: String,
        _ extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        _ schemeInfo: SchemeInfo,
        _ createAnalyzeAction: CreateAnalyzeAction,
        _ createArchiveAction: CreateArchiveAction,
        _ createBuildAction: CreateBuildAction,
        _ createLaunchAction: CreateLaunchAction,
        _ createProfileAction: CreateProfileAction,
        _ createSchemeXML: XCScheme.CreateScheme,
        _ createTestAction: CreateTestAction
    ) throws -> (name: String, scheme: String)

    static func defaultCallable(
        defaultXcodeConfiguration: String,
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        schemeInfo: SchemeInfo,
        createAnalyzeAction: CreateAnalyzeAction,
        createArchiveAction: CreateArchiveAction,
        createBuildAction: CreateBuildAction,
        createLaunchAction: CreateLaunchAction,
        createProfileAction: CreateProfileAction,
        createSchemeXML:  XCScheme.CreateScheme,
        createTestAction: CreateTestAction
    ) throws -> (name: String, scheme: String) {
        var buildActionEntries:
            OrderedDictionary<String, BuildActionEntry> = [:]
        func adjustBuildActionEntry(
            for reference: BuildableReference,
            include buildFor: BuildActionEntry.BuildFor
        ) {
            buildActionEntries[reference.blueprintIdentifier, default: .init(
                buildableReference: reference,
                buildFor: []
            )].buildFor.formUnion(buildFor)
        }

        var buildPostActions: [ExecutionAction] = []
        var buildPreActions: [ExecutionAction] = []

        // FIXME: Order these based on `.order`
        func handleExecutionAction(
            buildableTarget: SchemeInfo.BuildableTarget,
            actionPreActions: inout [ExecutionAction],
            actionPostActions: inout [ExecutionAction]
        ) {
            func handleExecutionAction(
                _ executionAction: SchemeInfo.ExecutionAction,
                isPreAction: Bool
            ) {
                let schemeExecutionAction = ExecutionAction(
                    title: executionAction.title,
                    escapedScriptText:
                        executionAction.scriptText.schemeXmlEscaped,
                    expandVariablesBasedOn:
                        buildableTarget.target.buildableReference
                )
                switch (executionAction.forBuild, isPreAction) {
                case (true, true):
                    buildPreActions.append(schemeExecutionAction)
                case (true, false):
                    buildPostActions.append(schemeExecutionAction)
                case (false, true):
                    actionPreActions.append(schemeExecutionAction)
                case (false, false):
                    actionPostActions.append(schemeExecutionAction)
                }
            }

            buildableTarget.preActions
                .forEach { handleExecutionAction($0, isPreAction: true) }
            buildableTarget.postActions
                .forEach { handleExecutionAction($0, isPreAction: false) }
        }

        // MARK: Run

        let launchBuildConfiguration = schemeInfo.run.xcodeConfiguration ??
            defaultXcodeConfiguration

        let launchRunnable: Runnable?
        var launchPostActions: [ExecutionAction] = []
        var launchPreActions: [ExecutionAction] = []
        let wasCreatedForAppExtension: Bool
        if let launchTarget = schemeInfo.run.launchTarget {
            let buildableReference =
                launchTarget.primary.target.buildableReference

            adjustBuildActionEntry(
                for: buildableReference,
                include: [.running, .analyzing]
            )

            if let extensionHost = launchTarget.extensionHost {
                let hostBuildableReference = extensionHost.buildableReference

                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: [.running, .analyzing]
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: launchTarget.primary.target.key.sortedIds.first!,
                        context: "Extension Target ID"
                    )

                launchRunnable = .hosted(
                    buildableReference: buildableReference,
                    hostBuildableReference: hostBuildableReference,
                    debuggingMode: extensionPointIdentifier.debuggingMode,
                    remoteBundleIdentifier:
                        extensionPointIdentifier.remoteBundleIdentifier
                )
                wasCreatedForAppExtension = true
            } else {
                launchRunnable = .plain(buildableReference: buildableReference)
                wasCreatedForAppExtension = false
            }

            launchPreActions.append(
                .updateLldbInitAndCopyDSYMs(for: buildableReference)
            )

            handleExecutionAction(
                buildableTarget: launchTarget.primary,
                actionPreActions: &launchPreActions,
                actionPostActions: &launchPostActions
            )
        } else {
            launchRunnable = nil
            wasCreatedForAppExtension = false
        }

        for buildOnlyTarget in schemeInfo.run.buildOnlyTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.target.buildableReference,
                include: [.running, .analyzing]
            )

            handleExecutionAction(
                buildableTarget: buildOnlyTarget,
                actionPreActions: &launchPreActions,
                actionPostActions: &launchPostActions
            )
        }

        // MARK: Profile

        let profileRunnable: Runnable?
        var profilePostActions: [ExecutionAction] = []
        var profilePreActions: [ExecutionAction] = []
        if let launchTarget = schemeInfo.profile.launchTarget {
            let buildableReference =
                launchTarget.primary.target.buildableReference

            adjustBuildActionEntry(for: buildableReference, include: .profiling)

            if let extensionHost = launchTarget.extensionHost {
                let hostBuildableReference = extensionHost.buildableReference

                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: .profiling
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: launchTarget.primary.target.key.sortedIds.first!,
                        context: "Extension Target ID"
                    )

                profileRunnable = .hosted(
                    buildableReference: buildableReference,
                    hostBuildableReference: hostBuildableReference,
                    debuggingMode: extensionPointIdentifier.debuggingMode,
                    remoteBundleIdentifier:
                        extensionPointIdentifier.remoteBundleIdentifier
                )
            } else {
                profileRunnable =
                    .plain(buildableReference: buildableReference)
            }

            profilePreActions.append(
                .updateLldbInitAndCopyDSYMs(for: buildableReference)
            )

            handleExecutionAction(
                buildableTarget: launchTarget.primary,
                actionPreActions: &profilePreActions,
                actionPostActions: &profilePostActions
            )
        } else {
            profileRunnable = nil
        }

        for buildOnlyTarget in schemeInfo.profile.buildOnlyTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.target.buildableReference,
                include: .profiling
            )

            handleExecutionAction(
                buildableTarget: buildOnlyTarget,
                actionPreActions: &profilePreActions,
                actionPostActions: &profilePostActions
            )
        }

        // MARK: Test

        var testables: [BuildableReference] = []
        var testPostActions: [ExecutionAction] = []
        var testPreActions: [ExecutionAction] = []

        for buildOnlyTarget in schemeInfo.test.buildOnlyTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.target.buildableReference,
                include: .testing
            )

            handleExecutionAction(
                buildableTarget: buildOnlyTarget,
                actionPreActions: &testPreActions,
                actionPostActions: &testPostActions
            )
        }

        // We process test targets last, but before Xcode Previews additional
        // targets, to ensure that the scheme icon is only a test bundle if
        // there are no other types of targets.
        for testTarget in schemeInfo.test.testTargets {
            let buildableReference = testTarget.target.buildableReference

            adjustBuildActionEntry(for: buildableReference, include: .testing)

            testables.append(buildableReference)

            handleExecutionAction(
                buildableTarget: testTarget,
                actionPreActions: &testPreActions,
                actionPostActions: &testPostActions
            )
        }

        // If we have a testable, use the first one to update `.lldbinit`
        if let testable = testables.first {
            testPreActions.insert(
                .updateLldbInitAndCopyDSYMs(for: testable),
                at: 0
            )
        }

        // MARK: Xcode Previews additional targets

        for reference in schemeInfo.run.transitivePreviewReferences {
            adjustBuildActionEntry(for: reference, include: .running)
        }

        // MARK: Build

        let buildActionEntryValues = buildActionEntries.values.elements

        if let firstReference =
            buildActionEntryValues.first?.buildableReference
        {
            // Use the first build entry for our Bazel support build pre-actions
            buildPreActions.insert(
                contentsOf: [
                    .initializeBazelBuildOutputGroupsFile(
                        with: firstReference
                    ),
                    .prepareBazelDependencies(with: firstReference),
                ],
                at: 0
            )
        }

        // MARK: Scheme

        let scheme = createSchemeXML(
            buildAction: createBuildAction(
                entries: buildActionEntryValues,
                postActions: buildPostActions,
                preActions: buildPreActions
            ),
            testAction: createTestAction(
                buildConfiguration: schemeInfo.test.xcodeConfiguration ??
                    launchBuildConfiguration,
                commandLineArguments: schemeInfo.test.commandLineArguments,
                enableAddressSanitizer: schemeInfo.test.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.test.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.test.enableUBSanitizer,
                environmentVariables: schemeInfo.test.environmentVariables,
                expandVariablesBasedOn: schemeInfo.test.useRunArgsAndEnv ?
                    nil : testables.first,
                postActions: testPostActions,
                preActions: testPreActions,
                testables: testables,
                useLaunchSchemeArgsEnv: schemeInfo.test.useRunArgsAndEnv
            ),
            launchAction: createLaunchAction(
                buildConfiguration: launchBuildConfiguration,
                commandLineArguments: schemeInfo.run.commandLineArguments,
                customWorkingDirectory: schemeInfo.run.customWorkingDirectory,
                enableAddressSanitizer: schemeInfo.run.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.run.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.run.enableUBSanitizer,
                environmentVariables: schemeInfo.run.environmentVariables,
                postActions: launchPostActions,
                preActions: launchPreActions,
                runnable: launchRunnable
            ),
            profileAction: createProfileAction(
                buildConfiguration: schemeInfo.profile.xcodeConfiguration ??
                    launchBuildConfiguration,
                commandLineArguments: schemeInfo.run.commandLineArguments,
                customWorkingDirectory: schemeInfo.run.customWorkingDirectory,
                environmentVariables: schemeInfo.run.environmentVariables,
                postActions: profilePostActions,
                preActions: profilePreActions,
                useLaunchSchemeArgsEnv: true,
                runnable: profileRunnable
            ),
            analyzeAction: createAnalyzeAction(
                buildConfiguration: launchBuildConfiguration
            ),
            archiveAction: createArchiveAction(
                buildConfiguration: launchBuildConfiguration
            ),
            wasCreatedForAppExtension: wasCreatedForAppExtension
        )

        return (schemeInfo.name, scheme)
    }
}

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

        /// Creates the XML for an `.xcscheme` file.
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
            buildActionEntries[
                reference.blueprintIdentifier,
                default: .init(
                    buildableReference: reference,
                    buildFor: []
                )
            ].buildFor.formUnion(buildFor)
        }

        var buildPostActions: [OrderedExecutionAction] = []
        var buildPreActions: [OrderedExecutionAction] = []
        var launchPostActions: [OrderedExecutionAction] = []
        var launchPreActions: [OrderedExecutionAction] = []
        var profilePostActions: [OrderedExecutionAction] = []
        var profilePreActions: [OrderedExecutionAction] = []
        var testPostActions: [OrderedExecutionAction] = []
        var testPreActions: [OrderedExecutionAction] = []

        func handleExecutionAction(
            _ executionAction: SchemeInfo.ExecutionAction
        ) {
            let schemeExecutionAction = ExecutionAction(
                title: executionAction.title,
                escapedScriptText:
                    executionAction.scriptText.schemeXmlEscaped,
                expandVariablesBasedOn:
                    executionAction.target?.buildableReference
            )

            switch (executionAction.action, executionAction.isPreAction) {
            case (.build, true):
                buildPreActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.build, false):
                buildPostActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.run, true):
                launchPreActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.run, false):
                launchPostActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.test, true):
                testPreActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.test, false):
                testPostActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.profile, true):
                profilePreActions
                    .append((schemeExecutionAction, executionAction.order))
            case (.profile, false):
                profilePostActions
                    .append((schemeExecutionAction, executionAction.order))
            }
        }

        // MARK: Run

        let launchBuildConfiguration = schemeInfo.run.xcodeConfiguration ??
            defaultXcodeConfiguration

        let launchRunnable: Runnable?
        let canUseLaunchSchemeArgsEnv: Bool
        let wasCreatedForAppExtension: Bool
        switch schemeInfo.run.launchTarget {
        case let .target(primary, extensionHost):
            canUseLaunchSchemeArgsEnv = true

            let buildableReference = primary.buildableReference

            adjustBuildActionEntry(
                for: buildableReference,
                include: [.running, .analyzing]
            )

            if let extensionHost {
                let hostBuildableReference = extensionHost.buildableReference
                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: [.running, .analyzing]
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: primary.key.sortedIds.first!,
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

            launchPreActions
                .appendUpdateLldbInitAndCopyDSYMs(for: buildableReference)
        case let .path(path):
            launchRunnable = .path(path: path)
            canUseLaunchSchemeArgsEnv = false
            wasCreatedForAppExtension = false

        case .none:
            launchRunnable = nil
            canUseLaunchSchemeArgsEnv = false
            wasCreatedForAppExtension = false
        }

        for buildOnlyTarget in schemeInfo.run.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: [.running, .analyzing]
            )
        }

        // MARK: Profile

        let profileRunnable: Runnable?
        switch schemeInfo.profile.launchTarget {
        case let .target(primary, extensionHost):
            let buildableReference = primary.buildableReference
            adjustBuildActionEntry(for: buildableReference, include: .profiling)

            if let extensionHost {
                let hostBuildableReference = extensionHost.buildableReference

                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: .profiling
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: primary.key.sortedIds.first!,
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

            profilePreActions
                .appendUpdateLldbInitAndCopyDSYMs(for: buildableReference)

        case let .path(path):
            profileRunnable = .path(path: path)

        case .none:
            profileRunnable = nil
        }

        for buildOnlyTarget in schemeInfo.profile.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: .profiling
            )
        }

        let profileUseLaunchSchemeArgsEnv =
            canUseLaunchSchemeArgsEnv && schemeInfo.profile.useRunArgsAndEnv

        // MARK: Test

        for buildOnlyTarget in schemeInfo.test.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: .testing
            )
        }

        // We process `testTargets` after `buildTargets` to ensure that
        // test bundle icons are only used for a scheme if there are no launch
        // or library targets declared
        var testables: [Testable] = []
        for testTarget in schemeInfo.test.testTargets {
            let buildableTarget = testTarget.target
            let buildableReference = buildableTarget.buildableReference

            adjustBuildActionEntry(for: buildableReference, include: .testing)

            testables.append(
                .init(
                    buildableReference: buildableReference,
                    isSkipped: !testTarget.isEnabled
                )
            )
        }

        // If we have a testable, use the first one to update `.lldbinit`
        if let buildableReference = testables.first?.buildableReference {
            testPreActions
                .appendUpdateLldbInitAndCopyDSYMs(for: buildableReference)
        }

        let testUseLaunchSchemeArgsEnv =
            canUseLaunchSchemeArgsEnv && schemeInfo.test.useRunArgsAndEnv

        // MARK: Execution actions

        for executionAction in schemeInfo.executionActions {
            handleExecutionAction(executionAction)
        }

        // MARK: Build

        let buildActionEntryValues: [BuildActionEntry]

        let unsortedBuildActionEntries = buildActionEntries.values.elements
        let restStartIndex =
            buildActionEntries.values.elements.startIndex.advanced(by: 1)
        let restEndIndex = buildActionEntries.values.elements.endIndex
        if restStartIndex < restStartIndex {
            // Keep the first element as first, then sort the test by name.
            // This ensure that Run action launch targets, a library target,
            // or finally a test target, is listed first. This influences the
            // icon shown for the scheme in Xcode.
            buildActionEntryValues = [unsortedBuildActionEntries.first!] +
                (unsortedBuildActionEntries[restStartIndex ..< restEndIndex])
                .sorted { lhs, rhs in
                    return lhs.buildableReference.blueprintName
                        .localizedStandardCompare(
                            rhs.buildableReference.blueprintName
                        ) == .orderedAscending
            }
        } else {
            buildActionEntryValues = buildActionEntries.values.elements
        }

        if let firstReference =
            buildActionEntryValues.first?.buildableReference
        {
            // Use the first build entry for our Bazel support build pre-actions
            buildPreActions.appendInitializeBazelBuildOutputGroupsFile(
                with: firstReference
            )
            buildPreActions.appendPrepareBazelDependencies(with: firstReference)
        }

        // MARK: Scheme

        let scheme = createSchemeXML(
            buildAction: createBuildAction(
                entries: buildActionEntryValues,
                postActions: buildPostActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                preActions: buildPreActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action)
            ),
            testAction: createTestAction(
                appLanguage: schemeInfo.test.options?.appLanguage,
                appRegion: schemeInfo.test.options?.appRegion,
                codeCoverage: schemeInfo.test.options?.codeCoverage ?? false,
                buildConfiguration: schemeInfo.test.xcodeConfiguration ??
                    defaultXcodeConfiguration,
                commandLineArguments: schemeInfo.test.commandLineArguments,
                enableAddressSanitizer: schemeInfo.test.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.test.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.test.enableUBSanitizer,
                enableMainThreadChecker: schemeInfo.test.enableMainThreadChecker,
                enableThreadPerformanceChecker: schemeInfo.test.enableThreadPerformanceChecker,
                environmentVariables: schemeInfo.test.environmentVariables,
                expandVariablesBasedOn: testUseLaunchSchemeArgsEnv ?
                    nil : testables.first?.buildableReference,
                postActions: testPostActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                preActions: testPreActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                testables: testables,
                useLaunchSchemeArgsEnv: testUseLaunchSchemeArgsEnv
            ),
            launchAction: createLaunchAction(
                buildConfiguration: launchBuildConfiguration,
                commandLineArguments: launchRunnable == nil ?
                    [] : schemeInfo.run.commandLineArguments,
                customWorkingDirectory: schemeInfo.run.customWorkingDirectory,
                enableAddressSanitizer: schemeInfo.run.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.run.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.run.enableUBSanitizer,
                enableMainThreadChecker: schemeInfo.run.enableMainThreadChecker,
                enableThreadPerformanceChecker: schemeInfo.run.enableThreadPerformanceChecker,
                environmentVariables: launchRunnable == nil ?
                    [] : schemeInfo.run.environmentVariables,
                postActions: launchPostActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                preActions: launchPreActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                runnable: launchRunnable
            ),
            profileAction: createProfileAction(
                buildConfiguration: schemeInfo.profile.xcodeConfiguration ??
                    defaultXcodeConfiguration,
                commandLineArguments: profileRunnable == nil ?
                    [] : schemeInfo.profile.commandLineArguments,
                customWorkingDirectory: schemeInfo.profile.customWorkingDirectory,
                environmentVariables: profileRunnable == nil ?
                    [] : schemeInfo.profile.environmentVariables,
                postActions: profilePostActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                preActions: profilePreActions
                    .sorted(by: compareExecutionActions)
                    .map(\.action),
                useLaunchSchemeArgsEnv: profileUseLaunchSchemeArgsEnv,
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

private typealias OrderedExecutionAction =
    (action: ExecutionAction, order: Int?)

private func compareExecutionActions(
    lhs: OrderedExecutionAction,
    rhs: OrderedExecutionAction
) -> Bool {
    guard let lhsOrder = lhs.order else {
        return false
    }
    guard let rhsOrder = rhs.order else {
        return true
    }
    return lhsOrder < rhsOrder
}

private extension Array where Element == OrderedExecutionAction {
    private static let initializeBazelBuildOutputGroupsFileScriptText = #"""
mkdir -p "${BUILD_MARKER_FILE%/*}"
touch "$BUILD_MARKER_FILE"

"""#.schemeXmlEscaped

    mutating func appendInitializeBazelBuildOutputGroupsFile(
        with buildableReference: BuildableReference
    ) {
        append(
            (
                ExecutionAction(
                    title: "Initialize Bazel Build Output Groups File",
                    escapedScriptText:
                        Self.initializeBazelBuildOutputGroupsFileScriptText,
                    expandVariablesBasedOn: buildableReference
                ),
                -100
            )
        )
    }

    private static let prepareBazelDependenciesScriptText = #"""
mkdir -p "$PROJECT_DIR"

if [[ "${ENABLE_ADDRESS_SANITIZER:-}" == "YES" || \
      "${ENABLE_THREAD_SANITIZER:-}" == "YES" || \
      "${ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:-}" == "YES" ]]
then
    # TODO: Support custom toolchains once clang.sh supports them
    cd "$INTERNAL_DIR" || exit 1
    ln -shfF "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib" lib
fi

"""#.schemeXmlEscaped

    /// Symlinks `$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib` to
    /// `$(BAZEL_INTEGRATION_DIR)/../lib` so that Xcode can copy sanitizers'
    /// dylibs.
    mutating func appendPrepareBazelDependencies(
        with buildableReference: BuildableReference
    ) {
        append(
            (
                ExecutionAction(
                    title: "Prepare BazelDependencies",
                    escapedScriptText: Self.prepareBazelDependenciesScriptText,
                    expandVariablesBasedOn: buildableReference
                ),
                0
            )
        )
    }

    private static let updateLldbInitAndCopyDSYMsScriptText = #"""
"$BAZEL_INTEGRATION_DIR/create_lldbinit.sh"
"$BAZEL_INTEGRATION_DIR/copy_dsyms.sh"

"""#.schemeXmlEscaped

    mutating func appendUpdateLldbInitAndCopyDSYMs(
        for buildableReference: BuildableReference
    ) {
        append(
            (
                ExecutionAction(
                    title: "Update .lldbinit and copy dSYMs",
                    escapedScriptText:
                        Self.updateLldbInitAndCopyDSYMsScriptText,
                    expandVariablesBasedOn: buildableReference
                ),
                0
            )
        )
    }
}

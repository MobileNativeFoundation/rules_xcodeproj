import XcodeProj

extension XCSchemeInfo {
    struct TestActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfos: Set<XCSchemeInfo.TargetInfo>
        let args: [String]?
        let diagnostics: DiagnosticsInfo
        let env: [String: String]?
        let expandVariablesBasedOn: TargetInfo?
        let preActions: [PrePostActionInfo]
        let postActions: [PrePostActionInfo]

        /// The primary initializer.
        init<TargetInfos: Sequence>(
            buildConfigurationName: String,
            targetInfos: TargetInfos,
            args: [String]? = nil,
            diagnostics: DiagnosticsInfo = .init(diagnostics: .init()),
            env: [String: String]? = nil,
            expandVariablesBasedOn: TargetInfo? = nil,
            preActions: [PrePostActionInfo] = [],
            postActions: [PrePostActionInfo] = []
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfos = Set(targetInfos)
            self.args = args
            self.diagnostics = diagnostics
            self.env = env
            self.expandVariablesBasedOn = expandVariablesBasedOn
            self.preActions = preActions
            self.postActions = postActions

            guard !self.targetInfos.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should have at least one \
`XCSchemeInfo.TargetInfo`.
""")
            }
            guard self.targetInfos.allSatisfy(\.pbxTarget.isTestable) else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should only contain testable \
`XCSchemeInfo.TargetInfo` values.
""")
            }
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.TestActionInfo {
    /// Create a copy of the test action info with host in the target infos
    /// resolved.
    init?<TargetInfos: Sequence>(
        resolveHostsFor testActionInfo: XCSchemeInfo.TestActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = testActionInfo else {
            return nil
        }

        var expandVariablesBasedOn: XCSchemeInfo.TargetInfo?
        if let originalExpandVariablesBasedOn = original.expandVariablesBasedOn {
            expandVariablesBasedOn = XCSchemeInfo.TargetInfo(
                resolveHostFor: originalExpandVariablesBasedOn,
                topLevelTargetInfos: topLevelTargetInfos
            )
        }

        try self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfos: original.targetInfos.map {
                .init(
                    resolveHostFor: $0,
                    topLevelTargetInfos: topLevelTargetInfos
                )
            },
            args: original.args,
            diagnostics: original.diagnostics,
            env: original.env,
            expandVariablesBasedOn: expandVariablesBasedOn,
            preActions: original.preActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos),
            postActions: original.postActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos)
        )
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.TestActionInfo {
    init?(
        testAction: XcodeScheme.TestAction?,
        defaultBuildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]],
        args _: [TargetID: [String]],
        envs: [TargetID: [String: String]]
    ) throws {
        guard let testAction = testAction else {
          return nil
        }

        let expandVariablesBasedOn = try testAction.expandVariablesBasedOn ??
            testAction.targets.sortedLocalizedStandard().first.orThrow("""
Expected at least one target in `TestAction.targets`
""")

        let buildConfigurationName = testAction.buildConfigurationName ??
            defaultBuildConfigurationName

        var env: [String: String] = testAction.env ?? [:]
        let testActionTargetIdsLabels: [(TargetID, BazelLabel)] =
            testAction.targets.compactMap { label in
                guard let targetId = targetIDsByLabelAndConfiguration.targetID(
                    for: label,
                    preferredConfiguration: buildConfigurationName
                ) else {
                    return nil
                }
                return (targetId, label)
            }
        for tuple in testActionTargetIdsLabels {
            let testActionTargetId: TargetID = tuple.0
            let testActionLabel: BazelLabel = tuple.1
            if let testActionTargetEnv: [String: String] = envs[testActionTargetId] {
                for (key, newValue) in testActionTargetEnv {
                    if let existingValue: String = env[key],
                       existingValue != newValue
                    {
                        let errorMessage = """
ERROR: '\(testActionLabel)' defines a value for '\(key)' ('\(newValue)') that \
doesn't match the existing value of '\(existingValue)' from another target in \
the same scheme.
"""
                        throw UsageError(message: errorMessage)
                    }
                    env[key] = newValue
                }
            }
        }

        let targetInfos = try testAction.targets.map { label in
            return try targetResolver.targetInfo(
                targetID: targetIDsByLabelAndConfiguration.targetID(
                    for: label,
                    preferredConfiguration: buildConfigurationName
                ).orThrow("""
Failed to find a `TargetID` for "\(label)" while creating a `TestActionInfo`
""")
            )
        }

        try self.init(
            buildConfigurationName: buildConfigurationName,
            targetInfos: targetInfos,
            args: testAction.args?.extractCommandLineArguments(),
            diagnostics: XCSchemeInfo.DiagnosticsInfo(
                diagnostics: testAction.diagnostics
            ),
            env: env.isEmpty ? testAction.env : env,
            expandVariablesBasedOn: targetResolver.targetInfo(
                targetID: targetIDsByLabelAndConfiguration.targetID(
                    for: expandVariablesBasedOn,
                    preferredConfiguration: buildConfigurationName
                ).orThrow("""
Failed to find a `TargetID` for "\(expandVariablesBasedOn)" while creating a \
`VariableExpansionContextInfo`
""")
            ),
            preActions: testAction.preActions.prePostActionInfos(
                buildConfigurationName: buildConfigurationName,
                targetResolver: targetResolver,
                targetIDsByLabelAndConfiguration:
                    targetIDsByLabelAndConfiguration,
                context: "creating a pre-action `PrePostActionInfo`"
            ),
            postActions: testAction.postActions.prePostActionInfos(
                buildConfigurationName: buildConfigurationName,
                targetResolver: targetResolver,
                targetIDsByLabelAndConfiguration:
                    targetIDsByLabelAndConfiguration,
                context: "creating a post-action `PrePostActionInfo`"
            )
        )
    }
}

// MARK: `macroExpansion`

extension XCSchemeInfo.TestActionInfo {
    var macroExpansion: XCScheme.BuildableReference? {
        get throws {
            // Sort the target infos so that we receive a consistent value
            let sortedTargetInfos = targetInfos
                .sortedLocalizedStandard(\.pbxTarget.name)
            guard let targetInfo = sortedTargetInfos.first else {
                return nil
            }
            return try targetInfo.macroExpansion
        }
    }
}

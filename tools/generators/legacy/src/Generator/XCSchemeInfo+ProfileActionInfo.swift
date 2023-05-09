import XcodeProj

extension XCSchemeInfo {
    struct ProfileActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
        let args: [String]?
        let env: [String: String]?
        let workingDirectory: String?

        init(
            buildConfigurationName: String,
            targetInfo: XCSchemeInfo.TargetInfo,
            args: [String]? = nil,
            env: [String: String]? = nil,
            workingDirectory: String? = nil
        ) {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfo = targetInfo
            self.args = args
            self.env = env
            self.workingDirectory = workingDirectory
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.ProfileActionInfo {
    /// Create a copy of the `ProfileActionInfo` with host in the `TargetInfo` resolved.
    init?<TargetInfos: Sequence>(
        resolveHostsFor profileActionInfo: XCSchemeInfo.ProfileActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = profileActionInfo else {
          return nil
        }
        self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfo: .init(
                resolveHostFor: original.targetInfo,
                topLevelTargetInfos: topLevelTargetInfos
            ),
            args: original.args,
            env: original.env,
            workingDirectory: original.workingDirectory
        )
    }
}

// MARK: `runnable`

extension XCSchemeInfo.ProfileActionInfo {
    var runnable: XCScheme.BuildableProductRunnable? {
        // We want to provide a `ProfileActionInfo`, but we do not want to set the runnable, if it
        // is testable.
        if targetInfo.pbxTarget.isTestable {
            return nil
        }
        return .init(buildableReference: targetInfo.buildableReference)
    }
}

// MARK: `macroExpansion`

extension XCSchemeInfo.ProfileActionInfo {
    var macroExpansion: XCScheme.BuildableReference? {
        get throws {
            try targetInfo.macroExpansion
        }
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.ProfileActionInfo {
    init?(
        profileAction: XcodeScheme.ProfileAction?,
        defaultBuildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]]
    ) throws {
        guard let profileAction = profileAction else {
          return nil
        }

        let buildConfigurationName = profileAction.buildConfigurationName ??
            defaultBuildConfigurationName

        let targetID = try targetIDsByLabelAndConfiguration.targetID(
            for: profileAction.target,
            preferredConfiguration: buildConfigurationName
        ).orThrow("""
Failed to find a `TargetID` for "\(profileAction.target)" while creating a \
`ProfileActionInfo`
""")

        try self.init(
            buildConfigurationName: buildConfigurationName,
            targetInfo: targetResolver.targetInfo(targetID: targetID),
            args: profileAction.args,
            env: profileAction.env,
            workingDirectory: profileAction.workingDirectory
        )
    }
}

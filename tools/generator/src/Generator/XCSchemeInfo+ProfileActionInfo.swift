import XcodeProj

extension XCSchemeInfo {
    struct ProfileActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
        let workingDirectory: String?

        init(
            buildConfigurationName: String,
            targetInfo: XCSchemeInfo.TargetInfo,
            workingDirectory: String? = nil
        ) {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfo = targetInfo
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

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.ProfileActionInfo {
    init?(
        profileAction: XcodeScheme.ProfileAction?,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        guard let profileAction = profileAction else {
          return nil
        }
        let targetInfo = try targetResolver.targetInfo(
            targetID: try targetIDsByLabel.value(
                for: profileAction.target,
                context: "creating a `ProfileActionInfo`"
            )
        )
        self.init(
            buildConfigurationName: profileAction.buildConfigurationName ??
                targetInfo.pbxTarget.defaultBuildConfigurationName,
            targetInfo: targetInfo,
            workingDirectory: profileAction.workingDirectory
        )
    }
}

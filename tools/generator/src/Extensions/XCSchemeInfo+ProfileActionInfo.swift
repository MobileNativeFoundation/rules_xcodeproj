import XcodeProj

extension XCSchemeInfo {
    struct ProfileActionInfo {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
    }
}

extension XCSchemeInfo.ProfileActionInfo {
    /// Create a copy of the profile action info with host in the target info resolved.
    init?(
        resolveHostsFor profileActionInfo: XCSchemeInfo.ProfileActionInfo?,
        topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
    ) {
        guard let original = profileActionInfo else {
          return nil
        }
        self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfo: .init(
                resolveHostFor: original.targetInfo,
                topLevelTargetInfos: topLevelTargetInfos
            )
        )
    }
}

extension XCSchemeInfo.ProfileActionInfo {
    var runnable: XCScheme.BuildableProductRunnable {
        return .init(buildableReference: targetInfo.buildableReference)
    }
}

import XcodeProj

extension XCSchemeInfo {
    struct HostInfo: Equatable, Hashable {
        let pbxTarget: PBXTarget
        let platforms: Set<Platform>
        let buildableReference: XCScheme.BuildableReference
        let index: Int
    }
}

extension XCSchemeInfo.HostInfo {
    init<Platforms: Sequence>(
        pbxTarget: PBXTarget,
        platforms: Platforms,
        referencedContainer: String,
        index: Int
    ) where Platforms.Element == Platform {
         self.pbxTarget = pbxTarget
         self.platforms = Set(platforms)
         buildableReference = .init(
             pbxTarget: pbxTarget,
             referencedContainer: referencedContainer
         )
         self.index = index
    }
}

extension XCSchemeInfo.HostInfo {
    init(pbxTargetInfo: TargetResolver.PBXTargetInfo, index: Int) {
        self.init(
            pbxTarget: pbxTargetInfo.pbxTarget,
            platforms: pbxTargetInfo.platforms,
            buildableReference: pbxTargetInfo.buildableReference,
            index: index
        )
    }
}
